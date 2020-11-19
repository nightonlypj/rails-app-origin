require 'rails_helper'

RSpec.describe 'Users::Passwords', type: :request do
  shared_context 'token作成' do |valid_flag|
    before do
      @token = Faker::Internet.password(min_length: 20, max_length: 20)
      user = FactoryBot.build(:user)
      user.reset_password_token = Devise.token_generator.digest(self, :reset_password_token, @token)
      user.reset_password_sent_at = valid_flag ? Time.now.utc : '0000-01-01'
      user.save!
    end
  end

  # GET /users/password/edit パスワード再設定
  describe 'GET /users/password/edit' do
    context '期限内のtoken' do
      include_context 'token作成', true
      it '成功ステータス' do
        get "#{edit_user_password_path}?reset_password_token=#{@token}"
        expect(response).to be_successful
      end
    end
    context '期限切れのtoken' do
      include_context 'token作成', false
      it 'パスワード再設定メール送信にリダイレクト' do
        get "#{edit_user_password_path}?reset_password_token=#{@token}"
        expect(response).to redirect_to(new_user_password_path)
      end
    end
    context '存在しないtoken' do
      it 'パスワード再設定メール送信にリダイレクト' do
        get "#{edit_user_password_path}?reset_password_token=not"
        expect(response).to redirect_to(new_user_password_path)
      end
    end
  end

  # PUT /users/password パスワード再設定(処理)
  describe 'PUT /users/password' do
    context '期限内のtoken' do
      include_context 'token作成', true
      it '成功ステータス' do
        put user_password_path, params: { user: { reset_password_token: @token } }
        expect(response).to be_successful
      end
    end
    context '期限切れのtoken' do
      include_context 'token作成', false
      it 'パスワード再設定メール送信にリダイレクト' do
        put user_password_path, params: { user: { reset_password_token: @token } }
        expect(response).to redirect_to(new_user_password_path)
      end
    end
    context '存在しないtoken' do
      it 'パスワード再設定メール送信にリダイレクト' do
        put user_password_path, params: { user: { reset_password_token: 'not' } }
        expect(response).to redirect_to(new_user_password_path)
      end
    end
  end
end
