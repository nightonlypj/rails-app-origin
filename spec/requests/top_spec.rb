require 'rails_helper'

RSpec.describe 'Top', type: :request do
  # GET /（ベースドメイン） トップページ
  # GET /（サブドメイン） スペーストップ
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   権限: ある(Owner, Admin, Member), ない → データ作成
  #   ベースドメイン, 存在するサブドメイン(公開スペース, 非公開スペース), 存在しないサブドメイン → 事前にデータ作成
  describe 'GET /index' do
    include_context 'リクエストスペース作成'
    include_context 'リクエストスペース作成（公開）'

    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get root_path, headers: headers
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToNG' do
      it '存在しないステータス' do
        get root_path, headers: headers
        expect(response).to be_not_found
      end
    end
    shared_examples_for 'ToLogin' do |alert, notice|
      it 'ログインにリダイレクト' do
        get root_path, headers: headers
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[*][*]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[*][*]存在するサブドメイン(公開スペース)' do
      let!(:headers) { @public_space_header }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[ログイン中/削除予約済み][ある]存在するサブドメイン(非公開スペース)' do
      let!(:headers) { @space_header }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[未ログイン][ない]存在するサブドメイン(非公開スペース)' do
      let!(:headers) { @space_header }
      it_behaves_like 'ToLogin', 'devise.failure.unauthenticated', nil
    end
    shared_examples_for '[ログイン中/削除予約済み][ない]存在するサブドメイン(非公開スペース)' do
      let!(:headers) { @space_header }
      it_behaves_like 'ToNG'
    end
    shared_examples_for '[*][*]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      it_behaves_like 'ToNG'
    end

    shared_examples_for '[ログイン中/削除予約済み]権限がある' do |power|
      include_context '顧客・ユーザー紐付け', Time.current, power
      include_context '顧客・ユーザー紐付け（公開）', Time.current, power
      it_behaves_like '[*][*]ベースドメイン'
      it_behaves_like '[*][*]存在するサブドメイン(公開スペース)'
      it_behaves_like '[ログイン中/削除予約済み][ある]存在するサブドメイン(非公開スペース)'
      it_behaves_like '[*][*]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン]権限がない' do
      it_behaves_like '[*][*]ベースドメイン'
      it_behaves_like '[*][*]存在するサブドメイン(公開スペース)'
      it_behaves_like '[未ログイン][ない]存在するサブドメイン(非公開スペース)'
      it_behaves_like '[*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み]権限がない' do
      it_behaves_like '[*][*]ベースドメイン'
      it_behaves_like '[*][*]存在するサブドメイン(公開スペース)'
      it_behaves_like '[ログイン中/削除予約済み][ない]存在するサブドメイン(非公開スペース)'
      it_behaves_like '[*][*]存在しないサブドメイン'
    end

    context '未ログイン' do
      # it_behaves_like '[未ログイン]権限がある', :Owner # Tips: 未ログインの為、権限がない
      # it_behaves_like '[未ログイン]権限がある', :Admin # Tips: 未ログインの為、権限がない
      # it_behaves_like '[未ログイン]権限がある', :Member # Tips: 未ログインの為、権限がない
      it_behaves_like '[未ログイン]権限がない'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中/削除予約済み]権限がある', :Owner
      it_behaves_like '[ログイン中/削除予約済み]権限がある', :Admin
      it_behaves_like '[ログイン中/削除予約済み]権限がある', :Member
      it_behaves_like '[ログイン中/削除予約済み]権限がない'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[ログイン中/削除予約済み]権限がある', :Owner
      it_behaves_like '[ログイン中/削除予約済み]権限がある', :Admin
      it_behaves_like '[ログイン中/削除予約済み]権限がある', :Member
      it_behaves_like '[ログイン中/削除予約済み]権限がない'
    end
  end

  # 管理メニュー
  # 前提条件
  #   ログイン中/削除予約済み, 存在するサブドメイン
  # テストパターン
  #   ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   権限: ある(Owner, Admin), ない(Member含む) → データ作成
  #   存在するサブドメイン(公開スペース, 非公開スペース) → 事前にデータ作成
  describe 'manage_space' do
    let!(:domain) { "//#{Settings['base_domain']}" }
    include_context 'リクエストスペース作成'
    include_context 'リクエストスペース作成（公開）'

    # テスト内容
    shared_examples_for '管理メニュー表示' do
      it '顧客詳細のパスが含まれる' do
        get root_path, headers: headers
        expect(response.body).to include("\"#{domain}#{customer_path(customer_code: target_customer.code)}\"")
      end
      it '顧客コードが含まれる' do # Tips: 顧客詳細のパスに含まれる為、正確ではない
        get root_path, headers: headers
        expect(response.body).to include(target_customer.code)
      end
      it '組織・団体名が含まれる' do
        get root_path, headers: headers
        expect(response.body).to include(target_customer.name)
      end
      it 'メンバー招待のパスが含まれる' do
        get root_path, headers: headers
        expect(response.body).to include("\"#{domain}#{new_member_path(customer_code: target_customer.code)}\"")
      end
      it 'メンバー一覧のパスが含まれる' do
        get root_path, headers: headers
        expect(response.body).to include("\"#{domain}#{members_path(customer_code: target_customer.code)}\"")
      end
      it 'スペース情報変更のパスが含まれる' do
        get root_path, headers: headers
        expect(response.body).to include("\"#{edit_space_path}\"")
      end
    end
    shared_examples_for '管理メニュー非表示' do
      it '顧客詳細のパスが含まれない' do
        get root_path, headers: headers
        expect(response.body).not_to include("\"#{domain}#{customer_path(customer_code: target_customer.code)}\"")
      end
      it '顧客コードが含まれない' do
        get root_path, headers: headers
        expect(response.body).not_to include(target_customer.code)
      end
      it '組織・団体名が含まれない' do
        get root_path, headers: headers
        expect(response.body).not_to include(target_customer.name)
      end
      it 'メンバー招待のパスが含まれない' do
        get root_path, headers: headers
        expect(response.body).not_to include("\"#{domain}#{new_member_path(customer_code: target_customer.code)}\"")
      end
      it 'メンバー一覧のパスが含まれない' do
        get root_path, headers: headers
        expect(response.body).not_to include("\"#{domain}#{members_path(customer_code: target_customer.code)}\"")
      end
      it 'スペース情報変更のパスが含まれない' do
        get root_path, headers: headers
        expect(response.body).not_to include("\"#{edit_space_path}\"")
      end
    end

    # テストケース
    shared_examples_for '[ログイン中/削除予約済み][ある]存在するサブドメイン(公開スペース)' do
      let!(:headers) { @public_space_header }
      let!(:target_customer) { public_customer }
      it_behaves_like '管理メニュー表示'
    end
    shared_examples_for '[ログイン中/削除予約済み][ない]存在するサブドメイン(公開スペース)' do
      let!(:headers) { @public_space_header }
      let!(:target_customer) { public_customer }
      it_behaves_like '管理メニュー非表示'
    end
    shared_examples_for '[ログイン中/削除予約済み][ある]存在するサブドメイン(非公開スペース)' do
      let!(:headers) { @space_header }
      let!(:target_customer) { customer }
      it_behaves_like '管理メニュー表示'
    end
    shared_examples_for '[ログイン中/削除予約済み][ない]存在するサブドメイン(非公開スペース)' do
      let!(:headers) { @space_header }
      let!(:target_customer) { customer }
      it_behaves_like '管理メニュー非表示'
    end

    shared_examples_for '[ログイン中/削除予約済み]権限がある' do |power|
      include_context '顧客・ユーザー紐付け', Time.current, power
      include_context '顧客・ユーザー紐付け（公開）', Time.current, power
      it_behaves_like '[ログイン中/削除予約済み][ある]存在するサブドメイン(公開スペース)'
      it_behaves_like '[ログイン中/削除予約済み][ある]存在するサブドメイン(非公開スペース)'
    end
    shared_examples_for '[ログイン中/削除予約済み]権限がMember' do
      include_context '顧客・ユーザー紐付け', Time.current, :Member
      include_context '顧客・ユーザー紐付け（公開）', Time.current, :Member
      it_behaves_like '[ログイン中/削除予約済み][ない]存在するサブドメイン(公開スペース)'
      it_behaves_like '[ログイン中/削除予約済み][ない]存在するサブドメイン(非公開スペース)'
    end
    shared_examples_for '[ログイン中/削除予約済み]権限がない' do
      it_behaves_like '[ログイン中/削除予約済み][ない]存在するサブドメイン(公開スペース)'
      it_behaves_like '[ログイン中/削除予約済み][ない]存在するサブドメイン(非公開スペース)'
    end

    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中/削除予約済み]権限がある', :Owner
      it_behaves_like '[ログイン中/削除予約済み]権限がある', :Admin
      it_behaves_like '[ログイン中/削除予約済み]権限がMember'
      it_behaves_like '[ログイン中/削除予約済み]権限がない'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[ログイン中/削除予約済み]権限がある', :Owner
      it_behaves_like '[ログイン中/削除予約済み]権限がある', :Admin
      it_behaves_like '[ログイン中/削除予約済み]権限がMember'
      it_behaves_like '[ログイン中/削除予約済み]権限がない'
    end
  end

  # お知らせ
  # 前提条件
  #   ベースドメイン/存在するサブドメイン
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   お知らせ: ない, 最大表示数と同じ, 最大表示数より多い → データ作成
  #   ベースドメイン, 存在するサブドメイン(公開スペース, 非公開スペース) → 事前にデータ作成
  # TODO: action_title
  describe '@infomations' do
    include_context 'リクエストスペース作成'
    include_context 'リクエストスペース作成（公開）'

    # テスト内容
    shared_examples_for 'リスト表示' do
      let!(:end_no) { Settings['infomations_limit'] }
      it 'タイトルが含まれる' do
        get root_path, headers: headers
        (1..end_no).each do |no|
          expect(response.body).to include(@infomations[@infomations.count - no].title)
        end
      end
      it '概要が含まれる（ありの場合）' do
        get root_path, headers: headers
        (1..end_no).each do |no|
          expect(response.body).to include(@infomations[@infomations.count - no].summary) if @infomations[@infomations.count - no].summary.present?
        end
      end
      it 'お知らせ詳細のパスが含まれる（本文ありの場合）' do
        get root_path, headers: headers
        (1..end_no).each do |no|
          if @infomations[@infomations.count - no].body.present?
            expect(response.body).to include("\"#{domain}#{infomation_path(@infomations[@infomations.count - no])}\"")
          end
        end
      end
      it 'お知らせ詳細のパスが含まれない（本文なしの場合）' do
        get root_path, headers: headers
        (1..end_no).each do |no|
          unless @infomations[@infomations.count - no].body.present?
            expect(response.body).not_to include("\"#{domain}#{infomation_path(@infomations[@infomations.count - no])}\"")
          end
        end
      end
      it '掲載開始日が含まれる' do # Tips: ユニークではない為、正確ではない
        get root_path, headers: headers
        (1..end_no).each do |no|
          expect(response.body).to include(I18n.l(@infomations[@infomations.count - no].started_at.to_date))
        end
      end
    end

    shared_examples_for 'リンク表示' do
      it 'お知らせ一覧のパスが含まれる' do
        get root_path, headers: headers
        expect(response.body).to include("\"#{domain}#{infomations_path}\"")
      end
    end
    shared_examples_for 'リンク非表示' do
      it 'お知らせ一覧のパスが含まれない' do
        get root_path, headers: headers
        expect(response.body).not_to include("\"#{domain}#{infomations_path}\"")
      end
    end

    # テストケース
    shared_examples_for '[*][ない]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      let!(:domain) { '' }
      # it_behaves_like 'リスト表示' # Tips: 対象がない
      it_behaves_like 'リンク非表示'
    end
    shared_examples_for '[*][最大表示数と同じ]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      let!(:domain) { '' }
      it_behaves_like 'リスト表示'
      it_behaves_like 'リンク表示'
    end
    shared_examples_for '[*][最大表示数より多い]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      let!(:domain) { '' }
      it_behaves_like 'リスト表示'
      it_behaves_like 'リンク表示'
    end
    shared_examples_for '[*][ない]存在するサブドメイン(公開スペース)' do
      let!(:headers) { @public_space_header }
      let!(:domain) { "//#{Settings['base_domain']}" }
      # it_behaves_like 'リスト表示' # Tips: 対象がない
      it_behaves_like 'リンク非表示'
    end
    shared_examples_for '[*][ない]存在するサブドメイン(非公開スペース)' do
      let!(:headers) { @space_header }
      let!(:domain) { "//#{Settings['base_domain']}" }
      # it_behaves_like 'リスト表示' # Tips: 対象がない
      it_behaves_like 'リンク非表示'
    end
    shared_examples_for '[*][最大表示数と同じ]存在するサブドメイン(公開スペース)' do
      let!(:headers) { @public_space_header }
      let!(:domain) { "//#{Settings['base_domain']}" }
      it_behaves_like 'リスト表示'
      it_behaves_like 'リンク表示'
    end
    shared_examples_for '[*][最大表示数と同じ]存在するサブドメイン(非公開スペース)' do
      let!(:headers) { @space_header }
      let!(:domain) { "//#{Settings['base_domain']}" }
      it_behaves_like 'リスト表示'
      it_behaves_like 'リンク表示'
    end
    shared_examples_for '[*][最大表示数より多い]存在するサブドメイン(公開スペース)' do
      let!(:headers) { @public_space_header }
      let!(:domain) { "//#{Settings['base_domain']}" }
      it_behaves_like 'リスト表示'
      it_behaves_like 'リンク表示'
    end
    shared_examples_for '[*][最大表示数より多い]存在するサブドメイン(非公開スペース)' do
      let!(:headers) { @space_header }
      let!(:domain) { "//#{Settings['base_domain']}" }
      it_behaves_like 'リスト表示'
      it_behaves_like 'リンク表示'
    end

    shared_examples_for '[*]お知らせがない' do
      it_behaves_like '[*][ない]ベースドメイン'
      it_behaves_like '[*][ない]存在するサブドメイン(公開スペース)'
      it_behaves_like '[*][ない]存在するサブドメイン(非公開スペース)'
    end
    shared_examples_for '[未ログイン]お知らせが最大表示数と同じ' do
      count = Settings['test_infomations']
      include_context 'お知らせ一覧作成', count['all_forever_count'] + count['user_forever_count'], count['all_future_count'] + count['user_future_count'], 0, 0
      it_behaves_like '[*][最大表示数と同じ]ベースドメイン'
      it_behaves_like '[*][最大表示数と同じ]存在するサブドメイン(公開スペース)'
      # it_behaves_like '[*][最大表示数と同じ]存在するサブドメイン(非公開スペース)' # Tips: 未ログインの為、権限がない
    end
    shared_examples_for '[ログイン中/削除予約済み]お知らせが最大表示数と同じ' do
      count = Settings['test_infomations']
      include_context 'お知らせ一覧作成', count['all_forever_count'], count['all_future_count'], count['user_forever_count'], count['user_future_count']
      it_behaves_like '[*][最大表示数と同じ]ベースドメイン'
      it_behaves_like '[*][最大表示数と同じ]存在するサブドメイン(公開スペース)'
      it_behaves_like '[*][最大表示数と同じ]存在するサブドメイン(非公開スペース)'
    end
    shared_examples_for '[未ログイン]お知らせが最大表示数より多い' do
      count = Settings['test_infomations']
      include_context 'お知らせ一覧作成', count['all_forever_count'] + count['user_forever_count'], count['all_future_count'] + count['user_future_count'] + 1, 0, 0
      it_behaves_like '[*][最大表示数より多い]ベースドメイン'
      it_behaves_like '[*][最大表示数より多い]存在するサブドメイン(公開スペース)'
      # it_behaves_like '[*][最大表示数より多い]存在するサブドメイン(非公開スペース)' # Tips: 未ログインの為、権限がない
    end
    shared_examples_for '[ログイン中/削除予約済み]お知らせが最大表示数より多い' do
      count = Settings['test_infomations']
      include_context 'お知らせ一覧作成', count['all_forever_count'], count['all_future_count'], count['user_forever_count'], count['user_future_count'] + 1
      it_behaves_like '[*][最大表示数より多い]ベースドメイン'
      it_behaves_like '[*][最大表示数より多い]存在するサブドメイン(公開スペース)'
      it_behaves_like '[*][最大表示数より多い]存在するサブドメイン(非公開スペース)'
    end

    context '未ログイン' do
      it_behaves_like '[*]お知らせがない'
      it_behaves_like '[未ログイン]お知らせが最大表示数と同じ'
      it_behaves_like '[未ログイン]お知らせが最大表示数より多い'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      include_context '顧客・ユーザー紐付け', Time.current, :Member
      include_context '顧客・ユーザー紐付け（公開）', Time.current, :Member
      it_behaves_like '[*]お知らせがない'
      it_behaves_like '[ログイン中/削除予約済み]お知らせが最大表示数と同じ'
      it_behaves_like '[ログイン中/削除予約済み]お知らせが最大表示数より多い'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      include_context '顧客・ユーザー紐付け', Time.current, :Member
      include_context '顧客・ユーザー紐付け（公開）', Time.current, :Member
      it_behaves_like '[*]お知らせがない'
      it_behaves_like '[ログイン中/削除予約済み]お知らせが最大表示数と同じ'
      it_behaves_like '[ログイン中/削除予約済み]お知らせが最大表示数より多い'
    end
  end

  # 参加スペース
  # 前提条件
  #   ベースドメイン
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   参加スペース: ない, 最大表示数と同じ, 最大表示数より多い → データ作成
  describe 'GET / @join_spaces' do
    let!(:headers) { BASE_HEADER }
    include_context 'スペース作成', 1 # Tips: 未所属
    include_context 'スペース作成', 1, true # Tips: 公開スペース

    # テスト内容
    shared_examples_for '対象のリスト表示' do
      it 'スペース名が含まれる' do
        get root_path, headers: headers
        (1..[@create_spaces.count, Settings['join_spaces_limit']].min).each do |no|
          expect(response.body).to include(@create_spaces[no - 1].name)
        end
      end
      it 'パスが含まれる' do
        get root_path, headers: headers
        (1..[@create_spaces.count, Settings['join_spaces_limit']].min).each do |no|
          expect(response.body).to include("//#{@create_spaces[no - 1].subdomain}.#{Settings['base_domain']}")
        end
      end
    end
    shared_examples_for '対象外のリスト非表示' do
      it 'スペース名が含まれない' do
        get root_path, headers: headers
        ((Settings['join_spaces_limit'] + 1)..@create_spaces.count).each do |no|
          expect(response.body).not_to include(@create_spaces[no - 1].name)
        end
      end
      it 'パスが含まれない' do
        get root_path, headers: headers
        ((Settings['join_spaces_limit'] + 1)..@create_spaces.count).each do |no|
          expect(response.body).not_to include("//#{@create_spaces[no - 1].subdomain}.#{Settings['base_domain']}")
        end
      end
    end

    shared_examples_for '一覧リンク表示' do
      it '参加スペース一覧のパスが含まれる' do
        get root_path, headers: headers
        expect(response.body).to include("\"#{spaces_path}\"")
      end
    end
    shared_examples_for '一覧リンク非表示' do
      it '参加スペース一覧のパスが含まれない' do
        get root_path, headers: headers
        expect(response.body).not_to include("\"#{spaces_path}\"")
      end
    end

    shared_examples_for '作成リンク表示' do
      it 'スペース作成のパスが含まれる' do
        get root_path, headers: headers
        expect(response.body).to include("\"#{new_space_path}\"")
      end
    end
    shared_examples_for '作成リンク非表示' do
      it 'スペース作成のパスが含まれない' do
        get root_path, headers: headers
        expect(response.body).not_to include("\"#{new_space_path}\"")
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]スペースがない' do
      it_behaves_like '一覧リンク非表示'
      it_behaves_like '作成リンク非表示'
    end
    shared_examples_for '[ログイン中/削除予約済み]スペースがない' do
      it_behaves_like '一覧リンク表示'
      it_behaves_like '作成リンク表示'
    end
    shared_examples_for '[ログイン中/削除予約済み]スペースが最大表示数と同じ' do
      include_context 'スペース作成（3顧客）', Settings['test_spaces_owner'], Settings['test_spaces_admin'], Settings['test_spaces_member']
      include_context '顧客・ユーザー紐付け（3顧客・権限）'
      it_behaves_like '対象のリスト表示'
      it_behaves_like '一覧リンク表示'
      it_behaves_like '作成リンク非表示'
    end
    shared_examples_for '[ログイン中/削除予約済み]スペースが最大表示数より多い' do
      include_context 'スペース作成（3顧客）', Settings['test_spaces_owner'], Settings['test_spaces_admin'], Settings['test_spaces_member'] + 1
      include_context '顧客・ユーザー紐付け（3顧客・権限）'
      it_behaves_like '対象のリスト表示'
      it_behaves_like '対象外のリスト非表示'
      it_behaves_like '一覧リンク表示'
      it_behaves_like '作成リンク非表示'
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]スペースがない'
      # it_behaves_like '[未ログイン]スペースが最大表示数と同じ' # Tips: 参加スペースがない
      # it_behaves_like '[未ログイン]スペースが最大表示数より多い' # Tips: 参加スペースがない
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中/削除予約済み]スペースがない'
      it_behaves_like '[ログイン中/削除予約済み]スペースが最大表示数と同じ'
      it_behaves_like '[ログイン中/削除予約済み]スペースが最大表示数より多い'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[ログイン中/削除予約済み]スペースがない'
      it_behaves_like '[ログイン中/削除予約済み]スペースが最大表示数と同じ'
      it_behaves_like '[ログイン中/削除予約済み]スペースが最大表示数より多い'
    end
  end

  # 公開スペース
  # 前提条件
  #   ベースドメイン
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   公開スペース: ない, 最大表示数と同じ, 最大表示数より多い → データ作成
  describe 'GET / @public_spaces' do
    let!(:headers) { BASE_HEADER }
    include_context 'スペース作成', 1 # Tips: 非公開スペース

    # テスト内容
    shared_examples_for '対象のリスト表示' do
      it 'スペース名が含まれる' do
        get root_path, headers: headers
        (1..[@create_spaces.count, Settings['public_spaces_limit']].min).each do |no|
          expect(response.body).to include(@create_spaces[@create_spaces.count - no].name)
        end
      end
      it 'パスが含まれる' do
        get root_path, headers: headers
        (1..[@create_spaces.count, Settings['public_spaces_limit']].min).each do |no|
          expect(response.body).to include("//#{@create_spaces[@create_spaces.count - no].subdomain}.#{Settings['base_domain']}")
        end
      end
    end
    shared_examples_for '対象外のリスト非表示' do
      it 'スペース名が含まれない' do
        get root_path, headers: headers
        ((Settings['public_spaces_limit'] + 1)..@create_spaces.count).each do |no|
          expect(response.body).not_to include(@create_spaces[@create_spaces.count - no].name)
        end
      end
      it 'パスが含まれない' do
        get root_path, headers: headers
        ((Settings['public_spaces_limit'] + 1)..@create_spaces.count).each do |no|
          expect(response.body).not_to include("//#{@create_spaces[@create_spaces.count - no].subdomain}.#{Settings['base_domain']}")
        end
      end
    end

    shared_examples_for 'リンク表示' do
      it '公開スペース一覧のパスが含まれる' do
        get root_path, headers: headers
        expect(response.body).to include("\"#{public_spaces_path}\"")
      end
    end
    shared_examples_for 'リンク非表示' do
      it '公開スペース一覧のパスが含まれない' do
        get root_path, headers: headers
        expect(response.body).not_to include("\"#{public_spaces_path}\"")
      end
    end

    # テストケース
    shared_examples_for '[*]スペースがない' do
      it_behaves_like 'リンク非表示'
    end
    shared_examples_for '[*]スペースが最大表示数と同じ' do
      include_context 'スペース作成', Settings['public_spaces_limit'], true
      it_behaves_like '対象のリスト表示'
      it_behaves_like 'リンク表示'
    end
    shared_examples_for '[*]スペースが最大表示数より多い' do
      include_context 'スペース作成', Settings['public_spaces_limit'] + 1, true
      it_behaves_like '対象のリスト表示'
      it_behaves_like '対象外のリスト非表示'
      it_behaves_like 'リンク表示'
    end

    context '未ログイン' do
      it_behaves_like '[*]スペースがない'
      it_behaves_like '[*]スペースが最大表示数と同じ'
      it_behaves_like '[*]スペースが最大表示数より多い'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[*]スペースがない'
      it_behaves_like '[*]スペースが最大表示数と同じ'
      it_behaves_like '[*]スペースが最大表示数より多い'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[*]スペースがない'
      it_behaves_like '[*]スペースが最大表示数と同じ'
      it_behaves_like '[*]スペースが最大表示数より多い'
    end
  end
end
