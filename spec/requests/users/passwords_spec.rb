require 'rails_helper'

RSpec.describe 'Users::Passwords', type: :request do
  let!(:base_headers) { { 'Host' => Settings['base_domain'] } }
  let!(:space_headers) { { 'Host' => "space.#{Settings['base_domain']}" } }

  shared_context '期限内のtoken作成' do
    before do
      @token = Faker::Internet.password
      user = FactoryBot.build(:user)
      user.reset_password_token = Devise.token_generator.digest(self, :reset_password_token, @token)
      user.reset_password_sent_at = Time.now
      user.save!
    end
  end
  shared_context '期限切れのtoken作成' do
    before do
      @token = Faker::Internet.password
      user = FactoryBot.build(:user)
      user.reset_password_token = Devise.token_generator.digest(self, :reset_password_token, @token)
      user.reset_password_sent_at = '0000-01-01'
      user.save!
    end
  end

  # GET /users/password/new パスワード再設定メール送信
  describe 'GET /users/password/new' do
    context 'ベースドメイン' do
      it 'renders a successful response' do
        get new_user_password_path, headers: base_headers
        expect(response).to be_successful
      end
    end
    context 'サブドメイン' do
      it 'ベースドメインにリダイレクト' do
        get new_user_password_path, headers: space_headers
        expect(response).to redirect_to("//#{Settings['base_domain']}#{new_user_password_path}")
      end
    end
  end

  # POST /users/password パスワード再設定メール送信(処理)
  describe 'POST /users/password' do
    context 'ベースドメイン' do
      it 'renders a successful response' do
        post user_password_path, headers: base_headers
        expect(response).to be_successful
      end
    end
    context 'サブドメイン' do
      it 'renders a not found response' do
        post user_password_path, headers: space_headers
        expect(response).to be_not_found
      end
    end
  end

  # GET /users/password/edit パスワード再設定
  describe 'GET /users/password/edit' do
    context 'ベースドメイン、期限内のtoken' do
      include_context '期限内のtoken作成'
      it 'renders a successful response' do
        get "#{edit_user_password_path}?reset_password_token=#{@token}", headers: base_headers
        expect(response).to be_successful
      end
    end
    context 'サブドメイン、期限内のtoken' do
      include_context '期限内のtoken作成'
      it 'ベースドメインにリダイレクト' do
        fullpath = "#{edit_user_password_path}?reset_password_token=#{@token}"
        get fullpath, headers: space_headers
        expect(response).to redirect_to("//#{Settings['base_domain']}#{fullpath}")
      end
    end
    context 'ベースドメイン、期限切れのtoken' do
      include_context '期限切れのtoken作成'
      it 'パスワード再設定メール送信にリダイレクト' do
        get "#{edit_user_password_path}?reset_password_token=#{@token}", headers: base_headers
        expect(response).to redirect_to(new_user_password_path)
      end
    end
    context 'ベースドメイン、存在しないtoken' do
      it 'パスワード再設定メール送信にリダイレクト' do
        get "#{edit_user_password_path}?reset_password_token=not", headers: base_headers
        expect(response).to redirect_to(new_user_password_path)
      end
    end
  end

  # PUT /users/password パスワード再設定(処理)
  describe 'PUT /users/password' do
    context 'ベースドメイン、期限内のtoken' do
      include_context '期限内のtoken作成'
      it 'renders a successful response' do
        put user_password_path, params: { user: { reset_password_token: @token } }, headers: base_headers
        expect(response).to be_successful
      end
    end
    context 'サブドメイン、期限内のtoken' do
      include_context '期限内のtoken作成'
      it 'renders a not found response' do
        put user_password_path, params: { user: { reset_password_token: @token } }, headers: space_headers
        expect(response).to be_not_found
      end
    end
    context 'ベースドメイン、期限切れのtoken' do
      include_context '期限切れのtoken作成'
      it 'パスワード再設定メール送信にリダイレクト' do
        put user_password_path, params: { user: { reset_password_token: @token } }, headers: base_headers
        expect(response).to redirect_to(new_user_password_path)
      end
    end
    context 'ベースドメイン、存在しないtoken' do
      it 'パスワード再設定メール送信にリダイレクト' do
        put user_password_path, params: { user: { reset_password_token: 'not' } }, headers: base_headers
        expect(response).to redirect_to(new_user_password_path)
      end
    end
  end
end
