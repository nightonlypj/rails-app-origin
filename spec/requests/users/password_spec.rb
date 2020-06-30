require 'rails_helper'

RSpec.describe 'Users::Password', type: :request do
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

  # GET /users/password/edit パスワード再設定
  describe 'GET /users/password/edit' do
    context '期限内のtoken' do
      include_context '期限内のtoken作成'
      it 'renders a successful response' do
        get "/users/password/edit?reset_password_token=#{@token}"
        expect(response).to be_successful
      end
    end
    context '期限切れのtoken' do
      include_context '期限切れのtoken作成'
      it 'パスワード再設定メール送信にリダイレクト' do
        get "/users/password/edit?reset_password_token=#{@token}"
        expect(response).to redirect_to(new_user_password_path)
      end
    end
    context '存在しないtoken' do
      it 'パスワード再設定メール送信にリダイレクト' do
        get '/users/password/edit?reset_password_token=not'
        expect(response).to redirect_to(new_user_password_path)
      end
    end
  end

  # PUT /users/password パスワード再設定(処理)
  describe 'PUT /users/password' do
    context '期限内のtoken' do
      include_context '期限内のtoken作成'
      it 'renders a successful response' do
        put '/users/password', params: { user: { reset_password_token: @token } }
        expect(response).to be_successful
      end
    end
    context '期限切れのtoken' do
      include_context '期限切れのtoken作成'
      it 'パスワード再設定メール送信にリダイレクト' do
        put '/users/password', params: { user: { reset_password_token: @token } }
        expect(response).to redirect_to(new_user_password_path)
      end
    end
    context '存在しないtoken' do
      it 'パスワード再設定メール送信にリダイレクト' do
        put '/users/password', params: { user: { reset_password_token: 'not' } }
        expect(response).to redirect_to(new_user_password_path)
      end
    end
  end
end
