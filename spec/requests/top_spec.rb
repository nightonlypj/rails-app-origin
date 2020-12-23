require 'rails_helper'

# TODO: private未対応
RSpec.describe 'Top', type: :request do
  include_context '共通ヘッダー'

  # GET /（ベースドメイン） トップページ
  # GET /（サブドメイン） スペーストップ
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
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
    shared_examples_for 'ベースドメイン' do
      let!(:headers) { base_headers }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '存在するサブドメイン' do
      let!(:headers) { @space_headers }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '存在しないサブドメイン' do
      let!(:headers) { not_space_headers }
      it_behaves_like 'ToNG'
    end

    context '未ログイン' do
      it_behaves_like 'ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like 'ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
  end

  # GET /（ベースドメイン） トップページ：新しいスペース一覧
  describe 'GET / @new_spaces' do
    # テスト内容
    shared_examples_for '対象のリスト表示' do
      it '名前が含まれる' do
        get root_path, headers: base_headers
        (1..[@create_spaces.count, Settings['new_spaces_limit']].min).each do |n|
          expect(response.body).to include(@create_spaces[@create_spaces.count - n].name)
        end
      end
      it 'パスが含まれる' do
        get root_path, headers: base_headers
        (1..[@create_spaces.count, Settings['new_spaces_limit']].min).each do |n|
          expect(response.body).to include("//#{@create_spaces[@create_spaces.count - n].subdomain}.#{Settings['base_domain']}")
        end
      end
    end
    shared_examples_for '対象外のリスト非表示' do
      it '名前が含まれない' do
        get root_path, headers: base_headers
        ((Settings['new_spaces_limit'] + 1)..@create_spaces.count).each do |n|
          expect(response.body).not_to include(@create_spaces[@create_spaces.count - n].name)
        end
      end
      it 'パスが含まれない' do
        get root_path, headers: base_headers
        ((Settings['new_spaces_limit'] + 1)..@create_spaces.count).each do |n|
          expect(response.body).not_to include("//#{@create_spaces[@create_spaces.count - n].subdomain}.#{Settings['base_domain']}")
        end
      end
    end

    shared_examples_for 'スペース一覧リンク表示' do
      it 'パスが含まれる' do
        get root_path, headers: base_headers
        expect(response.body).to include("\"#{spaces_path}\"")
      end
    end
    shared_examples_for 'スペース一覧リンク非表示' do
      it 'パスが含まれない' do
        get root_path, headers: base_headers
        expect(response.body).not_to include("\"#{spaces_path}\"")
      end
    end

    shared_examples_for 'スペース作成リンク表示' do
      it 'パスが含まれる' do
        get root_path, headers: base_headers
        expect(response.body).to include("\"#{new_space_path}\"")
      end
    end

    # テストケース
    shared_examples_for 'スペースが0件' do
      include_context 'スペース作成', 0
      it_behaves_like 'スペース一覧リンク非表示'
      it_behaves_like 'スペース作成リンク表示'
    end
    shared_examples_for 'スペースが最大表示数と同じ' do
      include_context 'スペース作成', Settings['new_spaces_limit']
      it_behaves_like '対象のリスト表示'
      it_behaves_like 'スペース一覧リンク表示'
      it_behaves_like 'スペース作成リンク表示'
    end
    shared_examples_for 'スペースが最大表示数より多い' do
      include_context 'スペース作成', Settings['new_spaces_limit'] + 1
      it_behaves_like '対象のリスト表示'
      it_behaves_like '対象外のリスト非表示'
      it_behaves_like 'スペース一覧リンク表示'
      it_behaves_like 'スペース作成リンク表示'
    end

    context '未ログイン' do
      it_behaves_like 'スペースが0件'
      it_behaves_like 'スペースが最大表示数と同じ'
      it_behaves_like 'スペースが最大表示数より多い'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'スペースが0件'
      it_behaves_like 'スペースが最大表示数と同じ'
      it_behaves_like 'スペースが最大表示数より多い'
    end
  end
end
