require 'rails_helper'

RSpec.describe 'Top', type: :request do
  # GET /（ベースドメイン） トップページ
  # GET /（サブドメイン） スペーストップ
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   ベースドメイン, 存在するサブドメイン, 存在しないサブドメイン → 事前にデータ作成
  describe 'GET /index' do
    include_context 'リクエストスペース作成'

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

    # テストケース
    shared_examples_for '[*]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[*]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[*]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      it_behaves_like 'ToNG'
    end

    context '未ログイン' do
      it_behaves_like '[*]ベースドメイン'
      it_behaves_like '[*]存在するサブドメイン'
      it_behaves_like '[*]存在しないサブドメイン'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[*]ベースドメイン'
      it_behaves_like '[*]存在するサブドメイン'
      it_behaves_like '[*]存在しないサブドメイン'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[*]ベースドメイン'
      it_behaves_like '[*]存在するサブドメイン'
      it_behaves_like '[*]存在しないサブドメイン'
    end
  end

  # 新しいお知らせ
  # 前提条件
  #   ベースドメイン/存在するサブドメイン
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   お知らせ: ない, 最大表示数と同じ, 最大表示数より多い → データ作成
  #   ベースドメイン, 存在するサブドメイン → 事前にデータ作成
  # TODO: action_title
  describe '@new_infomations' do
    include_context 'リクエストスペース作成'

    # テスト内容
    shared_examples_for 'リスト表示' do
      let!(:end_no) { Settings['new_infomations_limit'] }
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

    shared_examples_for 'もっと見る表示' do
      it 'パスが含まれる' do
        get root_path, headers: headers
        expect(response.body).to include("\"#{domain}#{infomations_path}\"")
      end
    end
    shared_examples_for 'もっと見る非表示' do
      it 'パスが含まれない' do
        get root_path, headers: headers
        expect(response.body).not_to include("\"#{domain}#{infomations_path}\"")
      end
    end

    # テストケース
    shared_examples_for '[*][ない]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      let!(:domain) { '' }
      # it_behaves_like 'リスト表示' # Tips: 対象がない
      it_behaves_like 'もっと見る非表示'
    end
    shared_examples_for '[*][最大表示数と同じ]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      let!(:domain) { '' }
      it_behaves_like 'リスト表示'
      it_behaves_like 'もっと見る非表示'
    end
    shared_examples_for '[*][最大表示数より多い]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      let!(:domain) { '' }
      it_behaves_like 'リスト表示'
      it_behaves_like 'もっと見る表示'
    end
    shared_examples_for '[*][ない]存在するサブドメイン' do
      let!(:headers) { @space_header }
      let!(:domain) { "//#{Settings['base_domain']}" }
      # it_behaves_like 'リスト表示' # Tips: 対象がない
      it_behaves_like 'もっと見る非表示'
    end
    shared_examples_for '[*][最大表示数と同じ]存在するサブドメイン' do
      let!(:headers) { @space_header }
      let!(:domain) { "//#{Settings['base_domain']}" }
      it_behaves_like 'リスト表示'
      it_behaves_like 'もっと見る非表示'
    end
    shared_examples_for '[*][最大表示数より多い]存在するサブドメイン' do
      let!(:headers) { @space_header }
      let!(:domain) { "//#{Settings['base_domain']}" }
      it_behaves_like 'リスト表示'
      it_behaves_like 'もっと見る表示'
    end

    shared_examples_for '[*]お知らせがない' do
      it_behaves_like '[*][ない]ベースドメイン'
      it_behaves_like '[*][ない]存在するサブドメイン'
    end
    shared_examples_for '[未ログイン]お知らせが最大表示数と同じ' do
      count = Settings['test_infomations']
      include_context 'お知らせ一覧作成', count['all_forever_count'] + count['user_forever_count'], count['all_future_count'] + count['user_future_count'], 0, 0
      it_behaves_like '[*][最大表示数と同じ]ベースドメイン'
      it_behaves_like '[*][最大表示数と同じ]存在するサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み]お知らせが最大表示数と同じ' do
      count = Settings['test_infomations']
      include_context 'お知らせ一覧作成', count['all_forever_count'], count['all_future_count'], count['user_forever_count'], count['user_future_count']
      it_behaves_like '[*][最大表示数と同じ]ベースドメイン'
      it_behaves_like '[*][最大表示数と同じ]存在するサブドメイン'
    end
    shared_examples_for '[未ログイン]お知らせが最大表示数より多い' do
      count = Settings['test_infomations']
      include_context 'お知らせ一覧作成', count['all_forever_count'] + count['user_forever_count'], count['all_future_count'] + count['user_future_count'] + 1, 0, 0
      it_behaves_like '[*][最大表示数より多い]ベースドメイン'
      it_behaves_like '[*][最大表示数より多い]存在するサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み]お知らせが最大表示数より多い' do
      count = Settings['test_infomations']
      include_context 'お知らせ一覧作成', count['all_forever_count'], count['all_future_count'], count['user_forever_count'], count['user_future_count'] + 1
      it_behaves_like '[*][最大表示数より多い]ベースドメイン'
      it_behaves_like '[*][最大表示数より多い]存在するサブドメイン'
    end

    context '未ログイン' do
      it_behaves_like '[*]お知らせがない'
      it_behaves_like '[未ログイン]お知らせが最大表示数と同じ'
      it_behaves_like '[未ログイン]お知らせが最大表示数より多い'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[*]お知らせがない'
      it_behaves_like '[ログイン中/削除予約済み]お知らせが最大表示数と同じ'
      it_behaves_like '[ログイン中/削除予約済み]お知らせが最大表示数より多い'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[*]お知らせがない'
      it_behaves_like '[ログイン中/削除予約済み]お知らせが最大表示数と同じ'
      it_behaves_like '[ログイン中/削除予約済み]お知らせが最大表示数より多い'
    end
  end

  # 新しいスペース一覧
  # 前提条件
  #   ベースドメイン
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   スペース: ない, 最大表示数と同じ, 最大表示数より多い → データ作成
  describe 'GET / @new_spaces' do
    let!(:headers) { BASE_HEADER }

    # テスト内容
    shared_examples_for '対象のリスト表示' do
      it '名前が含まれる' do
        get root_path, headers: headers
        (1..[@create_spaces.count, Settings['new_spaces_limit']].min).each do |n|
          expect(response.body).to include(@create_spaces[@create_spaces.count - n].name)
        end
      end
      it 'パスが含まれる' do
        get root_path, headers: headers
        (1..[@create_spaces.count, Settings['new_spaces_limit']].min).each do |n|
          expect(response.body).to include("//#{@create_spaces[@create_spaces.count - n].subdomain}.#{Settings['base_domain']}")
        end
      end
    end
    shared_examples_for '対象外のリスト非表示' do
      it '名前が含まれない' do
        get root_path, headers: headers
        ((Settings['new_spaces_limit'] + 1)..@create_spaces.count).each do |n|
          expect(response.body).not_to include(@create_spaces[@create_spaces.count - n].name)
        end
      end
      it 'パスが含まれない' do
        get root_path, headers: headers
        ((Settings['new_spaces_limit'] + 1)..@create_spaces.count).each do |n|
          expect(response.body).not_to include("//#{@create_spaces[@create_spaces.count - n].subdomain}.#{Settings['base_domain']}")
        end
      end
    end

    shared_examples_for 'スペース一覧リンク表示' do
      it 'パスが含まれる' do
        get root_path, headers: headers
        expect(response.body).to include("\"#{spaces_path}\"")
      end
    end
    shared_examples_for 'スペース一覧リンク非表示' do
      it 'パスが含まれない' do
        get root_path, headers: headers
        expect(response.body).not_to include("\"#{spaces_path}\"")
      end
    end

    # テストケース
    shared_examples_for '[*]スペースがない' do
      include_context 'スペース作成', 0
      it_behaves_like 'スペース一覧リンク非表示'
    end
    shared_examples_for '[*]スペースが最大表示数と同じ' do
      include_context 'スペース作成', Settings['new_spaces_limit']
      it_behaves_like '対象のリスト表示'
      it_behaves_like 'スペース一覧リンク非表示'
    end
    shared_examples_for '[*]スペースが最大表示数より多い' do
      include_context 'スペース作成', Settings['new_spaces_limit'] + 1
      it_behaves_like '対象のリスト表示'
      it_behaves_like '対象外のリスト非表示'
      it_behaves_like 'スペース一覧リンク表示'
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
