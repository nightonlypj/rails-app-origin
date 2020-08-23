require 'rails_helper'

RSpec.describe 'Users::Confirmations', type: :request do
  let!(:base_headers) { { 'Host' => Settings['base_domain'] } }
  let!(:space_headers) { { 'Host' => "space.#{Settings['base_domain']}" } }
  shared_context 'token作成' do |valid_flag, confirmed_blank_flag, confirmed_before_flag|
    before do
      @token = Faker::Internet.password(min_length: 20, max_length: 20)
      user = FactoryBot.build(:user)
      user.confirmation_token = @token
      user.confirmation_sent_at = valid_flag ? Time.now.utc : Time.now.utc - user.class.confirm_within - 1.hour
      user.confirmed_at = user.confirmation_sent_at + (confirmed_before_flag ? -1.hour : 1.hour) unless confirmed_blank_flag
      user.save!
    end
  end

  # GET /users/confirmation/new メールアドレス確認メール再送
  describe 'GET /users/confirmation/new' do
    context 'ベースドメイン' do
      it 'renders a successful response' do
        get new_user_confirmation_path, headers: base_headers
        expect(response).to be_successful
      end
    end
    context 'サブドメイン' do
      it 'ベースドメインにリダイレクト' do
        get new_user_confirmation_path, headers: space_headers
        expect(response).to redirect_to("//#{Settings['base_domain']}#{new_user_confirmation_path}")
      end
    end
  end

  # POST /users/confirmation メールアドレス確認メール再送(処理)
  describe 'POST /users/confirmation' do
    context 'ベースドメイン' do
      it 'renders a successful response' do
        post user_confirmation_path, headers: base_headers
        expect(response).to be_successful
      end
    end
    context 'サブドメイン' do
      it 'renders a not found response' do
        post user_confirmation_path, headers: space_headers
        expect(response).to be_not_found
      end
    end
  end

  # GET /users/confirmation メールアドレス確認(処理)
  describe 'GET /users/confirmation' do
    context 'ベースドメイン、期限内のtokenで、メールアドレス未確認（確認日時がない）' do
      include_context 'token作成', true, true
      it 'renders a successful response' do
        get "#{user_confirmation_path}?confirmation_token=#{@token}", headers: base_headers
        expect(response).to be_successful
      end
    end
    context 'ベースドメイン、期限内のtokenで、メールアドレス未確認（確認日時が確認送信日時より前）' do
      include_context 'token作成', true, false, true
      it 'renders a successful response' do
        get "#{user_confirmation_path}?confirmation_token=#{@token}", headers: base_headers
        expect(response).to be_successful
      end
    end
    context 'ベースドメイン、期限内のtokenで、メールアドレス確認済み（確認日時が確認送信日時より後）' do
      include_context 'token作成', true, false, false
      it 'ログインにリダイレクト' do
        get "#{user_confirmation_path}?confirmation_token=#{@token}", headers: base_headers
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'ベースドメイン、期限切れのtokenで、メールアドレス未確認（確認日時がない）' do
      include_context 'token作成', false, true
      it 'メールアドレス確認メール再送にリダイレクト' do
        get "#{user_confirmation_path}?confirmation_token=#{@token}", headers: base_headers
        expect(response).to redirect_to(new_user_confirmation_path)
      end
    end
    context 'ベースドメイン、期限切れのtokenで、メールアドレス未確認（確認日時が確認送信日時より前）' do
      include_context 'token作成', false, false, true
      it 'メールアドレス確認メール再送にリダイレクト' do
        get "#{user_confirmation_path}?confirmation_token=#{@token}", headers: base_headers
        expect(response).to redirect_to(new_user_confirmation_path)
      end
    end
    context 'ベースドメイン、期限切れのtokenで、メールアドレス確認済み（確認日時が確認送信日時より後）' do
      include_context 'token作成', false, false, false
      it 'ログインにリダイレクト' do
        get "#{user_confirmation_path}?confirmation_token=#{@token}", headers: base_headers
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'ベースドメイン、存在しないtoken' do
      it 'メールアドレス確認メール再送にリダイレクト' do
        get "#{user_confirmation_path}?confirmation_token=not", headers: base_headers
        expect(response).to redirect_to(new_user_confirmation_path)
      end
    end

    context 'サブドメイン、期限内のtokenで、メールアドレス未確認（確認日時がない）' do
      include_context 'token作成', true, true
      it 'ベースドメインにリダイレクト' do
        get user_confirmation_path, headers: space_headers
        expect(response).to redirect_to("//#{Settings['base_domain']}#{user_confirmation_path}")
      end
    end
  end
end
