require 'rails_helper'

RSpec.describe 'Invitations', type: :request do
  let(:response_json) { JSON.parse(response.body) }
  let(:response_json_space)       { response_json['space'] }
  let(:response_json_invitation)  { response_json['invitation'] }
  let(:response_json_invitations) { response_json['invitations'] }
  let(:response_json_space_current_member) { response_json_space['current_member'] }

  # GET /invitations/:space_code 招待URL一覧
  # GET /invitations/:space_code(.json) 招待URL一覧API
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）, APIログイン中, APIログイン中（削除予約済み）
  #   スペース: 存在しない, 公開, 非公開
  #   権限: ある（管理者）, ない（投稿者, 閲覧者, なし）
  #   招待URL: ない, 最大表示数と同じ, 最大表示数より多い
  #   ＋URLの拡張子: ない, .json
  #   ＋Acceptヘッダ: HTMLが含まれる, JSONが含まれる
  describe 'GET #index' do
    subject { get invitations_path(space_code: space.code, page: subject_page, format: subject_format), headers: auth_headers.merge(accept_headers) }

    let_it_be(:space_not)     { FactoryBot.build_stubbed(:space) }
    let_it_be(:space_public)  { FactoryBot.create(:space, :public) }
    let_it_be(:space_private) { FactoryBot.create(:space, :private) }

    # テスト内容
    shared_examples_for 'ToOK(html/*)' do
      it 'HTTPステータスが200。対象項目が含まれる' do
        is_expected.to eq(200)
        expect_space_html(response, space)
        expect(response.body).to include("href=\"#{new_invitation_path(space.code)}\"") # 招待URL作成
      end
    end
    shared_examples_for 'ToOK(json/json)' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it 'HTTPステータスが200。対象項目が一致する' do
        is_expected.to eq(200)
        expect(response_json['success']).to eq(true)

        expect(response_json_space['code']).to eq(space.code)
        expect_image_json(response_json_space, space)
        expect(response_json_space['name']).to eq(space.name)
        expect(response_json_space['description']).to eq(space.description)
        expect(response_json_space['private']).to eq(space.private)

        ## 削除予約
        expect(response_json_space['destroy_requested_at']).to eq(I18n.l(space.destroy_requested_at, format: :json, default: nil))
        expect(response_json_space['destroy_schedule_at']).to eq(I18n.l(space.destroy_schedule_at, format: :json, default: nil))

        expect(response_json_space_current_member['power']).to eq(:admin.to_s)
        expect(response_json_space_current_member['power_i18n']).to eq(Invitation.powers_i18n[:admin])
        expect(response_json_space_current_member.count).to eq(2)
        expect(response_json_space.count).to eq(9)

        expect(response_json_invitation['total_count']).to eq(invitations.count)
        expect(response_json_invitation['current_page']).to eq(subject_page)
        expect(response_json_invitation['total_pages']).to eq((invitations.count - 1).div(Settings.default_invitations_limit) + 1)
        expect(response_json_invitation['limit_value']).to eq(Settings.default_invitations_limit)
        expect(response_json_invitation.count).to eq(4)

        expect(response_json.count).to eq(4)
      end
    end

    shared_examples_for 'ページネーション表示' do |page, link_page|
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      let(:subject_page) { page }
      let(:url_page)     { link_page >= 2 ? link_page : nil }
      it "#{link_page}ページのパスが含まれる" do
        subject
        expect(response.body).to include("\"#{invitations_path(space_code: space.code, page: url_page)}\"")
      end
    end
    shared_examples_for 'ページネーション非表示' do |page, link_page|
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      let(:subject_page) { page }
      let(:url_page)     { link_page >= 2 ? link_page : nil }
      it "#{link_page}ページのパスが含まれない" do
        subject
        expect(response.body).not_to include("\"#{invitations_path(space_code: space.code, page: url_page)}\"")
      end
    end

    shared_examples_for 'リスト表示（0件）' do
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      let(:subject_page) { 1 }
      it '存在しないメッセージが含まれる' do
        subject
        expect(response.body).to include('対象の招待URLが見つかりません。')
      end
    end
    shared_examples_for 'リスト表示' do |page|
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      let(:subject_page) { page }
      let(:start_no)     { (Settings.default_invitations_limit * (page - 1)) + 1 }
      let(:end_no)       { [invitations.count, Settings.default_invitations_limit * page].min }
      it '対象項目が含まれる' do
        subject
        (start_no..end_no).each do |no|
          invitation = invitations[invitations.count - no]
          # 招待URL
          url = "text=\"#{"#{request.base_url}#{new_user_registration_path}?code=#{invitation.code}"}\""
          if invitation.status == :active
            expect(response.body).to include(url)
          else
            expect(response.body).not_to include(url)
          end
          # ステータス
          url = "href=\"#{edit_invitation_path(space.code, invitation.code)}\""
          if invitation.status == :email_joined
            expect(response.body).not_to include(url)
          else
            expect(response.body).to include(url)
          end
          expect(response.body).to include(invitation.status_i18n)
          # メールアドレス
          if invitation.email.present?
            expect(response.body).to include(invitation.email)
          else
            invitation.domains_array.each do |domain|
              expect(response.body).to include("*@#{domain}")
            end
          end
          # 権限
          expect(response.body).to include(invitation.power_i18n)
          # 期限
          expect(response.body).to include(I18n.l(invitation.ended_at, default: 'なし'))
          # メモ
          expect(response.body).to include(invitation.memo)
          # 作成者
          if invitation.created_user.present?
            expect(response.body).to include(invitation.created_user.image_url(:small))
            expect(response.body).to include(invitation.created_user.name)
          end
          # 作成日時
          expect(response.body).to include(I18n.l(invitation.created_at))
          # 更新者
          if invitation.last_updated_user.present?
            expect(response.body).to include(invitation.last_updated_user.image_url(:small)) # [最終更新者]画像
            expect(response.body).to include(invitation.last_updated_user.name) # [最終更新者]氏名
          end
          # 更新日時
          expect(response.body).to include(I18n.l(invitation.last_updated_at)) if invitation.last_updated_at.present?
        end
      end
    end
    shared_examples_for 'リスト表示(json)' do |page|
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      let(:subject_page) { page }
      let(:start_no)     { (Settings.default_invitations_limit * (page - 1)) + 1 }
      let(:end_no)       { [invitations.count, Settings.default_invitations_limit * page].min }
      it '件数・対象項目が一致する' do
        subject
        expect(response_json_invitations.count).to eq(end_no - start_no + 1)
        (start_no..end_no).each do |no|
          data = response_json_invitations[no - start_no]
          count = expect_invitation_json(data, invitations[invitations.count - no])
          expect(data.count).to eq(count)
        end
      end
    end

    shared_examples_for 'リダイレクト' do |page, redirect_page|
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      let(:subject_page) { page }
      let(:url_page)     { redirect_page >= 2 ? redirect_page : nil }
      it '最終ページにリダイレクトする' do
        is_expected.to redirect_to(invitations_path(space_code: space.code, page: url_page))
      end
    end
    shared_examples_for 'リダイレクト(json)' do |page|
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      let(:subject_page) { page }
      it 'リダイレクトしない' do
        is_expected.to eq(200)
      end
    end

    # テストケース
    shared_examples_for '[ログイン中/削除予約済み][*][ある]招待URLがない' do
      include_context '招待URL一覧作成', 0, 0, 0, 0
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToOK(html)', 1
        it_behaves_like 'ページネーション非表示', 1, 2
        it_behaves_like 'リスト表示（0件）'
        it_behaves_like 'リダイレクト', 2, 1
      end
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中/削除予約済み][*][ある]招待URLがない' do
      include_context '招待URL一覧作成', 0, 0, 0, 0
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToOK(html)', 1 # NOTE: HTMLもログイン状態になる
        it_behaves_like 'ページネーション非表示', 1, 2
        it_behaves_like 'リスト表示（0件）'
        it_behaves_like 'リダイレクト', 2, 1
      end
      it_behaves_like 'ToOK(json)', 1
      it_behaves_like 'リスト表示(json)', 1
      it_behaves_like 'リダイレクト(json)', 2
    end
    shared_examples_for '[ログイン中/削除予約済み][*][ある]招待URLが最大表示数と同じ' do
      count = Settings.test_invitations_count
      include_context '招待URL一覧作成', count.active, count.expired, count.deleted, count.email_joined
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToOK(html)', 1
        it_behaves_like 'ページネーション非表示', 1, 2
        it_behaves_like 'リスト表示', 1
        it_behaves_like 'リダイレクト', 2, 1
      end
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中/削除予約済み][*][ある]招待URLが最大表示数と同じ' do
      count = Settings.test_invitations_count
      include_context '招待URL一覧作成', count.active, count.expired, count.deleted, count.email_joined
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToOK(html)', 1 # NOTE: HTMLもログイン状態になる
        it_behaves_like 'ページネーション非表示', 1, 2
        it_behaves_like 'リスト表示', 1
        it_behaves_like 'リダイレクト', 2, 1
      end
      it_behaves_like 'ToOK(json)', 1
      it_behaves_like 'リスト表示(json)', 1
      it_behaves_like 'リダイレクト(json)', 2
    end
    shared_examples_for '[ログイン中/削除予約済み][*][ある]招待URLが最大表示数より多い' do
      count = Settings.test_invitations_count
      include_context '招待URL一覧作成', count.active, count.expired, count.deleted, count.email_joined + 1
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToOK(html)', 1
        it_behaves_like 'ToOK(html)', 2
        it_behaves_like 'ページネーション表示', 1, 2
        it_behaves_like 'ページネーション表示', 2, 1
        it_behaves_like 'リスト表示', 1
        it_behaves_like 'リスト表示', 2
        it_behaves_like 'リダイレクト', 3, 2
      end
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中/削除予約済み][*][ある]招待URLが最大表示数より多い' do
      count = Settings.test_invitations_count
      include_context '招待URL一覧作成', count.active, count.expired, count.deleted, count.email_joined + 1
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToOK(html)', 1 # NOTE: HTMLもログイン状態になる
        it_behaves_like 'ToOK(html)', 2
        it_behaves_like 'ページネーション表示', 1, 2
        it_behaves_like 'ページネーション表示', 2, 1
        it_behaves_like 'リスト表示', 1
        it_behaves_like 'リスト表示', 2
        it_behaves_like 'リダイレクト', 3, 2
      end
      it_behaves_like 'ToOK(json)', 1
      it_behaves_like 'ToOK(json)', 2
      it_behaves_like 'リスト表示(json)', 1
      it_behaves_like 'リスト表示(json)', 2
      it_behaves_like 'リダイレクト(json)', 3
    end

    shared_examples_for '[ログイン中/削除予約済み][*]権限がある' do |power|
      include_context 'set_member_power', power
      it_behaves_like '[ログイン中/削除予約済み][*][ある]招待URLがない'
      it_behaves_like '[ログイン中/削除予約済み][*][ある]招待URLが最大表示数と同じ'
      it_behaves_like '[ログイン中/削除予約済み][*][ある]招待URLが最大表示数より多い'
    end
    shared_examples_for '[APIログイン中/削除予約済み][*]権限がある' do |power|
      include_context 'set_member_power', power
      it_behaves_like '[APIログイン中/削除予約済み][*][ある]招待URLがない'
      it_behaves_like '[APIログイン中/削除予約済み][*][ある]招待URLが最大表示数と同じ'
      it_behaves_like '[APIログイン中/削除予約済み][*][ある]招待URLが最大表示数より多い'
    end
    shared_examples_for '[ログイン中/削除予約済み][*]権限がない' do |power|
      include_context 'set_member_power', power
      it_behaves_like 'ToNG(html)', Settings.api_only_mode ? 406 : 403
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中/削除予約済み][*]権限がない' do |power|
      include_context 'set_member_power', power
      it_behaves_like 'ToNG(html)', Settings.api_only_mode ? 406 : 403
      it_behaves_like 'ToNG(json)', 403
    end

    shared_examples_for '[ログイン中/削除予約済み]スペースが存在しない' do
      let_it_be(:space) { space_not }
      it_behaves_like 'ToNG(html)', Settings.api_only_mode ? 406 : 404
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中/削除予約済み]スペースが存在しない' do
      let_it_be(:space) { space_not }
      it_behaves_like 'ToNG(html)', Settings.api_only_mode ? 406 : 404
      it_behaves_like 'ToNG(json)', 404
    end
    shared_examples_for '[ログイン中/削除予約済み]スペースが公開' do
      let_it_be(:space) { space_public }
      it_behaves_like '[ログイン中/削除予約済み][*]権限がある', :admin
      it_behaves_like '[ログイン中/削除予約済み][*]権限がない', :writer
      it_behaves_like '[ログイン中/削除予約済み][*]権限がない', :reader
      it_behaves_like '[ログイン中/削除予約済み][*]権限がない', nil
    end
    shared_examples_for '[APIログイン中/削除予約済み]スペースが公開' do
      let_it_be(:space) { space_public }
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がある', :admin
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がない', :writer
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がない', :reader
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がない', nil
    end
    shared_examples_for '[ログイン中/削除予約済み]スペースが非公開' do
      let_it_be(:space) { space_private }
      it_behaves_like '[ログイン中/削除予約済み][*]権限がある', :admin
      it_behaves_like '[ログイン中/削除予約済み][*]権限がない', :writer
      it_behaves_like '[ログイン中/削除予約済み][*]権限がない', :reader
      it_behaves_like '[ログイン中/削除予約済み][*]権限がない', nil
    end
    shared_examples_for '[APIログイン中/削除予約済み]スペースが非公開' do
      let_it_be(:space) { space_private }
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がある', :admin
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がない', :writer
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がない', :reader
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がない', nil
    end

    shared_examples_for '[ログイン中/削除予約済み]' do
      it_behaves_like '[ログイン中/削除予約済み]スペースが存在しない'
      it_behaves_like '[ログイン中/削除予約済み]スペースが公開'
      it_behaves_like '[ログイン中/削除予約済み]スペースが非公開'
    end
    shared_examples_for '[APIログイン中/削除予約済み]' do
      it_behaves_like '[APIログイン中/削除予約済み]スペースが存在しない'
      it_behaves_like '[APIログイン中/削除予約済み]スペースが公開'
      it_behaves_like '[APIログイン中/削除予約済み]スペースが非公開'
    end

    context '未ログイン' do
      include_context '未ログイン処理'
      let_it_be(:space) { space_public }
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToLogin(html)'
      end
      it_behaves_like 'ToNG(json)', 401
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中/削除予約済み]'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', :destroy_reserved
      it_behaves_like '[ログイン中/削除予約済み]'
    end
    context 'APIログイン中' do
      include_context 'APIログイン処理'
      it_behaves_like '[APIログイン中/削除予約済み]'
    end
    context 'APIログイン中（削除予約済み）' do
      include_context 'APIログイン処理', :destroy_reserved
      it_behaves_like '[APIログイン中/削除予約済み]'
    end
  end
end
