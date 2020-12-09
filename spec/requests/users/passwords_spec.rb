require 'rails_helper'

RSpec.describe 'Users::Passwords', type: :request do
  let!(:send_user) { FactoryBot.create(:user) }
  let!(:valid_attributes) { FactoryBot.attributes_for(:user, email: send_user.email) }
  let!(:invalid_attributes) { FactoryBot.attributes_for(:user, email: nil, password: nil) }
  shared_context 'token作成' do |valid_flag|
    let!(:token) { Faker::Internet.password(min_length: 20, max_length: 20) }
    before do
      @user = FactoryBot.build(:user, reset_password_token: Devise.token_generator.digest(self, :reset_password_token, token))
      @user.reset_password_sent_at = valid_flag ? Time.now.utc : '0000-01-01'
      @user.save!
    end
  end

  # GET /users/password/new パスワード再設定メール送信
  describe 'GET /new' do
    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get new_user_password_path
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToTop' do
      it 'トップページにリダイレクト' do
        get new_user_password_path
        expect(response).to redirect_to(root_path)
      end
    end

    # テストケース
    context '未ログイン' do
      it_behaves_like 'ToOK'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'ToTop'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like 'ToTop'
    end
  end

  # POST /users/password パスワード再設定メール送信(処理)
  describe 'POST /create' do
    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        post user_password_path, params: { user: attributes }
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToTop' do
      it 'トップページにリダイレクト' do
        post user_password_path, params: { user: attributes }
        expect(response).to redirect_to(root_path)
      end
    end
    shared_examples_for 'ToLogin' do
      it 'ログインにリダイレクト' do
        post user_password_path, params: { user: attributes }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '[未ログイン]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'ToOK' # Tips: 再入力の為
    end
    shared_examples_for '[ログイン中]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[ログイン中]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'ToTop'
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

  # GET /users/password/edit パスワード再設定
  describe 'GET /edit' do
    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get "#{edit_user_password_path}?reset_password_token=#{token}"
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToTop' do
      it 'トップページにリダイレクト' do
        get "#{edit_user_password_path}?reset_password_token=#{token}"
        expect(response).to redirect_to(root_path)
      end
    end
    shared_examples_for 'ToLogin' do
      it 'ログインにリダイレクト' do
        get "#{edit_user_password_path}?reset_password_token=#{token}"
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    shared_examples_for 'ToNew' do
      it 'パスワード再設定メール送信にリダイレクト' do
        get "#{edit_user_password_path}?reset_password_token=#{token}"
        expect(response).to redirect_to(new_user_password_path)
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]期限内のtoken' do
      include_context 'token作成', true
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[未ログイン]期限切れのtoken' do
      include_context 'token作成', false
      it_behaves_like 'ToNew'
    end
    shared_examples_for '[未ログイン]存在しないtoken' do
      let!(:token) { 'not' }
      it_behaves_like 'ToNew'
    end
    shared_examples_for '[未ログイン]tokenなし' do
      let!(:token) { '' }
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '[ログイン中]期限内のtoken' do
      include_context 'token作成', true
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[ログイン中]期限切れのtoken' do
      include_context 'token作成', false
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[ログイン中]存在しないtoken' do
      let!(:token) { 'not' }
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[ログイン中]tokenなし' do
      let!(:token) { '' }
      it_behaves_like 'ToTop'
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]期限内のtoken'
      it_behaves_like '[未ログイン]期限切れのtoken'
      it_behaves_like '[未ログイン]存在しないtoken'
      it_behaves_like '[未ログイン]tokenなし'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中]期限内のtoken'
      it_behaves_like '[ログイン中]期限切れのtoken'
      it_behaves_like '[ログイン中]存在しないtoken'
      it_behaves_like '[ログイン中]tokenなし'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[ログイン中]期限内のtoken'
      it_behaves_like '[ログイン中]期限切れのtoken'
      it_behaves_like '[ログイン中]存在しないtoken'
      it_behaves_like '[ログイン中]tokenなし'
    end
  end

  # PUT /users/password パスワード再設定(処理)
  describe 'PUT /update' do
    # テスト内容
    shared_examples_for 'OK' do
      it 'パスワードリセット送信日時が空に変更される' do
        put user_password_path, params: { user: attributes.merge({ reset_password_token: token }) }
        expect(User.find(send_user.id).reset_password_sent_at).to be_nil
      end
    end
    shared_examples_for 'NG' do
      it 'パスワードリセット送信日時が変更されない' do
        put user_password_path, params: { user: attributes.merge({ reset_password_token: token }) }
        expect(User.find(send_user.id).reset_password_sent_at).to eq(send_user.reset_password_sent_at)
      end
    end

    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        put user_password_path, params: { user: attributes.merge({ reset_password_token: token }) }
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToTop' do
      it 'トップページにリダイレクト' do
        put user_password_path, params: { user: attributes.merge({ reset_password_token: token }) }
        expect(response).to redirect_to(root_path)
      end
    end
    shared_examples_for 'ToNew' do
      it 'パスワード再設定メール送信にリダイレクト' do
        put user_password_path, params: { user: attributes.merge({ reset_password_token: token }) }
        expect(response).to redirect_to(new_user_password_path)
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]期限内のtoken、有効なパラメータ' do
      include_context 'token作成', true
      let!(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[未ログイン]期限内のtoken、無効なパラメータ' do
      include_context 'token作成', true
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToOK' # Tips: 再入力の為
    end
    shared_examples_for '[未ログイン]期限切れのtoken、有効なパラメータ' do
      include_context 'token作成', false
      let!(:attributes) { valid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNew'
    end
    shared_examples_for '[未ログイン]期限切れのtoken、無効なパラメータ' do
      include_context 'token作成', false
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNew'
    end
    shared_examples_for '[未ログイン]存在しないtoken、有効なパラメータ' do
      let!(:token) { 'not' }
      let!(:attributes) { valid_attributes }
      it_behaves_like 'ToNew'
    end
    shared_examples_for '[未ログイン]存在しないtoken、無効なパラメータ' do
      let!(:token) { 'not' }
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'ToNew'
    end
    shared_examples_for '[未ログイン]tokenなし、有効なパラメータ' do
      let!(:token) { '' }
      let!(:attributes) { valid_attributes }
      it_behaves_like 'ToNew'
    end
    shared_examples_for '[未ログイン]tokenなし、無効なパラメータ' do
      let!(:token) { '' }
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'ToNew'
    end
    shared_examples_for '[ログイン中]期限内のtoken、有効なパラメータ' do
      include_context 'token作成', true
      let!(:attributes) { valid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[ログイン中]期限内のtoken、無効なパラメータ' do
      include_context 'token作成', true
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[ログイン中]期限切れのtoken、有効なパラメータ' do
      include_context 'token作成', false
      let!(:attributes) { valid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[ログイン中]期限切れのtoken、無効なパラメータ' do
      include_context 'token作成', false
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[ログイン中]存在しないtoken、有効なパラメータ' do
      let!(:token) { 'not' }
      let!(:attributes) { valid_attributes }
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[ログイン中]存在しないtoken、無効なパラメータ' do
      let!(:token) { 'not' }
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[ログイン中]tokenなし、有効なパラメータ' do
      let!(:token) { '' }
      let!(:attributes) { valid_attributes }
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[ログイン中]tokenなし、無効なパラメータ' do
      let!(:token) { '' }
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'ToTop'
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]期限内のtoken、有効なパラメータ'
      it_behaves_like '[未ログイン]期限内のtoken、無効なパラメータ'
      it_behaves_like '[未ログイン]期限切れのtoken、有効なパラメータ'
      it_behaves_like '[未ログイン]期限切れのtoken、無効なパラメータ'
      it_behaves_like '[未ログイン]存在しないtoken、有効なパラメータ'
      it_behaves_like '[未ログイン]存在しないtoken、無効なパラメータ'
      it_behaves_like '[未ログイン]tokenなし、有効なパラメータ'
      it_behaves_like '[未ログイン]tokenなし、無効なパラメータ'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中]期限内のtoken、有効なパラメータ'
      it_behaves_like '[ログイン中]期限内のtoken、無効なパラメータ'
      it_behaves_like '[ログイン中]期限切れのtoken、有効なパラメータ'
      it_behaves_like '[ログイン中]期限切れのtoken、無効なパラメータ'
      it_behaves_like '[ログイン中]存在しないtoken、有効なパラメータ'
      it_behaves_like '[ログイン中]存在しないtoken、無効なパラメータ'
      it_behaves_like '[ログイン中]tokenなし、有効なパラメータ'
      it_behaves_like '[ログイン中]tokenなし、無効なパラメータ'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[ログイン中]期限内のtoken、有効なパラメータ'
      it_behaves_like '[ログイン中]期限内のtoken、無効なパラメータ'
      it_behaves_like '[ログイン中]期限切れのtoken、有効なパラメータ'
      it_behaves_like '[ログイン中]期限切れのtoken、無効なパラメータ'
      it_behaves_like '[ログイン中]存在しないtoken、有効なパラメータ'
      it_behaves_like '[ログイン中]存在しないtoken、無効なパラメータ'
      it_behaves_like '[ログイン中]tokenなし、有効なパラメータ'
      it_behaves_like '[ログイン中]tokenなし、無効なパラメータ'
    end
  end
end
