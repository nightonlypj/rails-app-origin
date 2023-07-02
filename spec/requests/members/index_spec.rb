require 'rails_helper'

RSpec.describe 'Members', type: :request do
  let(:response_json) { JSON.parse(response.body) }
  let(:response_json_space)   { response_json['space'] }
  let(:response_json_member)  { response_json['member'] }
  let(:response_json_members) { response_json['members'] }
  let(:response_json_space_current_member) { response_json_space['current_member'] }
  let(:default_params) { { text: nil, power: Member.powers.keys.join(','), sort: 'invitationed_at', desc: 1 } }

  # テスト内容（共通）
  shared_examples_for 'ToOK[氏名]' do
    let!(:default_members_limit) { Settings.default_members_limit }
    before { Settings.default_members_limit = [default_members_limit, members.count].max }
    after  { Settings.default_members_limit = default_members_limit }
    it 'HTTPステータスが200。対象の氏名が一致する/含まれる' do
      is_expected.to eq(200)
      if subject_format == :json
        # JSON
        expect(response_json_members.count).to eq(members.count)
        members.each_with_index do |member, index|
          expect(response_json_members[members.count - index - 1]['user']['name']).to eq(member.user.name)
        end

        input_params = params.to_h { |key, value| [key, %i[text power sort].include?(key) ? value : value.to_i] }
        expect(response_json['search_params']).to eq(default_params.merge(input_params).stringify_keys)
      else
        # HTML
        members.each do |member|
          expect(response.body).to include(member.user.name)
        end
      end
    end
  end
  shared_examples_for 'ToOK[count](json)' do
    it 'HTTPステータスが200。件数が一致する' do
      is_expected.to eq(200)
      expect(response_json_members.count).to eq(members.count)

      input_params = params.to_h { |key, value| [key, %i[text power sort].include?(key) ? value : value.to_i] }
      expect(response_json['search_params']).to eq(default_params.merge(input_params).stringify_keys)
    end
  end

  # GET /members メンバー一覧
  # GET /members(.json) メンバー一覧API
  # 前提条件
  #   検索条件なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）, APIログイン中, APIログイン中（削除予約済み）
  #   スペース: 存在しない, 公開, 非公開
  #   権限: ある（管理者〜閲覧者）, ない
  #   メンバー: いない, 最大表示数と同じ, 最大表示数より多い
  #     権限: 管理者〜閲覧者
  #     招待者: いない, いる, アカウント削除済み
  #     最終更新者: いない, いる, アカウント削除済み
  #   ＋URLの拡張子: ない, .json
  #   ＋Acceptヘッダ: HTMLが含まれる, JSONが含まれる
  describe 'GET #index' do
    subject { get members_path(space_code: space.code, page: subject_page, format: subject_format), headers: auth_headers.merge(accept_headers) }
    let_it_be(:space_not)     { FactoryBot.build_stubbed(:space) }
    let_it_be(:space_public)  { FactoryBot.create(:space, :public) }
    let_it_be(:space_private) { FactoryBot.create(:space, :private, created_user: space_public.created_user) }

    # テスト内容
    shared_examples_for 'ToOK(html/*)' do
      it 'HTTPステータスが200。対象項目が含まれる' do
        is_expected.to eq(200)
        expect_space_html(response, space, user_power)

        new_url = "href=\"#{new_member_path(space.code)}\""
        download_url = "href=\"#{create_download_path(model: :member, space_code: space.code, search_params: { page: subject_page }).gsub(/&/, '&amp;')}\""
        destroy_url = "action=\"#{destroy_member_path(space.code)}\""
        if user_power == :admin
          expect(response.body).to include(new_url)
          expect(response.body).to include(download_url)
          expect(response.body).to include(destroy_url)
        else
          expect(response.body).not_to include(new_url)
          expect(response.body).not_to include(download_url)
          expect(response.body).not_to include(destroy_url)
        end
      end
    end
    shared_examples_for 'ToOK(json/json)' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it 'HTTPステータスが200。対象項目が一致する' do
        is_expected.to eq(200)
        expect(response_json['success']).to eq(true)
        expect(response_json['search_params']).to eq(default_params.stringify_keys)

        expect(response_json_space['code']).to eq(space.code)
        expect_image_json(response_json_space, space)
        expect(response_json_space['name']).to eq(space.name)
        expect(response_json_space['description']).to eq(space.description)
        expect(response_json_space['private']).to eq(space.private)

        ## 削除予約
        expect(response_json_space['destroy_requested_at']).to eq(I18n.l(space.destroy_requested_at, format: :json, default: nil))
        expect(response_json_space['destroy_schedule_at']).to eq(I18n.l(space.destroy_schedule_at, format: :json, default: nil))

        expect(response_json_space_current_member['power']).to eq(user_power.to_s)
        expect(response_json_space_current_member['power_i18n']).to eq(Member.powers_i18n[user_power])
        expect(response_json_space_current_member.count).to eq(2)
        expect(response_json_space.count).to eq(9)

        expect(response_json_member['total_count']).to eq(members.count)
        expect(response_json_member['current_page']).to eq(subject_page)
        expect(response_json_member['total_pages']).to eq((members.count - 1).div(Settings.default_members_limit) + 1)
        expect(response_json_member['limit_value']).to eq(Settings.default_members_limit)
        expect(response_json_member.count).to eq(4)

        expect(response_json.count).to eq(5)
      end
    end

    shared_examples_for 'ページネーション表示' do |page, link_page|
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      let(:subject_page) { page }
      let(:url_page)     { link_page >= 2 ? link_page : nil }
      it "#{link_page}ページのパスが含まれる" do
        subject
        expect(response.body).to include("\"#{members_path(space_code: space.code, page: url_page)}\"")
      end
    end
    shared_examples_for 'ページネーション非表示' do |page, link_page|
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      let(:subject_page) { page }
      let(:url_page)     { link_page >= 2 ? link_page : nil }
      it "#{link_page}ページのパスが含まれない" do
        subject
        expect(response.body).not_to include("\"#{members_path(space_code: space.code, page: url_page)}\"")
      end
    end

    shared_examples_for 'リスト表示' do |page|
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      let(:subject_page) { page }
      let(:start_no)     { (Settings.default_members_limit * (page - 1)) + 1 }
      let(:end_no)       { [members.count, Settings.default_members_limit * page].min }
      it '対象項目が含まれる' do
        subject
        (start_no..end_no).each do |no|
          member = members[members.count - no]
          # (メンバー解除)
          codes = "id=\"codes[#{member.user.code}]\""
          if user_power == :admin
            expect(response.body).to include(codes)
          else
            expect(response.body).not_to include(codes)
          end
          # メンバー
          expect(response.body).to include(member.user.image_url(:small))
          expect(response.body).to include(member.user.name)
          # メールアドレス
          if user_power == :admin
            expect(response.body).to include(member.user.email)
          else
            expect(response.body).not_to include(member.user.email)
          end
          url = "href=\"#{edit_member_path(space.code, member.user.code)}\""
          if user_power == :admin && member.user != user
            expect(response.body).to include(url)
          else
            expect(response.body).not_to include(url)
          end
          # 権限
          expect(response.body).to include(member.power_i18n)
          # 招待者
          if member.invitationed_user.present?
            if user_power == :admin
              expect(response.body).to include(member.invitationed_user.image_url(:small))
              expect(response.body).to include(member.invitationed_user.name)
            else
              # expect(response.body).not_to include(member.invitationed_user.image_url(:small)) # NOTE: ユニークではない為
              expect(response.body).not_to include(member.invitationed_user.name)
            end
          end
          # 招待日時
          expect(response.body).to include(I18n.l(member.invitationed_at)) if member.invitationed_at.present?
          # 更新者
          if member.last_updated_user.present?
            if user_power == :admin
              expect(response.body).to include(member.last_updated_user.image_url(:small))
              expect(response.body).to include(member.last_updated_user.name)
            else
              # expect(response.body).not_to include(member.last_updated_user.image_url(:small)) # NOTE: ユニークではない為
              expect(response.body).not_to include(member.last_updated_user.name)
            end
          end
          # 更新日時
          if member.last_updated_at.present?
            if user_power == :admin
              expect(response.body).to include(I18n.l(member.last_updated_at))
            else
              expect(response.body).not_to include(I18n.l(member.last_updated_at))
            end
          end
        end
      end
    end
    shared_examples_for 'リスト表示(json)' do |page|
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      let(:subject_page) { page }
      let(:start_no)     { (Settings.default_members_limit * (page - 1)) + 1 }
      let(:end_no)       { [members.count, Settings.default_members_limit * page].min }
      it '件数・対象項目が一致する' do
        subject
        expect(response_json_members.count).to eq(end_no - start_no + 1)
        (start_no..end_no).each do |no|
          data = response_json_members[no - start_no]
          count = expect_member_json(data, members[members.count - no], user_power)
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
        is_expected.to redirect_to(members_path(space_code: space.code, page: url_page))
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
      count = Settings.test_members_count
      include_context 'メンバー一覧作成', count.admin, count.reader
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
    shared_examples_for '[APIログイン中/削除予約済み][*][ある]メンバーが最大表示数と同じ' do |power|
      let_it_be(:user_power) { power }
      count = Settings.test_members_count
      include_context 'メンバー一覧作成', count.admin, count.reader
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
    shared_examples_for '[ログイン中/削除予約済み][*][ある]メンバーが最大表示数より多い' do |power|
      let_it_be(:user_power) { power }
      count = Settings.test_members_count
      include_context 'メンバー一覧作成', count.admin, count.reader + 1
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
    shared_examples_for '[APIログイン中/削除予約済み][*][ある]メンバーが最大表示数より多い' do |power|
      let_it_be(:user_power) { power }
      count = Settings.test_members_count
      include_context 'メンバー一覧作成', count.admin, count.reader + 1
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
      # it_behaves_like '[ログイン中/削除予約済み][*][ある]メンバーがいない', power # NOTE: 自分がいる
      it_behaves_like '[ログイン中/削除予約済み][*][ある]メンバーが最大表示数と同じ', power
      it_behaves_like '[ログイン中/削除予約済み][*][ある]メンバーが最大表示数より多い', power
    end
    shared_examples_for '[APIログイン中/削除予約済み][*]権限がある' do |power|
      # it_behaves_like '[APIログイン中/削除予約済み][*][ある]メンバーがいない', power # NOTE: 自分がいる
      it_behaves_like '[APIログイン中/削除予約済み][*][ある]メンバーが最大表示数と同じ', power
      it_behaves_like '[APIログイン中/削除予約済み][*][ある]メンバーが最大表示数より多い', power
    end
    shared_examples_for '[ログイン中/削除予約済み][*]権限がない' do
      it_behaves_like 'ToNG(html)', Settings.api_only_mode ? 406 : 403
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中/削除予約済み][*]権限がない' do
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
      it_behaves_like '[ログイン中/削除予約済み][*]権限がある', :reader
      it_behaves_like '[ログイン中/削除予約済み][*]権限がない'
    end
    shared_examples_for '[APIログイン中/削除予約済み]スペースが公開' do
      let_it_be(:space) { space_public }
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がある', :admin
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がある', :reader
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がない'
    end
    shared_examples_for '[ログイン中/削除予約済み]スペースが非公開' do
      let_it_be(:space) { space_private }
      it_behaves_like '[ログイン中/削除予約済み][*]権限がある', :admin
      it_behaves_like '[ログイン中/削除予約済み][*]権限がある', :reader
      it_behaves_like '[ログイン中/削除予約済み][*]権限がない'
    end
    shared_examples_for '[APIログイン中/削除予約済み]スペースが非公開' do
      let_it_be(:space) { space_private }
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がある', :admin
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がある', :reader
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がない'
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

  # 前提条件
  #   ログイン中（URLの拡張子がない/AcceptヘッダにHTMLが含まれる）, APIログイン中（URLの拡張子が.json/AcceptヘッダにJSONが含まれる）
  #   権限がある, 検索オプションなし, 氏名のみ確認
  # テストパターン
  #   権限: 管理者〜閲覧者
  #   部分一致（大文字・小文字を区別しない）, 不一致: 氏名, メールアドレス（管理者のみ表示）
  describe 'GET #index (.search)' do
    subject { get members_path(space_code: space.code, format: subject_format), params:, headers: auth_headers.merge(accept_headers) }
    let_it_be(:space)             { FactoryBot.create(:space) }
    let_it_be(:member_all)        { FactoryBot.create(:member, space:, user: FactoryBot.create(:user, name: '氏名(Aaa)')) }
    let_it_be(:member_admin_only) { FactoryBot.create(:member, space:, user: FactoryBot.create(:user, email: '_Aaa@example.com')) }
    before_all { FactoryBot.create(:member, user: FactoryBot.create(:user, name: '氏名(Aaa)')) } # NOTE: 対象外

    # テスト内容
    shared_examples_for 'ToNG[0件]' do
      it '0件/存在しないメッセージが含まれる' do
        is_expected.to eq(200)
        if subject_format == :json
          # JSON
          expect(response_json_members.count).to eq(0)
        else
          # HTML
          expect(response.body).to include('対象のメンバーが見つかりません。')
        end
      end
    end

    # テストケース
    shared_examples_for '[管理者]部分一致' do
      let(:params) { { text: 'aaa' } }
      let(:members) { [member_all, member_admin_only] }
      it_behaves_like 'ToOK[氏名]'
    end
    shared_examples_for '[管理者以外]部分一致' do
      let(:params) { { text: 'aaa' } }
      let(:members) { [member_all] }
      it_behaves_like 'ToOK[氏名]'
    end
    shared_examples_for '[*]不一致' do
      let(:params) { { text: 'zzz' } }
      it_behaves_like 'ToNG[0件]'
    end

    shared_examples_for '管理者' do |power|
      before_all { FactoryBot.create(:member, power, space:, user:) }
      it_behaves_like '[管理者]部分一致'
      it_behaves_like '[*]不一致'
    end
    shared_examples_for '管理者以外' do |power|
      before_all { FactoryBot.create(:member, power, space:, user:) }
      it_behaves_like '[管理者以外]部分一致'
      it_behaves_like '[*]不一致'
    end

    shared_examples_for '権限' do
      it_behaves_like '管理者', :admin
      it_behaves_like '管理者以外', :reader
    end

    context 'ログイン中（URLの拡張子がない/AcceptヘッダにHTMLが含まれる）' do
      next if Settings.api_only_mode

      include_context 'ログイン処理'
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      it_behaves_like '権限'
    end
    context 'APIログイン中（URLの拡張子が.json/AcceptヘッダにJSONが含まれる）' do
      include_context 'APIログイン処理'
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it_behaves_like '権限'
    end
  end

  # 前提条件
  #   ログイン中（URLの拡張子がない/AcceptヘッダにHTMLが含まれる）, APIログイン中（URLの拡張子が.json/AcceptヘッダにJSONが含まれる）
  #   権限あり, 検索テキスト、並び順指定なし, 氏名のみ確認
  # テストパターン
  #   管理者, 投稿者, 閲覧者 の組み合わせ
  describe 'GET #index (.power)' do
    subject { get members_path(space_code: space.code, format: subject_format), params:, headers: auth_headers.merge(accept_headers) }
    let_it_be(:space)         { FactoryBot.create(:space) }
    let_it_be(:member_reader) { FactoryBot.create(:member, :reader, space:) }
    let_it_be(:member_writer) { FactoryBot.create(:member, :writer, space:) }

    # テストケース
    context 'ログイン中（URLの拡張子がない/AcceptヘッダにHTMLが含まれる）' do
      next if Settings.api_only_mode

      include_context 'ログイン処理'
      let_it_be(:member_admin) { FactoryBot.create(:member, :admin, space:, user:) }
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      context '■管理者, ■投稿者, ■閲覧者' do
        let(:params) { { power: { admin: 1, writer: 1, reader: 1 } } }
        let(:members) { [member_reader, member_writer, member_admin] }
        it_behaves_like 'ToOK[氏名]'
      end
      context '■管理者, ■投稿者, □閲覧者' do
        let(:params) { { power: { admin: 1, writer: 1, reader: 0 } } }
        let(:members) { [member_writer, member_admin] }
        it_behaves_like 'ToOK[氏名]'
      end
      context '■管理者, □投稿者, ■閲覧者' do
        let(:params) { { power: { admin: 1, writer: 0, reader: 1 } } }
        let(:members) { [member_reader, member_admin] }
        it_behaves_like 'ToOK[氏名]'
      end
      context '□管理者, ■投稿者, ■閲覧者' do
        let(:params) { { power: { admin: 0, writer: 1, reader: 1 } } }
        let(:members) { [member_reader, member_writer] }
        it_behaves_like 'ToOK[氏名]'
      end
      context '■管理者, □投稿者, □閲覧者' do
        let(:params) { { power: { admin: 1, writer: 0, reader: 0 } } }
        let(:members) { [member_admin] }
        it_behaves_like 'ToOK[氏名]'
      end
      context '□管理者, ■投稿者, □閲覧者' do
        let(:params) { { power: { admin: 0, writer: 1, reader: 0 } } }
        let(:members) { [member_writer] }
        it_behaves_like 'ToOK[氏名]'
      end
      context '□管理者, □投稿者, ■閲覧者' do
        let(:params) { { power: { admin: 0, writer: 0, reader: 1 } } }
        let(:members) { [member_reader] }
        it_behaves_like 'ToOK[氏名]'
      end
      context '□管理者, □投稿者, □閲覧者' do
        let(:params) { { power: { admin: 0, writer: 0, reader: 0 } } }
        let(:members) { [] }
        it_behaves_like 'ToOK[氏名]'
      end
    end
    context 'APIログイン中（URLの拡張子が.json/AcceptヘッダにJSONが含まれる）' do
      include_context 'APIログイン処理'
      let_it_be(:member_admin) { FactoryBot.create(:member, :admin, space:, user:) }
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      context '■管理者, ■投稿者, ■閲覧者' do
        let(:params) { { power: 'admin,writer,reader' } }
        let(:members) { [member_reader, member_writer, member_admin] }
        it_behaves_like 'ToOK[氏名]'
      end
      context '■管理者, ■投稿者, □閲覧者' do
        let(:params) { { power: 'admin,writer' } }
        let(:members) { [member_writer, member_admin] }
        it_behaves_like 'ToOK[氏名]'
      end
      context '■管理者, □投稿者, ■閲覧者' do
        let(:params) { { power: 'admin,reader' } }
        let(:members) { [member_reader, member_admin] }
        it_behaves_like 'ToOK[氏名]'
      end
      context '□管理者, ■投稿者, ■閲覧者' do
        let(:params) { { power: 'writer,reader' } }
        let(:members) { [member_reader, member_writer] }
        it_behaves_like 'ToOK[氏名]'
      end
      context '■管理者, □投稿者, □閲覧者' do
        let(:params) { { power: 'admin' } }
        let(:members) { [member_admin] }
        it_behaves_like 'ToOK[氏名]'
      end
      context '□管理者, ■投稿者, □閲覧者' do
        let(:params) { { power: 'writer' } }
        let(:members) { [member_writer] }
        it_behaves_like 'ToOK[氏名]'
      end
      context '□管理者, □投稿者, ■閲覧者' do
        let(:params) { { power: 'reader' } }
        let(:members) { [member_reader] }
        it_behaves_like 'ToOK[氏名]'
      end
      context '□管理者, □投稿者, □閲覧者' do
        let(:params) { { power: '' } }
        let(:members) { [] }
        it_behaves_like 'ToOK[氏名]'
      end
    end
  end

  # 前提条件
  #   APIログイン中（URLの拡張子が.json/AcceptヘッダにJSONが含まれる）
  #   権限あり, 検索テキスト、権限指定なし, 件数のみ確認
  # テストパターン
  #   対象: メンバー, メールアドレス, 権限, 招待者, 招待日時, 最終更新者, 最終更新日時
  #   並び順: ASC, DESC  ※ASCは1つのみ確認
  describe 'GET #index (.order)' do
    subject { get members_path(space_code: space.code, format: :json), params:, headers: auth_headers.merge(ACCEPT_INC_JSON) }
    include_context 'APIログイン処理'
    let_it_be(:space) { FactoryBot.create(:space) }
    let_it_be(:members) do
      [
        FactoryBot.create(:member, :writer, space:),
        FactoryBot.create(:member, :admin, space:, user:)
      ]
    end

    # テストケース
    context 'メンバー ASC' do
      let(:params) { { sort: 'user.name', desc: '0' } }
      it_behaves_like 'ToOK[count](json)'
    end
    context 'メンバー DESC' do
      let(:params) { { sort: 'user.name', desc: '1' } }
      it_behaves_like 'ToOK[count](json)'
    end
    context 'メールアドレス DESC' do
      let(:params) { { sort: 'user.email', desc: '1' } }
      it_behaves_like 'ToOK[count](json)'
    end
    context '権限 DESC' do
      let(:params) { { sort: 'power', desc: '1' } }
      it_behaves_like 'ToOK[count](json)'
    end
    context '招待者 DESC' do
      let(:params) { { sort: 'invitationed_user.name', desc: '1' } }
      it_behaves_like 'ToOK[count](json)'
    end
    context '招待日時 DESC' do
      let(:params) { { sort: 'invitationed_at', desc: '1' } }
      it_behaves_like 'ToOK[count](json)'
    end
    context '最終更新者 DESC' do
      let(:params) { { sort: 'last_updated_user.name', desc: '1' } }
      it_behaves_like 'ToOK[count](json)'
    end
    context '最終更新日時 DESC' do
      let(:params) { { sort: 'last_updated_at', desc: '1' } }
      it_behaves_like 'ToOK[count](json)'
    end
  end
end
