require 'rails_helper'

RSpec.describe 'Users::Registrations', type: :request do
  let!(:base_headers) { { 'Host' => Settings['base_domain'] } }
  let!(:space_headers) { { 'Host' => "space.#{Settings['base_domain']}" } }
  let!(:valid_attributes) { FactoryBot.attributes_for(:user) }
  let!(:user) { FactoryBot.create(:user) }
  shared_context 'ログイン処理' do |destroy_reserved_flag|
    before do
      if destroy_reserved_flag
        user.destroy_requested_at = Time.now.utc
        user.destroy_schedule_at = Time.now.utc + Settings['destroy_schedule_days'].days
      end
      sign_in user
    end
  end

  # GET /users/sign_up アカウント登録
  describe 'GET /users/sign_up' do
    context 'ベースドメイン' do
      it 'renders a successful response' do
        get new_user_registration_path, headers: base_headers
        expect(response).to be_successful
      end
    end
    context 'サブドメイン' do
      it 'ベースドメインにリダイレクト' do
        get new_user_registration_path, headers: space_headers
        expect(response).to redirect_to("//#{Settings['base_domain']}#{new_user_registration_path}")
      end
    end
  end

  # POST /users アカウント登録(処理)
  describe 'POST /users' do
    context 'ベースドメイン、未ログイン、有効なパラメータ' do
      it 'ログインにリダイレクト' do
        post user_registration_path, params: { user: valid_attributes }, headers: base_headers
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'サブドメイン、未ログイン、有効なパラメータ' do
      it 'renders a not found response' do
        post user_registration_path, params: { user: valid_attributes }, headers: space_headers
        expect(response).to be_not_found
      end
    end
  end

  # GET /users/edit 登録情報変更
  describe 'GET /users/edit' do
    context 'ベースドメイン、ログイン中' do
      include_context 'ログイン処理', false
      it 'renders a successful response' do
        get edit_user_registration_path, headers: base_headers
        expect(response).to be_successful
      end
    end
    context 'ベースドメイン、ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it 'トップページにリダイレクト' do
        get edit_user_registration_path, headers: base_headers
        expect(response).to redirect_to(root_path)
      end
    end

    context 'サブドメイン、ログイン中' do
      include_context 'ログイン処理', false
      it 'ベースドメインにリダイレクト' do
        get edit_user_registration_path, headers: space_headers
        expect(response).to redirect_to("//#{Settings['base_domain']}#{edit_user_registration_path}")
      end
    end
  end

  # PUT /users 登録情報変更(処理)
  describe 'PUT /users' do
    context 'ベースドメイン、ログイン中' do
      include_context 'ログイン処理', false
      it 'renders a successful response' do
        put user_registration_path, params: { user: user }, headers: base_headers
        expect(response).to be_successful
      end
    end
    context 'ベースドメイン、ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it 'トップページにリダイレクト' do
        put user_registration_path, params: { user: user }, headers: base_headers
        expect(response).to redirect_to(root_path)
      end
    end

    context 'サブドメイン、ログイン中' do
      include_context 'ログイン処理', false
      it 'renders a not found response' do
        put user_registration_path, params: { user: user }, headers: space_headers
        expect(response).to be_not_found
      end
    end
  end

  # GET /users/delete アカウント削除
  describe 'GET /users/delete' do
    context 'ベースドメイン、未ログイン' do
      it 'ログインにリダイレクト' do
        get users_delete_path, headers: base_headers
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'ベースドメイン、ログイン中' do
      include_context 'ログイン処理', false
      it 'renders a successful response' do
        get users_delete_path, headers: base_headers
        expect(response).to be_successful
      end
    end

    context 'サブドメイン、ログイン中' do
      include_context 'ログイン処理', false
      it 'renders a not found response' do
        get users_delete_path, headers: space_headers
        expect(response).to be_not_found
      end
    end
  end

  # DELETE /users アカウント削除(処理)
  describe 'DELETE /users' do
    context 'ベースドメイン、ログイン中' do
      include_context 'ログイン処理', false
      it '削除依頼日時が現在日時と一致' do
        start_time = Time.current
        delete user_registration_path, headers: base_headers
        expect(User.last.destroy_requested_at).to be_between(start_time, Time.current)
      end
      it "削除予定日時が#{Settings['destroy_schedule_days']}日後と一致" do
        start_time = Time.current
        delete user_registration_path, headers: base_headers
        expect(User.last.destroy_schedule_at).to be_between(start_time + Settings['destroy_schedule_days'].days,
                                                            Time.current + Settings['destroy_schedule_days'].days)
      end
    end
    context 'ベースドメイン、ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it 'トップページにリダイレクト' do
        delete user_registration_path, headers: base_headers
        expect(response).to redirect_to(root_path)
      end
    end

    context 'サブドメイン、ログイン中' do
      include_context 'ログイン処理', false
      it 'renders a not found response' do
        delete user_registration_path, headers: space_headers
        expect(response).to be_not_found
      end
    end
  end

  # GET /users/undo_delete アカウント削除取り消し
  describe 'GET /users/undo_delete' do
    context 'ベースドメイン、未ログイン' do
      it 'ログインにリダイレクト' do
        get users_undo_delete_path, headers: base_headers
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'ベースドメイン、ログイン中' do
      include_context 'ログイン処理', false
      it 'トップページにリダイレクト' do
        get users_undo_delete_path, headers: base_headers
        expect(response).to redirect_to(root_path)
      end
    end
    context 'ベースドメイン、ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it 'renders a successful response' do
        get users_undo_delete_path, headers: base_headers
        expect(response).to be_successful
      end
    end

    context 'サブドメイン、ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it 'renders a not found response' do
        get users_undo_delete_path, headers: space_headers
        expect(response).to be_not_found
      end
    end
  end

  # PUT /users/undo_destroy アカウント削除取り消し(処理)
  describe 'PUT /users/undo_destroy' do
    context 'ベースドメイン、未ログイン' do
      it 'ログインにリダイレクト' do
        put users_undo_destroy_path, headers: base_headers
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'ベースドメイン、ログイン中' do
      include_context 'ログイン処理', false
      it 'トップページにリダイレクト' do
        put users_undo_destroy_path, headers: base_headers
        expect(response).to redirect_to(root_path)
      end
    end
    context 'ベースドメイン、ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it '削除依頼日時がない' do
        put users_undo_destroy_path, headers: base_headers
        expect(User.last.destroy_requested_at).to be_nil
      end
      it '削除予定日時がない' do
        put users_undo_destroy_path, headers: base_headers
        expect(User.last.destroy_schedule_at).to be_nil
      end
    end

    context 'サブドメイン、ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it 'renders a not found response' do
        put users_undo_destroy_path, headers: space_headers
        expect(response).to be_not_found
      end
    end
  end
end
