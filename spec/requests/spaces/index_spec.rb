require 'rails_helper'

RSpec.describe 'Spaces', type: :request do
  let(:response_json) { JSON.parse(response.body) }
  let(:response_json_space)  { response_json['space'] }
  let(:response_json_spaces) { response_json['spaces'] }

  # テスト内容（共通）
  shared_examples_for 'リスト表示（個別）' do
    it '対象の名称が含まれる' do
      Settings['default_spaces_limit'] = spaces.count if spaces.count.positive?
      subject
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
        expect(response_json['search_params']).to eq({ text: nil, public: 1, private: 1, join: 1, nojoin: 1, active: 1, destroy: 0 }.stringify_keys)
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
          expect(response.body).to include(space.image_url(:small)) # 画像
          expect(response.body).to include(space.name) # 名称
          expect(response.body).to include(space.description) # 説明
          expect(response.body).to include('非公開') if space.private # 非公開
          expect(response.body).to include(I18n.l(space.destroy_schedule_at.to_date)) if space.destroy_reserved? # 削除予定日時
          if @members[space.id].present?
            expect(response.body).to include(Member.powers_i18n[@members[space.id]]) # 権限
            expect(response.body).to include("href=\"#{members_path(space.code)}\"") # メンバー一覧
          else
            expect(response.body).not_to include("href=\"#{members_path(space.code)}\"")
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
          expect(data['code']).to eq(space.code)

          data_image_url = data['image_url']
          expect(data_image_url['mini']).to eq("#{Settings['base_image_url']}#{space.image_url(:mini)}")
          expect(data_image_url['small']).to eq("#{Settings['base_image_url']}#{space.image_url(:small)}")
          expect(data_image_url['medium']).to eq("#{Settings['base_image_url']}#{space.image_url(:medium)}")
          expect(data_image_url['large']).to eq("#{Settings['base_image_url']}#{space.image_url(:large)}")
          expect(data_image_url['xlarge']).to eq("#{Settings['base_image_url']}#{space.image_url(:xlarge)}")

          expect(data['name']).to eq(space.name)
          expect(data['description']).to eq(space.description)
          expect(data['private']).to eq(space.private)
          expect(data['destroy_requested_at']).to eq(I18n.l(space.destroy_requested_at, format: :json, default: nil))
          expect(data['destroy_schedule_at']).to eq(I18n.l(space.destroy_schedule_at, format: :json, default: nil))

          power = members[space.id]
          if power.blank?
            expect(data['current_member']).to be_nil
          else
            expect(data['current_member']['power']).to eq(power)
            expect(data['current_member']['power_i18n']).to eq(Member.powers_i18n[power])
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
      it_behaves_like 'リダイレクト', 2, 1
      it_behaves_like 'ToOK(json)', 1
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

    context '未ログイン' do
      let(:spaces)  { @public_spaces + @public_nojoin_spaces }
      let(:members) { {} }
      include_context '未ログイン処理'
      it_behaves_like '[*]スペースが存在しない'
      it_behaves_like '[未ログイン]スペースが最大表示数と同じ'
      it_behaves_like '[未ログイン]スペースが最大表示数より多い'
    end
    context 'ログイン中' do
      let(:spaces)  { @public_spaces + @public_nojoin_spaces } # NOTE: APIは未ログイン扱いの為、公開しか見れない
      let(:members) { {} }
      include_context 'ログイン処理'
      it_behaves_like '[*]スペースが存在しない'
      it_behaves_like '[ログイン中/削除予約済み]スペースが最大表示数と同じ'
      it_behaves_like '[ログイン中/削除予約済み]スペースが最大表示数より多い'
    end
    context 'ログイン中（削除予約済み）' do
      let(:spaces)  { @public_spaces + @public_nojoin_spaces } # NOTE: APIは未ログイン扱いの為、公開しか見れない
      let(:members) { {} }
      include_context 'ログイン処理', :destroy_reserved
      it_behaves_like '[*]スペースが存在しない'
      it_behaves_like '[ログイン中/削除予約済み]スペースが最大表示数と同じ'
      it_behaves_like '[ログイン中/削除予約済み]スペースが最大表示数より多い'
    end
    context 'APIログイン中' do
      let(:spaces)  { @public_spaces + @public_nojoin_spaces + @private_spaces }
      let(:members) { @members }
      include_context 'APIログイン処理'
      it_behaves_like '[*]スペースが存在しない'
      it_behaves_like '[APIログイン中/削除予約済み]スペースが最大表示数と同じ'
      it_behaves_like '[APIログイン中/削除予約済み]スペースが最大表示数より多い'
    end
    context 'APIログイン中（削除予約済み）' do
      let(:spaces)  { @public_spaces + @public_nojoin_spaces + @private_spaces }
      let(:members) { @members }
      include_context 'APIログイン処理', :destroy_reserved
      it_behaves_like '[*]スペースが存在しない'
      it_behaves_like '[APIログイン中/削除予約済み]スペースが最大表示数と同じ'
      it_behaves_like '[APIログイン中/削除予約済み]スペースが最大表示数より多い'
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
    shared_examples_for 'リスト表示' do
      let(:spaces) { [join_space, nojoin_space] }
      it_behaves_like 'リスト表示（個別）'
    end

    context 'ログイン中（URLの拡張子がない/AcceptヘッダにHTMLが含まれる）' do
      include_context 'ログイン処理'
      before_all { FactoryBot.create(:member, :admin, space: join_space, user: user) }
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      it_behaves_like 'リスト表示'
    end
    context 'APIログイン中（URLの拡張子が.json/AcceptヘッダにJSONが含まれる）' do
      include_context 'APIログイン処理'
      before_all { FactoryBot.create(:member, :admin, space: join_space, user: user) }
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it_behaves_like 'リスト表示'
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
      it_behaves_like 'リスト表示（個別）'
    end
    shared_examples_for '公開・非公開が1と0' do
      let(:params) { { public: 1, private: 0, join: 1, nojoin: 1, active: 1, destroy: 1 } }
      let(:spaces) { (@public_spaces + @public_nojoin_spaces + @public_nojoin_destroy_spaces).reverse }
      it_behaves_like 'リスト表示（個別）'
    end
    shared_examples_for '公開・非公開が0と1' do
      let(:params) { { public: 0, private: 1, join: 1, nojoin: 1, active: 1, destroy: 1 } }
      let(:spaces) { @private_spaces.reverse }
      it_behaves_like 'リスト表示（個別）'
    end
    shared_examples_for '公開・非公開が0と0' do
      let(:params) { { public: 0, private: 0, join: 1, nojoin: 1, active: 1, destroy: 1 } }
      let(:spaces) { [] }
      it_behaves_like 'リスト表示（個別）'
    end
    shared_examples_for '参加・未参加が1と0' do
      let(:params) { { public: 1, private: 1, join: 1, nojoin: 0, active: 1, destroy: 1 } }
      let(:spaces) { (@public_spaces + @private_spaces).reverse }
      it_behaves_like 'リスト表示（個別）'
    end
    shared_examples_for '参加・未参加が0と1' do
      let(:params) { { public: 1, private: 1, join: 0, nojoin: 1, active: 1, destroy: 1 } }
      let(:spaces) { (@public_nojoin_spaces + @public_nojoin_destroy_spaces).reverse }
      it_behaves_like 'リスト表示（個別）'
    end
    shared_examples_for '参加・未参加が0と0' do
      let(:params) { { public: 1, private: 1, join: 0, nojoin: 0, active: 1, destroy: 1 } }
      let(:spaces) { [] }
      it_behaves_like 'リスト表示（個別）'
    end
    shared_examples_for '有効・削除予定が1と0' do
      let(:params) { { public: 1, private: 1, join: 1, nojoin: 1, active: 1, destroy: 0 } }
      let(:spaces) { (@public_spaces + @public_nojoin_spaces + @private_spaces).reverse }
      it_behaves_like 'リスト表示（個別）'
    end
    shared_examples_for '有効・削除予定が0と1' do
      let(:params) { { public: 1, private: 1, join: 1, nojoin: 1, active: 0, destroy: 1 } }
      let(:spaces) { @public_nojoin_destroy_spaces.reverse }
      it_behaves_like 'リスト表示（個別）'
    end
    shared_examples_for '有効・削除予定が0と0' do
      let(:params) { { public: 1, private: 1, join: 1, nojoin: 1, active: 0, destroy: 0 } }
      let(:spaces) { [] }
      it_behaves_like 'リスト表示（個別）'
    end

    shared_examples_for 'リスト表示' do
      it_behaves_like '全て1'
      it_behaves_like '公開・非公開が1と0'
      it_behaves_like '公開・非公開が0と1'
      it_behaves_like '公開・非公開が0と0'
      it_behaves_like '参加・未参加が1と0'
      it_behaves_like '参加・未参加が0と1'
      it_behaves_like '参加・未参加が0と0'
      it_behaves_like '有効・削除予定が1と0'
      it_behaves_like '有効・削除予定が0と1'
      it_behaves_like '有効・削除予定が0と0'
    end

    context 'ログイン中（URLの拡張子がない/AcceptヘッダにHTMLが含まれる）' do
      include_context 'ログイン処理'
      include_context 'スペース一覧作成', 1, 1, 1, 1
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      it_behaves_like 'リスト表示'
    end
    context 'APIログイン中（URLの拡張子が.json/AcceptヘッダにJSONが含まれる）' do
      include_context 'APIログイン処理'
      include_context 'スペース一覧作成', 1, 1, 1, 1
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it_behaves_like 'リスト表示'
    end
  end
end
