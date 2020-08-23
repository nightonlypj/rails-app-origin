require 'rails_helper'

RSpec.describe 'AdminUsers::Confirmations', type: :request do
  #   shared_context 'token作成' do |valid_flag, confirmed_blank_flag, confirmed_before_flag|
  #     before do
  #       @token = Faker::Internet.password(min_length: 20, max_length: 20)
  #       admin_user = FactoryBot.build(:admin_user)
  #       admin_user.confirmation_token = @token
  #       admin_user.confirmation_sent_at = valid_flag ? Time.now.utc : Time.now.utc - admin_user.class.confirm_within - 1.hour
  #       admin_user.confirmed_at = admin_user.confirmation_sent_at + (confirmed_before_flag ? -1.hour : 1.hour) unless confirmed_blank_flag
  #       admin_user.save!
  #     end
  #   end
  #
  #   # GET /admin_users/confirmation メールアドレス確認(処理)
  #   describe 'GET /admin_users/confirmation' do
  #     context '期限内のtokenで、メールアドレス未確認（確認日時がない）' do
  #       include_context 'token作成', true, true
  #       it 'renders a successful response' do
  #         get "#{admin_user_confirmation_path}?confirmation_token=#{@token}"
  #         expect(response).to be_successful
  #       end
  #     end
  #     context '期限内のtokenで、メールアドレス未確認（確認日時が確認送信日時より前）' do
  #       include_context 'token作成', true, false, true
  #       it 'renders a successful response' do
  #         get "#{admin_user_confirmation_path}?confirmation_token=#{@token}"
  #         expect(response).to be_successful
  #       end
  #     end
  #     context '期限内のtokenで、メールアドレス確認済み（確認日時が確認送信日時より後）' do
  #       include_context 'token作成', true, false, false
  #       it 'ログインにリダイレクト' do
  #         get "#{admin_user_confirmation_path}?confirmation_token=#{@token}"
  #         expect(response).to redirect_to(new_admin_user_session_path)
  #       end
  #     end
  #
  #     context '期限切れのtokenで、メールアドレス未確認（確認日時がない）' do
  #       include_context 'token作成', false, true
  #       it 'メールアドレス確認メール再送にリダイレクト' do
  #         get "#{admin_user_confirmation_path}?confirmation_token=#{@token}"
  #         expect(response).to redirect_to(new_admin_user_confirmation_path)
  #       end
  #     end
  #     context '期限切れのtokenで、メールアドレス未確認（確認日時が確認送信日時より前）' do
  #       include_context 'token作成', false, false, true
  #       it 'メールアドレス確認メール再送にリダイレクト' do
  #         get "#{admin_user_confirmation_path}?confirmation_token=#{@token}"
  #         expect(response).to redirect_to(new_admin_user_confirmation_path)
  #       end
  #     end
  #     context '期限切れのtokenで、メールアドレス確認済み（確認日時が確認送信日時より後）' do
  #       include_context 'token作成', false, false, false
  #       it 'ログインにリダイレクト' do
  #         get "#{admin_user_confirmation_path}?confirmation_token=#{@token}"
  #         expect(response).to redirect_to(new_admin_user_session_path)
  #       end
  #     end
  #
  #     context '存在しないtoken' do
  #       it 'メールアドレス確認メール再送にリダイレクト' do
  #         get "#{admin_user_confirmation_path}?confirmation_token=not"
  #         expect(response).to redirect_to(new_admin_user_confirmation_path)
  #       end
  #     end
  #   end
end
