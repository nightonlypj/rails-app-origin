require 'rails_helper'

RSpec.describe 'Users::Registrations', type: :request do
  let!(:valid_attributes) { FactoryBot.attributes_for(:user) }
  let!(:invalid_attributes) { FactoryBot.attributes_for(:user, email: nil) }

  # GET /users/sign_up アカウント登録
  describe 'GET /users/sign_up' do
    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get new_user_registration_path
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToTop' do
      it 'トップページにリダイレクト' do
        get new_user_registration_path
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

  # POST /users アカウント登録(処理)
  describe 'POST /users' do
    # テスト内容
    shared_examples_for 'OK' do
      it '作成される' do
        expect do
          post user_registration_path, params: { user: attributes }
        end.to change(User, :count).by(1)
      end
    end
    shared_examples_for 'NG' do
      it '作成されない' do
        expect do
          post user_registration_path, params: { user: attributes }
        end.to change(User, :count).by(0)
      end
    end

    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        post user_registration_path, params: { user: attributes }
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToTop' do
      it 'トップページにリダイレクト' do
        post user_registration_path, params: { user: attributes }
        expect(response).to redirect_to(root_path)
      end
    end
    shared_examples_for 'ToLogin' do
      it 'ログインにリダイレクト' do
        post user_registration_path, params: { user: attributes }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '[未ログイン]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToOK' # Tips: 再入力の為
    end
    shared_examples_for '[ログイン中]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[ログイン中]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
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

  # GET /users/edit 登録情報変更
  describe 'GET /users/edit' do
    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get edit_user_registration_path
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToTop' do
      it 'トップページにリダイレクト' do
        get edit_user_registration_path
        expect(response).to redirect_to(root_path)
      end
    end
    shared_examples_for 'ToLogin' do
      it 'ログインにリダイレクト' do
        get edit_user_registration_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    # テストケース
    context '未ログイン' do
      it_behaves_like 'ToLogin'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'ToOK'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like 'ToTop'
    end
  end

  # PUT /users 登録情報変更(処理)
  describe 'PUT /users' do
    # テスト内容
    shared_examples_for 'OK' do
      it 'メールアドレスが変更される' do
        after_user = user
        after_user.email = "a#{user.email}"
        put user_registration_path, params: { user: after_user }
        expect(user.email).to eq(after_user.email)
      end
    end
    shared_examples_for 'NG' do
      let!(:before_user) { user }
      it 'メールアドレスが変更されない' do
        after_user = user
        after_user.email = "a#{user.email}"
        put user_registration_path, params: { user: after_user }
        expect(user.email).to eq(before_user.email)
      end
    end

    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        after_user = user
        after_user.email = "a#{user.email}"
        put user_registration_path, params: { user: after_user }
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToTop' do
      it 'トップページにリダイレクト' do
        after_user = user
        after_user.email = "a#{user.email}"
        put user_registration_path, params: { user: after_user }
        expect(response).to redirect_to(root_path)
      end
    end
    shared_examples_for 'ToLogin' do
      it 'ログインにリダイレクト' do
        put user_registration_path, params: { user: nil }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    # テストケース
    context '未ログイン' do
      it_behaves_like 'ToLogin'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'OK'
      it_behaves_like 'ToOK'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like 'NG'
      it_behaves_like 'ToTop'
    end
  end

  # GET /users/delete アカウント削除
  describe 'GET /users/delete' do
    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get users_delete_path
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToTop' do
      it 'トップページにリダイレクト' do
        get users_delete_path
        expect(response).to redirect_to(root_path)
      end
    end
    shared_examples_for 'ToLogin' do
      it 'ログインにリダイレクト' do
        get users_delete_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    # テストケース
    context '未ログイン' do
      it_behaves_like 'ToLogin'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'ToOK'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like 'ToTop'
    end
  end

  # DELETE /users アカウント削除(処理)
  describe 'DELETE /users' do
    # テスト内容
    shared_examples_for 'OK' do
      let!(:start_time) { Time.current }
      it '削除依頼日時が現在日時に変更される' do
        delete user_registration_path
        expect(user.destroy_requested_at).to be_between(start_time, Time.current)
      end
      it "削除予定日時が#{Settings['destroy_schedule_days']}日後に変更される" do
        delete user_registration_path
        expect(user.destroy_schedule_at).to be_between(start_time + Settings['destroy_schedule_days'].days,
                                                       Time.current + Settings['destroy_schedule_days'].days)
      end
    end
    shared_examples_for 'NG' do
      let!(:before_user) { user }
      it '削除依頼日時が変更されない' do
        delete user_registration_path
        expect(user.destroy_requested_at).to eq(before_user.destroy_requested_at)
      end
      it '削除予定日時が変更されない' do
        delete user_registration_path
        expect(user.destroy_schedule_at).to eq(before_user.destroy_schedule_at)
      end
    end

    shared_examples_for 'ToTop' do
      it 'トップページにリダイレクト' do
        delete user_registration_path
        expect(response).to redirect_to(root_path)
      end
    end
    shared_examples_for 'ToLogin' do
      it 'ログインにリダイレクト' do
        delete user_registration_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    # テストケース
    context '未ログイン' do
      it_behaves_like 'ToLogin'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'OK'
      it_behaves_like 'ToLogin'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like 'NG'
      it_behaves_like 'ToTop'
    end
  end

  # GET /users/undo_delete アカウント削除取り消し
  describe 'GET /users/undo_delete' do
    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get users_undo_delete_path
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToTop' do
      it 'トップページにリダイレクト' do
        get users_undo_delete_path
        expect(response).to redirect_to(root_path)
      end
    end
    shared_examples_for 'ToLogin' do
      it 'ログインにリダイレクト' do
        get users_undo_delete_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    # テストケース
    context '未ログイン' do
      it_behaves_like 'ToLogin'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'ToTop'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like 'ToOK'
    end
  end

  # PUT /users/undo_destroy アカウント削除取り消し(処理)
  describe 'PUT /users/undo_destroy' do
    # テスト内容
    shared_examples_for 'OK' do
      it '削除依頼日時が空に変更される' do
        put users_undo_destroy_path
        expect(user.destroy_requested_at).to be_nil
      end
      it '削除予定日時が空に変更される' do
        put users_undo_destroy_path
        expect(user.destroy_schedule_at).to be_nil
      end
    end
    shared_examples_for 'NG' do
      let!(:before_user) { user }
      it '削除依頼日時が変更されない' do
        put users_undo_destroy_path
        expect(user.destroy_requested_at).to eq(before_user.destroy_requested_at)
      end
      it '削除予定日時が変更されない' do
        put users_undo_destroy_path
        expect(user.destroy_schedule_at).to eq(before_user.destroy_schedule_at)
      end
    end

    shared_examples_for 'ToTop' do
      it 'トップページにリダイレクト' do
        put users_undo_destroy_path
        expect(response).to redirect_to(root_path)
      end
    end
    shared_examples_for 'ToLogin' do
      it 'ログインにリダイレクト' do
        put users_undo_destroy_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    # テストケース
    context '未ログイン' do
      it_behaves_like 'ToLogin'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'NG'
      it_behaves_like 'ToTop'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like 'OK'
      it_behaves_like 'ToTop'
    end
  end
end
