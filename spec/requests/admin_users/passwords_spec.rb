require 'rails_helper'

RSpec.describe 'AdminUsers::Passwords', type: :request do
  shared_context '期限内のtoken作成' do
    before do
      @token = Faker::Internet.password
      admin_user = FactoryBot.build(:admin_user)
      admin_user.reset_password_token = Devise.token_generator.digest(self, :reset_password_token, @token)
      admin_user.reset_password_sent_at = Time.now
      admin_user.save!
    end
  end
  shared_context '期限切れのtoken作成' do
    before do
      @token = Faker::Internet.password
      admin_user = FactoryBot.build(:admin_user)
      admin_user.reset_password_token = Devise.token_generator.digest(self, :reset_password_token, @token)
      admin_user.reset_password_sent_at = '0000-01-01'
      admin_user.save!
    end
  end

  # GET /admin_users/password/edit パスワード再設定
  describe 'GET /admin_users/password/edit' do
    context '期限内のtoken' do
      include_context '期限内のtoken作成'
      it 'renders a successful response' do
        get "#{edit_admin_user_password_path}?reset_password_token=#{@token}"
        expect(response).to be_successful
      end
    end
    context '期限切れのtoken' do
      include_context '期限切れのtoken作成'
      it 'パスワード再設定メール送信にリダイレクト' do
        get "#{edit_admin_user_password_path}?reset_password_token=#{@token}"
        expect(response).to redirect_to(new_admin_user_password_path)
      end
    end
    context '存在しないtoken' do
      it 'パスワード再設定メール送信にリダイレクト' do
        get "#{edit_admin_user_password_path}?reset_password_token=not"
        expect(response).to redirect_to(new_admin_user_password_path)
      end
    end
  end

  # PUT /admin_users/password パスワード再設定(処理)
  describe 'PUT /admin_users/password' do
    context '期限内のtoken' do
      include_context '期限内のtoken作成'
      it 'renders a successful response' do
        put admin_user_password_path, params: { admin_user: { reset_password_token: @token } }
        expect(response).to be_successful
      end
    end
    context '期限切れのtoken' do
      include_context '期限切れのtoken作成'
      it 'パスワード再設定メール送信にリダイレクト' do
        put admin_user_password_path, params: { admin_user: { reset_password_token: @token } }
        expect(response).to redirect_to(new_admin_user_password_path)
      end
    end
    context '存在しないtoken' do
      it 'パスワード再設定メール送信にリダイレクト' do
        put admin_user_password_path, params: { admin_user: { reset_password_token: 'not' } }
        expect(response).to redirect_to(new_admin_user_password_path)
      end
    end
  end
end
