require 'rails_helper'

RSpec.describe 'Users::Unlocks', type: :request do
  include_context '共通ヘッダー'
  include_context 'リクエストスペース作成'
  let!(:token) { Faker::Internet.password(min_length: 20, max_length: 20) }
  let!(:send_user) { FactoryBot.create(:user, locked_at: Time.now.utc, unlock_token: Devise.token_generator.digest(self, :unlock_token, token)) }
  let!(:valid_attributes) { FactoryBot.attributes_for(:user, email: send_user.email) }
  let!(:invalid_attributes) { FactoryBot.attributes_for(:user, email: nil) }

  # GET /users/unlock/new アカウントロック解除メール再送
  describe 'GET /users/unlock/new' do
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
      let!(:headers) { base_headers }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[ログイン中]ベースドメイン' do
      let!(:headers) { base_headers }
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[未ログイン]存在するサブドメイン' do
      let!(:headers) { @space_headers }
      it_behaves_like 'ToBase'
    end
    shared_examples_for '[ログイン中]存在するサブドメイン' do
      let!(:headers) { @space_headers }
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[未ログイン]存在しないサブドメイン' do
      let!(:headers) { not_space_headers }
      it_behaves_like 'ToBase'
    end
    shared_examples_for '[ログイン中]存在しないサブドメイン' do
      let!(:headers) { not_space_headers }
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
  describe 'POST /users/unlock' do
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
    shared_examples_for '[未ログイン][ベースドメイン]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '[未ログイン][サブドメイン]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like 'ToNG'
    end
    shared_examples_for '[未ログイン][ベースドメイン]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'ToOK' # Tips: 再入力の為
    end
    shared_examples_for '[未ログイン][サブドメイン]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'ToNG'
    end
    shared_examples_for '[ログイン中]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[ログイン中]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'ToTop'
    end

    shared_examples_for '[未ログイン]ベースドメイン' do
      let!(:headers) { base_headers }
      it_behaves_like '[未ログイン][ベースドメイン]有効なパラメータ'
      it_behaves_like '[未ログイン][ベースドメイン]無効なパラメータ'
    end
    shared_examples_for '[ログイン中]ベースドメイン' do
      let!(:headers) { base_headers }
      it_behaves_like '[ログイン中]有効なパラメータ'
      it_behaves_like '[ログイン中]無効なパラメータ'
    end
    shared_examples_for '[未ログイン]存在するサブドメイン' do
      let!(:headers) { @space_headers }
      it_behaves_like '[未ログイン][サブドメイン]有効なパラメータ'
      it_behaves_like '[未ログイン][サブドメイン]無効なパラメータ'
    end
    shared_examples_for '[ログイン中]存在するサブドメイン' do
      let!(:headers) { @space_headers }
      it_behaves_like '[ログイン中]有効なパラメータ'
      it_behaves_like '[ログイン中]無効なパラメータ'
    end
    shared_examples_for '[未ログイン]存在しないサブドメイン' do
      let!(:headers) { not_space_headers }
      it_behaves_like '[未ログイン][サブドメイン]有効なパラメータ'
      it_behaves_like '[未ログイン][サブドメイン]無効なパラメータ'
    end
    shared_examples_for '[ログイン中]存在しないサブドメイン' do
      let!(:headers) { not_space_headers }
      it_behaves_like '[ログイン中]有効なパラメータ'
      it_behaves_like '[ログイン中]無効なパラメータ'
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

  # GET /users/unlock アカウントロック解除(処理)
  describe 'GET /users/unlock' do
    # テスト内容
    shared_examples_for 'OK' do
      it 'アカウントロック日時が空に変更される' do
        get "#{user_unlock_path}?unlock_token=#{token}", headers: headers
        expect(User.find(send_user.id).locked_at).to be_nil
      end
    end
    shared_examples_for 'NG' do
      it 'アカウントロック日時が変更されない' do
        get "#{user_unlock_path}?unlock_token=#{token}", headers: headers
        expect(User.find(send_user.id).locked_at).to eq(send_user.locked_at)
      end
    end

    shared_examples_for 'ToTop' do
      it 'トップページにリダイレクト' do
        get "#{user_unlock_path}?unlock_token=#{token}", headers: headers
        expect(response).to redirect_to(root_path)
      end
    end
    shared_examples_for 'ToLogin' do
      it 'ログインにリダイレクト' do
        get "#{user_unlock_path}?unlock_token=#{token}", headers: headers
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    shared_examples_for 'ToBase' do
      it 'ベースドメインにリダイレクト' do
        get "#{user_unlock_path}?unlock_token=#{token}", headers: headers
        expect(response).to redirect_to("//#{Settings['base_domain']}#{user_unlock_path}?unlock_token=#{token}")
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]ベースドメイン' do
      let!(:headers) { base_headers }
      it_behaves_like 'OK'
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '[ログイン中]ベースドメイン' do
      let!(:headers) { base_headers }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[未ログイン]存在するサブドメイン' do
      let!(:headers) { @space_headers }
      it_behaves_like 'NG'
      it_behaves_like 'ToBase'
    end
    shared_examples_for '[ログイン中]存在するサブドメイン' do
      let!(:headers) { @space_headers }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[未ログイン]存在しないサブドメイン' do
      let!(:headers) { not_space_headers }
      it_behaves_like 'NG'
      it_behaves_like 'ToBase'
    end
    shared_examples_for '[ログイン中]存在しないサブドメイン' do
      let!(:headers) { not_space_headers }
      it_behaves_like 'NG'
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
end
