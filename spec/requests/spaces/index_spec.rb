require 'rails_helper'

RSpec.describe 'Spaces', type: :request do
  let(:response_json) { JSON.parse(response.body) }
  let(:response_json_space)  { response_json['space'] }
  let(:response_json_spaces) { response_json['spaces'] }

  # テスト内容（共通）
  shared_examples_for 'ToOK[名称]' do
    it 'HTTPステータスが200。対象の名称が含まれる/一致する' do
      Settings['default_spaces_limit'] = spaces.count if spaces.count.positive?
      is_expected.to eq(200)
      if subject_format == :json
        # JSON
        expect(response_json_spaces.count).to eq(spaces.count)
        spaces.each_with_index do |space, index|
          expect(response_json_spaces[index]['name']).to eq(space.name)
        end
      else
        # HTML
        spaces.each do |space|
          expect(response.body).to include(space.name)
        end
      end
    end
  end

  # GET /spaces スペース一覧
  # GET /spaces(.json) スペース一覧API
  # 前提条件
  #   検索条件なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）, APIログイン中, APIログイン中（削除予約済み）
  #   スペース: 存在しない, 最大表示数と同じ, 最大表示数より多い
  #   ＋URLの拡張子: ない, .json
  #   ＋Acceptヘッダ: HTMLが含まれる, JSONが含まれる
  describe 'GET #index' do
    subject { get spaces_path(page: subject_page, format: subject_format), headers: auth_headers.merge(accept_headers) }

    # テスト内容
    shared_examples_for 'ToOK(html/*)' do
      it 'HTTPステータスが200' do
        is_expected.to eq(200)
      end
    end
    shared_examples_for 'ToOK(json/json)' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it 'HTTPステータスが200。対象項目が一致する' do
        is_expected.to eq(200)
        expect(response_json['success']).to eq(true)
        if Settings['enable_public_space']
          search_params = { text: nil, public: 1, private: 1, join: 1, nojoin: 1, active: 1, destroy: 0 }
        else
          search_params = { text: nil, active: 1, destroy: 0 }
        end
        expect(response_json['search_params']).to eq(search_params.stringify_keys)
        expect(response_json_space['total_count']).to eq(spaces.count)
        expect(response_json_space['current_page']).to eq(subject_page)
        expect(response_json_space['total_pages']).to eq((spaces.count - 1).div(Settings['default_spaces_limit']) + 1)
        expect(response_json_space['limit_value']).to eq(Settings['default_spaces_limit'])
      end
    end

    shared_examples_for 'ページネーション表示' do |page, link_page|
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      let(:subject_page) { page }
      let(:url_page)     { link_page >= 2 ? link_page : nil }
      it "#{link_page}ページのパスが含まれる" do
        subject
        expect(response.body).to include("\"#{spaces_path(page: url_page)}\"")
      end
    end
    shared_examples_for 'ページネーション非表示' do |page, link_page|
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      let(:subject_page) { page }
      let(:url_page)     { link_page >= 2 ? link_page : nil }
      it "#{link_page}ページのパスが含まれない" do
        subject
        expect(response.body).not_to include("\"#{spaces_path(page: url_page)}\"")
      end
    end

    shared_examples_for 'リスト表示（0件）' do
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      let(:subject_page) { 1 }
      it '存在しないメッセージが含まれる' do
        subject
        expect(response.body).to include('スペースが見つかりません。')
      end
    end
    shared_examples_for 'リスト表示' do |page|
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      let(:subject_page) { page }
      let(:user_spaces)  { @public_spaces + @public_nojoin_spaces + @private_spaces }
      let(:start_no)     { (Settings['default_spaces_limit'] * (page - 1)) + 1 }
      let(:end_no)       { [user_spaces.count, Settings['default_spaces_limit'] * page].min }
      it '対象項目が含まれる' do
        subject
        (start_no..end_no).each do |no|
          space = user_spaces[user_spaces.count - no]
          # 名称
          expect_space_html(response, space, nil, false)
          # 説明
          expect(response.body).to include(space.description)
          # (アクション)
          url = "href=\"#{members_path(space.code)}\""
          if @members[space.id].present?
            expect(response.body).to include(Member.powers_i18n[@members[space.id]])
            expect(response.body).to include(url)
          else
            expect(response.body).not_to include(url)
          end
        end
      end
    end
    shared_examples_for 'リスト表示(json)' do |page|
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      let(:subject_page) { page }
      let(:start_no)     { (Settings['default_spaces_limit'] * (page - 1)) + 1 }
      let(:end_no)       { [spaces.count, Settings['default_spaces_limit'] * page].min }
      it '件数・対象項目が一致する' do
        subject
        expect(response_json_spaces.count).to eq(end_no - start_no + 1)
        (start_no..end_no).each do |no|
          data = response_json_spaces[no - start_no]
          space = spaces[spaces.count - no]
          expect_space_basic_json(data, space)

          power = members[space.id]
          if power.present?
            expect(data['current_member']['power']).to eq(power)
            expect(data['current_member']['power_i18n']).to eq(Member.powers_i18n[power])
          else
            expect(data['current_member']).to be_nil
          end
        end
      end
    end

    shared_examples_for 'リダイレクト' do |page, redirect_page|
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      let(:subject_page) { page }
      let(:url_page)     { redirect_page >= 2 ? redirect_page : nil }
      it '最終ページにリダイレクトする' do
        is_expected.to redirect_to(spaces_path(page: url_page))
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
    shared_examples_for '[*]スペースが存在しない' do
      include_context 'スペース一覧作成', 0, 0, 0, 0
      it_behaves_like 'ToOK(html)', 1
      it_behaves_like 'ページネーション非表示', 1, 2
      it_behaves_like 'リスト表示（0件）'
      it_behaves_like 'リダイレクト', 2, 1
      it_behaves_like 'ToOK(json)', 1
      it_behaves_like 'リスト表示(json)', 1
      it_behaves_like 'リダイレクト(json)', 2
    end
    shared_examples_for '[未ログイン]スペースが最大表示数と同じ' do
      count = Settings['test_spaces']
      all = count['public_admin_count'] + count['public_none_count'] + count['private_admin_count'] + count['private_reader_count']
      include_context 'スペース一覧作成', 0, all, 0, 0
      it_behaves_like 'ToOK(html)', 1
      it_behaves_like 'ページネーション非表示', 1, 2
      it_behaves_like 'リスト表示', 1
      it_behaves_like 'リダイレクト', 2, 1
      it_behaves_like 'ToOK(json)', 1
      it_behaves_like 'リスト表示(json)', 1
      it_behaves_like 'リダイレクト(json)', 2
    end
    shared_examples_for '[ログイン中/削除予約済み]スペースが最大表示数と同じ' do
      count = Settings['test_spaces']
      include_context 'スペース一覧作成', count['public_admin_count'], count['public_none_count'], count['private_admin_count'], count['private_reader_count']
      it_behaves_like 'ToOK(html)', 1
      it_behaves_like 'ページネーション非表示', 1, 2
      it_behaves_like 'リスト表示', 1
      it_behaves_like 'リダイレクト', 2, 1
      it_behaves_like 'ToOK(json)', 1
      it_behaves_like 'リスト表示(json)', 1
      it_behaves_like 'リダイレクト(json)', 2
    end
    shared_examples_for '[APIログイン中/削除予約済み]スペースが最大表示数と同じ' do
      count = Settings['test_spaces']
      include_context 'スペース一覧作成', count['public_admin_count'], count['public_none_count'], count['private_admin_count'], count['private_reader_count']
      it_behaves_like 'ToOK(html)', 1
      it_behaves_like 'ページネーション非表示', 1, 2
      it_behaves_like 'リスト表示', 1
      it_behaves_like 'リダイレクト', 2, 1
      it_behaves_like 'ToOK(json)', 1
      it_behaves_like 'リスト表示(json)', 1
      it_behaves_like 'リダイレクト(json)', 2
    end
    shared_examples_for '[未ログイン]スペースが最大表示数より多い' do
      count = Settings['test_spaces']
      all = count['public_admin_count'] + count['public_none_count'] + count['private_admin_count'] + count['private_reader_count']
      include_context 'スペース一覧作成', 0, all + 1, 0, 0
      it_behaves_like 'ToOK(html)', 1
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
    shared_examples_for '[ログイン中/削除予約済み]スペースが最大表示数より多い' do
      count = Settings['test_spaces']
      include_context 'スペース一覧作成', count['public_admin_count'], count['public_none_count'] + 1, count['private_admin_count'], count['private_reader_count']
      it_behaves_like 'ToOK(html)', 1
      it_behaves_like 'ToOK(html)', 2
      it_behaves_like 'ページネーション表示', 1, 2
      it_behaves_like 'ページネーション表示', 2, 1
      it_behaves_like 'リスト表示', 1
      it_behaves_like 'リスト表示', 2
      it_behaves_like 'リダイレクト', 3, 2
      # it_behaves_like 'ToOK(json)', 1 # NOTE: APIは未ログイン扱いの為
      # it_behaves_like 'ToOK(json)', 2
      # it_behaves_like 'リスト表示(json)', 1
      # it_behaves_like 'リスト表示(json)', 2
      # it_behaves_like 'リダイレクト(json)', 3
    end
    shared_examples_for '[APIログイン中/削除予約済み]スペースが最大表示数より多い' do
      count = Settings['test_spaces']
      include_context 'スペース一覧作成', count['public_admin_count'], count['public_none_count'] + 1, count['private_admin_count'], count['private_reader_count']
      it_behaves_like 'ToOK(html)', 1
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

    shared_examples_for '[ログイン中/削除予約済み]' do
      let(:spaces)  { @public_spaces + @public_nojoin_spaces } # NOTE: APIは未ログイン扱いの為、公開しか見れない
      let(:members) { {} }
      it_behaves_like '[*]スペースが存在しない'
      it_behaves_like '[ログイン中/削除予約済み]スペースが最大表示数と同じ'
      it_behaves_like '[ログイン中/削除予約済み]スペースが最大表示数より多い'
    end
    shared_examples_for '[APIログイン中/削除予約済み]' do
      let(:spaces)  { @public_spaces + @public_nojoin_spaces + @private_spaces }
      let(:members) { @members }
      it_behaves_like '[*]スペースが存在しない'
      it_behaves_like '[APIログイン中/削除予約済み]スペースが最大表示数と同じ'
      it_behaves_like '[APIログイン中/削除予約済み]スペースが最大表示数より多い'
    end

    context '未ログイン' do
      include_context '未ログイン処理'
      let(:spaces)  { @public_spaces + @public_nojoin_spaces }
      let(:members) { {} }
      it_behaves_like '[*]スペースが存在しない'
      it_behaves_like '[未ログイン]スペースが最大表示数と同じ'
      it_behaves_like '[未ログイン]スペースが最大表示数より多い'
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
  #   公開スペース（未参加） + 公開スペース（参加）
  #   検索文字列あり（部分一致, 大文字・小文字を区別しない）: name, description
  #   オプションなし
  describe 'GET #index (.search)' do
    subject { get spaces_path(format: subject_format), params: params, headers: auth_headers.merge(accept_headers) }
    let_it_be(:nojoin_space) { FactoryBot.create(:space, :public, name: 'space(Aaa)', description: 'description(Bbb)') }
    let_it_be(:join_space)   { FactoryBot.create(:space, :public, name: 'space(Bbb)', description: 'description(Aaa)') }
    before_all { FactoryBot.create(:space) } # NOTE: 対象外
    let(:params) { { text: 'aaa' } }

    # テストケース
    shared_examples_for '検索文字列あり' do
      let(:spaces) { [join_space, nojoin_space] }
      it_behaves_like 'ToOK[名称]'
    end

    context 'ログイン中（URLの拡張子がない/AcceptヘッダにHTMLが含まれる）' do
      include_context 'ログイン処理'
      before_all { FactoryBot.create(:member, :admin, space: join_space, user: user) }
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      it_behaves_like '検索文字列あり'
    end
    context 'APIログイン中（URLの拡張子が.json/AcceptヘッダにJSONが含まれる）' do
      include_context 'APIログイン処理'
      before_all { FactoryBot.create(:member, :admin, space: join_space, user: user) }
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it_behaves_like '検索文字列あり'
    end
  end

  # 前提条件
  #   ログイン中（URLの拡張子がない/AcceptヘッダにHTMLが含まれる）, APIログイン中（URLの拡張子が.json/AcceptヘッダにJSONが含まれる）
  #   検索文字列なし
  # テストパターン
  #   公開・非公開、参加・未参加、有効・削除予定: 全て1, 1と0, 0と1, 0と0
  describe 'GET #index (.by_target)' do
    subject { get spaces_path(format: subject_format), params: params, headers: auth_headers.merge(accept_headers) }

    # テストケース
    shared_examples_for '全て1' do
      let(:params) { { public: 1, private: 1, join: 1, nojoin: 1, active: 1, destroy: 1 } }
      let(:spaces) { (@public_spaces + @public_nojoin_spaces + @public_nojoin_destroy_spaces + @private_spaces).reverse }
      it_behaves_like 'ToOK[名称]'
    end
    shared_examples_for '公開・非公開が1と0' do
      let(:params) { { public: 1, private: 0, join: 1, nojoin: 1, active: 1, destroy: 1 } }
      let(:spaces) { (@public_spaces + @public_nojoin_spaces + @public_nojoin_destroy_spaces).reverse }
      it_behaves_like 'ToOK[名称]'
    end
    shared_examples_for '公開・非公開が0と1' do
      let(:params) { { public: 0, private: 1, join: 1, nojoin: 1, active: 1, destroy: 1 } }
      let(:spaces) { @private_spaces.reverse }
      it_behaves_like 'ToOK[名称]'
    end
    shared_examples_for '公開・非公開が0と0' do
      let(:params) { { public: 0, private: 0, join: 1, nojoin: 1, active: 1, destroy: 1 } }
      let(:spaces) { [] }
      it_behaves_like 'ToOK[名称]'
    end
    shared_examples_for '参加・未参加が1と0' do
      let(:params) { { public: 1, private: 1, join: 1, nojoin: 0, active: 1, destroy: 1 } }
      let(:spaces) { (@public_spaces + @private_spaces).reverse }
      it_behaves_like 'ToOK[名称]'
    end
    shared_examples_for '参加・未参加が0と1' do
      let(:params) { { public: 1, private: 1, join: 0, nojoin: 1, active: 1, destroy: 1 } }
      let(:spaces) { (@public_nojoin_spaces + @public_nojoin_destroy_spaces).reverse }
      it_behaves_like 'ToOK[名称]'
    end
    shared_examples_for '参加・未参加が0と0' do
      let(:params) { { public: 1, private: 1, join: 0, nojoin: 0, active: 1, destroy: 1 } }
      let(:spaces) { [] }
      it_behaves_like 'ToOK[名称]'
    end
    shared_examples_for '有効・削除予定が1と0' do
      let(:params) { { public: 1, private: 1, join: 1, nojoin: 1, active: 1, destroy: 0 } }
      let(:spaces) { (@public_spaces + @public_nojoin_spaces + @private_spaces).reverse }
      it_behaves_like 'ToOK[名称]'
    end
    shared_examples_for '有効・削除予定が0と1' do
      let(:params) { { public: 1, private: 1, join: 1, nojoin: 1, active: 0, destroy: 1 } }
      let(:spaces) { @public_nojoin_destroy_spaces.reverse }
      it_behaves_like 'ToOK[名称]'
    end
    shared_examples_for '有効・削除予定が0と0' do
      let(:params) { { public: 1, private: 1, join: 1, nojoin: 1, active: 0, destroy: 0 } }
      let(:spaces) { [] }
      it_behaves_like 'ToOK[名称]'
    end

    shared_examples_for 'オプション' do
      it_behaves_like '全て1'
      if Settings['enable_public_space']
        it_behaves_like '公開・非公開が1と0'
        it_behaves_like '公開・非公開が0と1'
        it_behaves_like '公開・非公開が0と0'
        it_behaves_like '参加・未参加が1と0'
        it_behaves_like '参加・未参加が0と1'
        it_behaves_like '参加・未参加が0と0'
      end
      it_behaves_like '有効・削除予定が1と0'
      it_behaves_like '有効・削除予定が0と1'
      it_behaves_like '有効・削除予定が0と0'
    end

    context 'ログイン中（URLの拡張子がない/AcceptヘッダにHTMLが含まれる）' do
      include_context 'ログイン処理'
      include_context 'スペース一覧作成', 1, 1, 1, 1
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      it_behaves_like 'オプション'
    end
    context 'APIログイン中（URLの拡張子が.json/AcceptヘッダにJSONが含まれる）' do
      include_context 'APIログイン処理'
      include_context 'スペース一覧作成', 1, 1, 1, 1
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it_behaves_like 'オプション'
    end
  end
end
