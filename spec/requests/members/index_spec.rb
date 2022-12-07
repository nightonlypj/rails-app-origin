require 'rails_helper'

RSpec.describe 'Members', type: :request do
  let(:response_json) { JSON.parse(response.body) }
  let(:response_json_space)           { response_json['space'] }
  let(:response_json_space_image_url) { response_json['space']['image_url'] }
  let(:response_json_member)          { response_json['member'] }
  let(:response_json_members)         { response_json['members'] }

  # GET /members メンバー一覧
  # GET /members(.json) メンバー一覧API
  # 前提条件
  #   検索条件なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）, APIログイン中, APIログイン中（削除予約済み）
  #   スペース: 存在しない, 公開, 非公開
  #   権限: ない, ある（管理者, 投稿者, 閲覧者）
  #   メンバー: いない, 最大表示数と同じ, 最大表示数より多い
  #   ＋URLの拡張子: ない, .json
  #   ＋Acceptヘッダ: HTMLが含まれる, JSONが含まれる
  describe 'GET #index' do
    subject { get members_path(code: space.code, page: subject_page, format: subject_format), headers: auth_headers.merge(accept_headers) }

    # テスト内容
    shared_examples_for 'ToOK(html/*)' do
      it 'HTTPステータスが200。対象項目が含まれる' do
        is_expected.to eq(200)
        expect(response.body).to include(space.image_url(:small)) # 画像
        expect(response.body).to include("href=\"#{space_path(space.code)}\"") # スペーストップ
        expect(response.body).to include("#{space.name}のメンバー") # 名称
        expect(response.body).to include('非公開') if space.private # 非公開
        expect(response.body).to include(I18n.l(space.destroy_schedule_at.to_date)) if space.destroy_reserved? # 削除予定日時
        expect(response.body).to include(Member.powers_i18n[user_power]) if user_power.present? # 権限

        download_url = create_download_path({ model: :member, space_code: space.code, search_params: { page: subject_page } }).gsub(/&/, '&amp;')
        if user_power == :admin
          expect(response.body).to include("href=\"#{new_member_path(space.code)}\"") # メンバー招待
          expect(response.body).to include("href=\"#{download_url}\"") # ダウンロード
          expect(response.body).to include("action=\"#{destroy_member_path(space.code)}\"") # メンバー解除
        else
          expect(response.body).not_to include("href=\"#{new_member_path(space.code)}\"")
          expect(response.body).not_to include("href=\"#{download_url}\"")
          expect(response.body).not_to include("action=\"#{destroy_member_path(space.code)}\"")
        end
      end
    end
    shared_examples_for 'ToOK(json/json)' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it 'HTTPステータスが200。対象項目が一致する' do
        is_expected.to eq(200)
        expect(response_json['success']).to eq(true)
        expect(response_json['search_params']).to eq({ text: nil, power: Member.powers.keys.join(','), sort: 'invitationed_at', desc: 1 }.stringify_keys)

        expect(response_json_space['code']).to eq(space.code)
        expect(response_json_space_image_url['mini']).to eq("#{Settings['base_image_url']}#{space.image_url(:mini)}")
        expect(response_json_space_image_url['small']).to eq("#{Settings['base_image_url']}#{space.image_url(:small)}")
        expect(response_json_space_image_url['medium']).to eq("#{Settings['base_image_url']}#{space.image_url(:medium)}")
        expect(response_json_space_image_url['large']).to eq("#{Settings['base_image_url']}#{space.image_url(:large)}")
        expect(response_json_space_image_url['xlarge']).to eq("#{Settings['base_image_url']}#{space.image_url(:xlarge)}")
        expect(response_json_space['name']).to eq(space.name)
        expect(response_json_space['description']).to eq(space.description)
        expect(response_json_space['private']).to eq(space.private)
        expect(response_json_space['destroy_requested_at']).to eq(I18n.l(space.destroy_requested_at, format: :json, default: nil))
        expect(response_json_space['destroy_schedule_at']).to eq(I18n.l(space.destroy_schedule_at, format: :json, default: nil))
        if user_power.blank?
          expect(response_json_space['current_member']).to be_nil
        else
          expect(response_json_space['current_member']['power']).to eq(user_power.to_s)
          expect(response_json_space['current_member']['power_i18n']).to eq(Member.powers_i18n[user_power])
        end

        expect(response_json_member['total_count']).to eq(members.count)
        expect(response_json_member['current_page']).to eq(subject_page)
        expect(response_json_member['total_pages']).to eq((members.count - 1).div(Settings['default_members_limit']) + 1)
        expect(response_json_member['limit_value']).to eq(Settings['default_members_limit'])
      end
    end

    shared_examples_for 'ページネーション表示' do |page, link_page|
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      let(:subject_page) { page }
      let(:url_page)     { link_page >= 2 ? link_page : nil }
      it "#{link_page}ページのパスが含まれる" do
        subject
        expect(response.body).to include("\"#{members_path(code: space.code, page: url_page)}\"")
      end
    end
    shared_examples_for 'ページネーション非表示' do |page, link_page|
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      let(:subject_page) { page }
      let(:url_page)     { link_page >= 2 ? link_page : nil }
      it "#{link_page}ページのパスが含まれない" do
        subject
        expect(response.body).not_to include("\"#{members_path(code: space.code, page: url_page)}\"")
      end
    end

    shared_examples_for 'リスト表示' do |page|
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      let(:subject_page) { page }
      let(:start_no)     { (Settings['default_members_limit'] * (page - 1)) + 1 }
      let(:end_no)       { [members.count, Settings['default_members_limit'] * page].min }
      it '対象項目が含まれる' do
        subject
        (start_no..end_no).each do |no|
          member = members[members.count - no]
          if user_power == :admin
            expect(response.body).to include("id=\"codes[#{member.user.code}]\"") # (メンバー解除)
          else
            expect(response.body).not_to include("id=\"codes[#{member.user.code}]\"")
          end
          expect(response.body).to include(member.user.image_url(:small)) # 画像
          expect(response.body).to include(member.user.name) # 氏名
          if user_power == :admin
            expect(response.body).to include(member.user.email) # メールアドレス
          else
            expect(response.body).not_to include(member.user.email)
          end
          if user_power == :admin && member.user != user
            expect(response.body).to include("href=\"#{edit_member_path(space.code, member.user.code)}\"") # メンバー情報変更
          else
            expect(response.body).not_to include("href=\"#{edit_member_path(space.code, member.user.code)}\"")
          end
          expect(response.body).to include(member.power_i18n) # 権限
          if member.invitation_user.present?
            if user_power == :admin
              expect(response.body).to include(member.invitation_user.image_url(:small)) # [招待者]画像
              expect(response.body).to include(member.invitation_user.name) # [招待者]氏名
            else
              # expect(response.body).not_to include(member.invitation_user.image_url(:small)) # NOTE: ユニークじゃない為
              expect(response.body).not_to include(member.invitation_user.name)
            end
          end
          expect(response.body).to include(I18n.l(member.invitationed_at)) if member.invitationed_at.present?
        end
      end
    end
    shared_examples_for 'リスト表示(json)' do |page|
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      let(:subject_page) { page }
      let(:start_no)     { (Settings['default_members_limit'] * (page - 1)) + 1 }
      let(:end_no)       { [members.count, Settings['default_members_limit'] * page].min }
      it '件数・対象項目が一致する' do
        subject
        expect(response_json_members.count).to eq(end_no - start_no + 1)
        (start_no..end_no).each do |no|
          data = response_json_members[no - start_no]
          member = members[members.count - no]

          data_user = data['user']
          expect(data_user['code']).to eq(member.user.code)
          data_user_image_url = data_user['image_url']
          expect(data_user_image_url['mini']).to eq("#{Settings['base_image_url']}#{member.user.image_url(:mini)}")
          expect(data_user_image_url['small']).to eq("#{Settings['base_image_url']}#{member.user.image_url(:small)}")
          expect(data_user_image_url['medium']).to eq("#{Settings['base_image_url']}#{member.user.image_url(:medium)}")
          expect(data_user_image_url['large']).to eq("#{Settings['base_image_url']}#{member.user.image_url(:large)}")
          expect(data_user_image_url['xlarge']).to eq("#{Settings['base_image_url']}#{member.user.image_url(:xlarge)}")
          expect(data_user['name']).to eq(member.user.name)
          if user_power == :admin
            expect(data_user['email']).to eq(member.user.email)
          else
            expect(data_user['email']).to be_nil
          end
          expect(data['power']).to eq(member.power)
          expect(data['power_i18n']).to eq(Member.powers_i18n[member.power])

          if member.invitation_user.present? && user_power == :admin
            data_invitation_user = data['invitation_user']
            expect(data_invitation_user['code']).to eq(member.invitation_user.code)
            data_invitation_user_image_url = data_invitation_user['image_url']
            expect(data_invitation_user_image_url['mini']).to eq("#{Settings['base_image_url']}#{member.invitation_user.image_url(:mini)}")
            expect(data_invitation_user_image_url['small']).to eq("#{Settings['base_image_url']}#{member.invitation_user.image_url(:small)}")
            expect(data_invitation_user_image_url['medium']).to eq("#{Settings['base_image_url']}#{member.invitation_user.image_url(:medium)}")
            expect(data_invitation_user_image_url['large']).to eq("#{Settings['base_image_url']}#{member.invitation_user.image_url(:large)}")
            expect(data_invitation_user_image_url['xlarge']).to eq("#{Settings['base_image_url']}#{member.invitation_user.image_url(:xlarge)}")
            expect(data_invitation_user['name']).to eq(member.invitation_user.name)
            expect(data_invitation_user['email']).to eq(member.invitation_user.email)
          else
            expect(data['invitation_user']).to be_nil
          end
          expect(data['invitationed_at']).to eq(I18n.l(member.invitationed_at, format: :json, default: nil))
        end
      end
    end

    shared_examples_for 'リダイレクト' do |page, redirect_page|
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      let(:subject_page) { page }
      let(:url_page)     { redirect_page >= 2 ? redirect_page : nil }
      it '最終ページにリダイレクトする' do
        is_expected.to redirect_to(members_path(code: space.code, page: url_page))
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
    shared_examples_for '[ログイン中/削除予約済み][*][ある]メンバーが最大表示数と同じ' do |power|
      let_it_be(:user_power) { power }
      count = Settings['test_members']
      include_context 'メンバー一覧作成', count['admin_count'], count['writer_count'], count['reader_count']
      it_behaves_like 'ToOK(html)', 1
      it_behaves_like 'ページネーション非表示', 1, 2
      it_behaves_like 'リスト表示', 1
      it_behaves_like 'リダイレクト', 2, 1
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中/削除予約済み][*][ある]メンバーが最大表示数と同じ' do |power|
      let_it_be(:user_power) { power }
      count = Settings['test_members']
      include_context 'メンバー一覧作成', count['admin_count'], count['writer_count'], count['reader_count']
      it_behaves_like 'ToOK(html)', 1 # NOTE: HTMLもログイン状態になる
      it_behaves_like 'ページネーション非表示', 1, 2
      it_behaves_like 'リスト表示', 1
      it_behaves_like 'リダイレクト', 2, 1
      it_behaves_like 'ToOK(json)', 1
      it_behaves_like 'リスト表示(json)', 1
      it_behaves_like 'リダイレクト(json)', 2
    end
    shared_examples_for '[ログイン中/削除予約済み][*][ある]メンバーが最大表示数より多い' do |power|
      let_it_be(:user_power) { power }
      count = Settings['test_members']
      include_context 'メンバー一覧作成', count['admin_count'], count['writer_count'], count['reader_count'] + 1
      it_behaves_like 'ToOK(html)', 1
      it_behaves_like 'ToOK(html)', 2
      it_behaves_like 'ページネーション表示', 1, 2
      it_behaves_like 'ページネーション表示', 2, 1
      it_behaves_like 'リスト表示', 1
      it_behaves_like 'リスト表示', 2
      it_behaves_like 'リダイレクト', 3, 2
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中/削除予約済み][*][ある]メンバーが最大表示数より多い' do |power|
      let_it_be(:user_power) { power }
      count = Settings['test_members']
      include_context 'メンバー一覧作成', count['admin_count'], count['writer_count'], count['reader_count'] + 1
      it_behaves_like 'ToOK(html)', 1 # NOTE: HTMLもログイン状態になる
      it_behaves_like 'ToOK(html)', 2
      it_behaves_like 'ページネーション表示', 1, 2
      it_behaves_like 'ページネーション表示', 2, 1
      it_behaves_like 'リスト表示', 1
      it_behaves_like 'リスト表示', 2
      it_behaves_like 'リダイレクト', 3, 2
      it_behaves_like 'ToOK(json)', 1
      it_behaves_like 'ToOK(json)', 2
      it_behaves_like 'リスト表示(json)', 1
      it_behaves_like 'リスト表示(json)', 2
      it_behaves_like 'リダイレクト(json)', 3
    end

    shared_examples_for '[未ログイン][*]権限がない' do
      it_behaves_like 'ToLogin(html)'
      it_behaves_like 'ToNG(json)', 401
    end
    shared_examples_for '[ログイン中/削除予約済み][*]権限がない' do
      it_behaves_like 'ToNG(html)', 403
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中/削除予約済み][*]権限がない' do
      it_behaves_like 'ToNG(html)', 403
      it_behaves_like 'ToNG(json)', 403
    end
    shared_examples_for '[ログイン中/削除予約済み][*]権限がある' do |power|
      # it_behaves_like '[ログイン中/削除予約済み][*][ある]メンバーがいない', power # NOTE: 自分がいる
      it_behaves_like '[ログイン中/削除予約済み][*][ある]メンバーが最大表示数と同じ', power
      it_behaves_like '[ログイン中/削除予約済み][*][ある]メンバーが最大表示数より多い', power
    end
    shared_examples_for '[APIログイン中/削除予約済み][*]権限がある' do |power|
      # it_behaves_like '[APIログイン中/削除予約済み][*][ある]メンバーがいない', power # NOTE: 自分がいる
      it_behaves_like '[APIログイン中/削除予約済み][*][ある]メンバーが最大表示数と同じ', power
      it_behaves_like '[APIログイン中/削除予約済み][*][ある]メンバーが最大表示数より多い', power
    end

    shared_examples_for '[未ログイン]スペースが存在しない' do
      let_it_be(:space) { FactoryBot.build_stubbed(:space) }
      it_behaves_like 'ToLogin(html)'
      it_behaves_like 'ToNG(json)', 401
    end
    shared_examples_for '[ログイン中/削除予約済み]スペースが存在しない' do
      let_it_be(:space) { FactoryBot.build_stubbed(:space) }
      it_behaves_like 'ToNG(html)', 404
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中/削除予約済み]スペースが存在しない' do
      let_it_be(:space) { FactoryBot.build_stubbed(:space) }
      it_behaves_like 'ToNG(html)', 404
      it_behaves_like 'ToNG(json)', 404
    end
    shared_examples_for '[未ログイン]スペースが公開' do
      let_it_be(:space) { FactoryBot.create(:space, :public) }
      it_behaves_like '[未ログイン][*]権限がない'
      # it_behaves_like '[未ログイン][公開]権限がある', :admin # NOTE: 未ログインの為、権限がない
      # it_behaves_like '[未ログイン][公開]権限がある', :writer
      # it_behaves_like '[未ログイン][公開]権限がある', :reader
    end
    shared_examples_for '[ログイン中/削除予約済み]スペースが公開' do
      let_it_be(:space) { FactoryBot.create(:space, :public) }
      it_behaves_like '[ログイン中/削除予約済み][*]権限がない'
      it_behaves_like '[ログイン中/削除予約済み][*]権限がある', :admin
      it_behaves_like '[ログイン中/削除予約済み][*]権限がある', :writer
      it_behaves_like '[ログイン中/削除予約済み][*]権限がある', :reader
    end
    shared_examples_for '[APIログイン中/削除予約済み]スペースが公開' do
      let_it_be(:space) { FactoryBot.create(:space, :public) }
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がない'
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がある', :admin
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がある', :writer
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がある', :reader
    end
    shared_examples_for '[未ログイン]スペースが非公開' do
      let_it_be(:space) { FactoryBot.create(:space, :private) }
      it_behaves_like '[未ログイン][*]権限がない'
      # it_behaves_like '[未ログイン][非公開]権限がある', :admin # NOTE: 未ログインの為、権限がない
      # it_behaves_like '[未ログイン][非公開]権限がある', :writer
      # it_behaves_like '[未ログイン][非公開]権限がある', :reader
    end
    shared_examples_for '[ログイン中/削除予約済み]スペースが非公開' do
      let_it_be(:space) { FactoryBot.create(:space, :private) }
      it_behaves_like '[ログイン中/削除予約済み][*]権限がない'
      it_behaves_like '[ログイン中/削除予約済み][*]権限がある', :admin
      it_behaves_like '[ログイン中/削除予約済み][*]権限がある', :writer
      it_behaves_like '[ログイン中/削除予約済み][*]権限がある', :reader
    end
    shared_examples_for '[APIログイン中/削除予約済み]スペースが非公開' do
      let_it_be(:space) { FactoryBot.create(:space, :private) }
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がない'
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がある', :admin
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がある', :writer
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がある', :reader
    end

    context '未ログイン' do
      include_context '未ログイン処理'
      it_behaves_like '[未ログイン]スペースが存在しない'
      it_behaves_like '[未ログイン]スペースが公開'
      it_behaves_like '[未ログイン]スペースが非公開'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中/削除予約済み]スペースが存在しない'
      it_behaves_like '[ログイン中/削除予約済み]スペースが公開'
      it_behaves_like '[ログイン中/削除予約済み]スペースが非公開'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', :destroy_reserved
      it_behaves_like '[ログイン中/削除予約済み]スペースが存在しない'
      it_behaves_like '[ログイン中/削除予約済み]スペースが公開'
      it_behaves_like '[ログイン中/削除予約済み]スペースが非公開'
    end
    context 'APIログイン中' do
      include_context 'APIログイン処理'
      it_behaves_like '[APIログイン中/削除予約済み]スペースが存在しない'
      it_behaves_like '[APIログイン中/削除予約済み]スペースが公開'
      it_behaves_like '[APIログイン中/削除予約済み]スペースが非公開'
    end
    context 'APIログイン中（削除予約済み）' do
      include_context 'APIログイン処理', :destroy_reserved
      it_behaves_like '[APIログイン中/削除予約済み]スペースが存在しない'
      it_behaves_like '[APIログイン中/削除予約済み]スペースが公開'
      it_behaves_like '[APIログイン中/削除予約済み]スペースが非公開'
    end
  end

  describe 'GET #index (.search)' do
    # TODO
  end

  describe 'GET #index (.power)' do
    # TODO
  end

  describe 'GET #index (.order)' do
    # TODO
  end
end
