require 'rails_helper'

RSpec.describe 'Users::Unlocks', type: :request do
  include_context 'リクエストスペース作成'

  # GET /users/unlock/new アカウントロック解除メール再送
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   ベースドメイン, 存在するサブドメイン, 存在しないサブドメイン → 事前にデータ作成
  describe 'GET /new' do
    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get new_user_unlock_path, headers: headers
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToTop' do
      it 'トップページにリダイレクト' do
        get new_user_unlock_path, headers: headers
        expect(response).to redirect_to(root_path)
      end
    end
    shared_examples_for 'ToBase' do
      it 'ベースドメインにリダイレクト' do
        get new_user_unlock_path, headers: headers
        expect(response).to redirect_to("//#{Settings['base_domain']}#{new_user_unlock_path}")
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[ログイン中]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[未ログイン]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'ToBase'
    end
    shared_examples_for '[ログイン中]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[未ログイン]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      it_behaves_like 'ToBase'
    end
    shared_examples_for '[ログイン中]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      it_behaves_like 'ToTop'
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]ベースドメイン'
      it_behaves_like '[未ログイン]存在するサブドメイン'
      it_behaves_like '[未ログイン]存在しないサブドメイン'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中]ベースドメイン'
      it_behaves_like '[ログイン中]存在するサブドメイン'
      it_behaves_like '[ログイン中]存在しないサブドメイン'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[ログイン中]ベースドメイン'
      it_behaves_like '[ログイン中]存在するサブドメイン'
      it_behaves_like '[ログイン中]存在しないサブドメイン'
    end
  end

  # POST /users/unlock アカウントロック解除メール再送(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   有効なパラメータ, 無効なパラメータ → 事前にデータ作成
  #   ベースドメイン, 存在するサブドメイン, 存在しないサブドメイン → 事前にデータ作成
  describe 'POST /create' do
    include_context 'アカウントロック解除トークン作成'
    let!(:valid_attributes) { FactoryBot.attributes_for(:user, email: @send_user.email) }
    let!(:invalid_attributes) { FactoryBot.attributes_for(:user, email: nil) }

    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        post user_unlock_path, params: { user: attributes }, headers: headers
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToNG' do
      it '存在しないステータス' do
        post user_unlock_path, params: { user: attributes }, headers: headers
        expect(response).to be_not_found
      end
    end
    shared_examples_for 'ToTop' do
      it 'トップページにリダイレクト' do
        post user_unlock_path, params: { user: attributes }, headers: headers
        expect(response).to redirect_to(root_path)
      end
    end
    shared_examples_for 'ToLogin' do
      it 'ログインにリダイレクト' do
        post user_unlock_path, params: { user: attributes }, headers: headers
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    # テストケース
    shared_examples_for '[未ログイン][有効なパラメータ]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToLogin' # Tips: OK
    end
    shared_examples_for '[ログイン中][有効なパラメータ]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[未ログイン][無効なパラメータ]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToOK' # Tips: 再入力
    end
    shared_examples_for '[ログイン中][無効なパラメータ]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[未ログイン]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'ToNG'
    end
    shared_examples_for '[ログイン中]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[未ログイン]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      it_behaves_like 'ToNG'
    end
    shared_examples_for '[ログイン中]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      it_behaves_like 'ToTop'
    end

    shared_examples_for '[未ログイン]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like '[未ログイン][有効なパラメータ]ベースドメイン'
      it_behaves_like '[未ログイン]存在するサブドメイン'
      it_behaves_like '[未ログイン]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like '[ログイン中][有効なパラメータ]ベースドメイン'
      it_behaves_like '[ログイン中]存在するサブドメイン'
      it_behaves_like '[ログイン中]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like '[未ログイン][無効なパラメータ]ベースドメイン'
      it_behaves_like '[未ログイン]存在するサブドメイン'
      it_behaves_like '[未ログイン]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like '[ログイン中][無効なパラメータ]ベースドメイン'
      it_behaves_like '[ログイン中]存在するサブドメイン'
      it_behaves_like '[ログイン中]存在しないサブドメイン'
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]有効なパラメータ'
      it_behaves_like '[未ログイン]無効なパラメータ'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中]有効なパラメータ'
      it_behaves_like '[ログイン中]無効なパラメータ'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[ログイン中]有効なパラメータ'
      it_behaves_like '[ログイン中]無効なパラメータ'
    end
  end

  # GET /users/unlock アカウントロック解除(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   存在するtoken, 存在しないtoken, tokenなし → データ作成
  #   未ロック（ロック日時がない）, ロック中（ロック日時がある） → データ作成
  #   ベースドメイン, 存在するサブドメイン, 存在しないサブドメイン → 事前にデータ作成
  describe 'GET /show' do
    # テスト内容
    shared_examples_for 'OK' do
      it 'アカウントロック日時が空に変更される' do
        get user_unlock_path(unlock_token: unlock_token), headers: headers
        expect(User.find(@send_user.id).locked_at).to be_nil
      end
    end
    shared_examples_for 'NG' do
      it 'アカウントロック日時が変更されない' do
        get user_unlock_path(unlock_token: unlock_token), headers: headers
        expect(User.find(@send_user.id).locked_at).to eq(@send_user.locked_at)
      end
    end

    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get user_unlock_path(unlock_token: unlock_token), headers: headers
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToNG' do
      it '存在しないステータス' do
        get user_unlock_path(unlock_token: unlock_token), headers: headers
        expect(response).to be_not_found
      end
    end
    shared_examples_for 'ToTop' do
      it 'トップページにリダイレクト' do
        get user_unlock_path(unlock_token: unlock_token), headers: headers
        expect(response).to redirect_to(root_path)
      end
    end
    shared_examples_for 'ToLogin' do
      it 'ログインにリダイレクト' do
        get user_unlock_path(unlock_token: unlock_token), headers: headers
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    shared_examples_for 'ToBase' do
      it 'ベースドメインにリダイレクト' do
        get user_unlock_path(unlock_token: unlock_token), headers: headers
        expect(response).to redirect_to("//#{Settings['base_domain']}#{user_unlock_path(unlock_token: unlock_token)}")
      end
    end

    # テストケース
    shared_examples_for '[未ログイン][存在するtoken][未ロック]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      # it_behaves_like 'NG' # Tips: 元々、ロック日時が空
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '[ログイン中][存在するtoken][未ロック]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      # it_behaves_like 'NG' # Tips: 元々、ロック日時が空
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[未ログイン][存在しないtoken][未ロック]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      # it_behaves_like 'NG' # Tips: tokenが存在しない為、ロック日時がない
      it_behaves_like 'ToOK' # Tips: 再入力
    end
    shared_examples_for '[ログイン中][存在しないtoken][未ロック]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      # it_behaves_like 'NG' # Tips: tokenが存在しない為、ロック日時がない
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[未ログイン][存在するtoken][ロック中]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'OK'
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '[ログイン中][存在するtoken][ロック中]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[未ログイン][存在するtoken]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'NG'
      it_behaves_like 'ToBase'
    end
    shared_examples_for '[ログイン中][存在するtoken]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[未ログイン][存在しないtoken]存在するサブドメイン' do
      let!(:headers) { @space_header }
      # it_behaves_like 'NG' # Tips: tokenが存在しない為、ロック日時がない
      it_behaves_like 'ToBase'
    end
    shared_examples_for '[ログイン中][存在しないtoken]存在するサブドメイン' do
      let!(:headers) { @space_header }
      # it_behaves_like 'NG' # Tips: tokenが存在しない為、ロック日時がない
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[未ログイン][存在するtoken]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToBase'
    end
    shared_examples_for '[ログイン中][存在するtoken]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[未ログイン][存在しないtoken]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      # it_behaves_like 'NG' # Tips: tokenが存在しない為、ロック日時がない
      it_behaves_like 'ToBase'
    end
    shared_examples_for '[ログイン中][存在しないtoken]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      # it_behaves_like 'NG' # Tips: tokenが存在しない為、ロック日時がない
      it_behaves_like 'ToTop'
    end

    shared_examples_for '[未ログイン][存在するtoken]未ロック（ロック日時がない）' do
      include_context 'アカウントロック解除トークン解除'
      it_behaves_like '[未ログイン][存在するtoken][未ロック]ベースドメイン'
      it_behaves_like '[未ログイン][存在するtoken]存在するサブドメイン'
      it_behaves_like '[未ログイン][存在するtoken]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中][存在するtoken]未ロック（ロック日時がない）' do
      include_context 'アカウントロック解除トークン解除'
      it_behaves_like '[ログイン中][存在するtoken][未ロック]ベースドメイン'
      it_behaves_like '[ログイン中][存在するtoken]存在するサブドメイン'
      it_behaves_like '[ログイン中][存在するtoken]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][存在しないtoken]未ロック（ロック日時がない）' do
      it_behaves_like '[未ログイン][存在しないtoken][未ロック]ベースドメイン'
      it_behaves_like '[未ログイン][存在しないtoken]存在するサブドメイン'
      it_behaves_like '[未ログイン][存在しないtoken]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中][存在しないtoken]未ロック（ロック日時がない）' do
      it_behaves_like '[ログイン中][存在しないtoken][未ロック]ベースドメイン'
      it_behaves_like '[ログイン中][存在しないtoken]存在するサブドメイン'
      it_behaves_like '[ログイン中][存在しないtoken]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][存在するtoken]ロック中（ロック日時がある）' do
      it_behaves_like '[未ログイン][存在するtoken][ロック中]ベースドメイン'
      it_behaves_like '[未ログイン][存在するtoken]存在するサブドメイン'
      it_behaves_like '[未ログイン][存在するtoken]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中][存在するtoken]ロック中（ロック日時がある）' do
      it_behaves_like '[ログイン中][存在するtoken][ロック中]ベースドメイン'
      it_behaves_like '[ログイン中][存在するtoken]存在するサブドメイン'
      it_behaves_like '[ログイン中][存在するtoken]存在しないサブドメイン'
    end

    shared_examples_for '[未ログイン]存在するtoken' do
      include_context 'アカウントロック解除トークン作成'
      it_behaves_like '[未ログイン][存在するtoken]未ロック（ロック日時がない）'
      it_behaves_like '[未ログイン][存在するtoken]ロック中（ロック日時がある）'
    end
    shared_examples_for '[ログイン中]存在するtoken' do
      include_context 'アカウントロック解除トークン作成'
      it_behaves_like '[ログイン中][存在するtoken]未ロック（ロック日時がない）'
      it_behaves_like '[ログイン中][存在するtoken]ロック中（ロック日時がある）'
    end
    shared_examples_for '[未ログイン]存在しないtoken' do
      let!(:unlock_token) { NOT_TOKEN }
      it_behaves_like '[未ログイン][存在しないtoken]未ロック（ロック日時がない）'
      # it_behaves_like '[未ログイン][存在しないtoken]ロック中（ロック日時がある）' # Tips: tokenが存在しない為、ロック日時がない
    end
    shared_examples_for '[ログイン中]存在しないtoken' do
      let!(:unlock_token) { NOT_TOKEN }
      it_behaves_like '[ログイン中][存在しないtoken]未ロック（ロック日時がない）'
      # it_behaves_like '[ログイン中][存在しないtoken]ロック中（ロック日時がある）' # Tips: tokenが存在しない為、ロック日時がない
    end
    shared_examples_for '[未ログイン]tokenなし' do
      let!(:unlock_token) { NO_TOKEN }
      it_behaves_like '[未ログイン][存在しないtoken]未ロック（ロック日時がない）'
      # it_behaves_like '[未ログイン][存在しないtoken]ロック中（ロック日時がある）' # Tips: tokenが存在しない為、ロック日時がない
    end
    shared_examples_for '[ログイン中]tokenなし' do
      let!(:unlock_token) { NO_TOKEN }
      it_behaves_like '[ログイン中][存在しないtoken]未ロック（ロック日時がない）'
      # it_behaves_like '[ログイン中][存在しないtoken]ロック中（ロック日時がある）' # Tips: tokenが存在しない為、ロック日時がない
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]存在するtoken'
      it_behaves_like '[未ログイン]存在しないtoken'
      it_behaves_like '[未ログイン]tokenなし'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中]存在するtoken'
      it_behaves_like '[ログイン中]存在しないtoken'
      it_behaves_like '[ログイン中]tokenなし'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[ログイン中]存在するtoken'
      it_behaves_like '[ログイン中]存在しないtoken'
      it_behaves_like '[ログイン中]tokenなし'
    end
  end
end
