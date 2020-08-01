require 'rails_helper'

RSpec.describe 'Users::Registrations', type: :request do
  let!(:valid_attributes) { FactoryBot.attributes_for(:user) }
  let!(:user) { FactoryBot.create(:user) }
  shared_context 'ログイン処理' do |delete_reserved_flag|
    before do
      user.delete_schedule_at = Time.now + Settings['delete_schedule_days'].days if delete_reserved_flag
      sign_in user
    end
  end

  # POST /users アカウント登録(処理)
  describe 'POST /users' do
    context '有効なパラメータ' do
      it 'ログインにリダイレクト' do
        post user_registration_path, params: { user: valid_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # GET /users/delete アカウント削除
  describe 'GET /users/delete' do
    context '未ログイン' do
      it 'ログインにリダイレクト' do
        get users_delete_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'ログイン中' do
      include_context 'ログイン処理', false
      it 'renders a successful response' do
        get users_delete_path
        expect(response).to be_successful
      end
    end
  end

  # DELETE /users アカウント削除(処理)
  describe 'DELETE /users' do
    context 'ログイン中、削除予定日時がない' do
      include_context 'ログイン処理', false
      it '削除予約日時が現在日時と一致' do
        start_time = Time.current
        delete user_registration_path
        expect(User.last.delete_reserved_at).to be_between(start_time, Time.current)
      end
      it "削除予定日時が#{Settings['delete_schedule_days']}日後と一致" do
        start_time = Time.current
        delete user_registration_path
        expect(User.last.delete_schedule_at).to be_between(start_time + Settings['delete_schedule_days'].days, Time.current + Settings['delete_schedule_days'].days)
      end
    end
    context 'ログイン中、削除予定日時がある' do
      # TODO
    end
  end
end
