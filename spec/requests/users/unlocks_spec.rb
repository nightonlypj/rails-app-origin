require 'rails_helper'

RSpec.describe 'Users::Unlocks', type: :request do
  let!(:token) { Faker::Internet.password(min_length: 20, max_length: 20) }
  let!(:send_user) { FactoryBot.create(:user, locked_at: Time.now.utc, unlock_token: Devise.token_generator.digest(self, :unlock_token, token)) }
  let!(:valid_attributes) { FactoryBot.attributes_for(:user, email: send_user.email) }
  let!(:invalid_attributes) { FactoryBot.attributes_for(:user, email: nil) }

  # GET /users/unlock/new アカウントロック解除メール再送
  describe 'GET /users/unlock/new' do
    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get new_user_unlock_path
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToTop' do
      it 'トップページにリダイレクト' do
        get new_user_unlock_path
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

  # POST /users/unlock アカウントロック解除メール再送(処理)
  describe 'POST /users/unlock' do
    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        post user_unlock_path, params: { user: attributes }
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToTop' do
      it 'トップページにリダイレクト' do
        post user_unlock_path, params: { user: attributes }
        expect(response).to redirect_to(root_path)
      end
    end
    shared_examples_for 'ToLogin' do
      it 'ログインにリダイレクト' do
        post user_unlock_path, params: { user: attributes }
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

  # GET /users/unlock アカウントロック解除(処理)
  describe 'GET /users/unlock' do
    # テスト内容
    shared_examples_for 'OK' do
      it 'アカウントロック日時が空に変更される' do
        get "#{user_unlock_path}?unlock_token=#{token}"
        expect(User.find(send_user.id).locked_at).to be_nil
      end
    end
    shared_examples_for 'NG' do
      let!(:before_user) { send_user }
      it 'アカウントロック日時が変更されない' do
        get "#{user_unlock_path}?unlock_token=#{token}"
        expect(User.find(send_user.id).locked_at).to eq(before_user.locked_at)
      end
    end

    shared_examples_for 'ToTop' do
      it 'トップページにリダイレクト' do
        get "#{user_unlock_path}?unlock_token=#{token}"
        expect(response).to redirect_to(root_path)
      end
    end
    shared_examples_for 'ToLogin' do
      it 'ログインにリダイレクト' do
        get "#{user_unlock_path}?unlock_token=#{token}"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    # テストケース
    context '未ログイン' do
      it_behaves_like 'OK'
      it_behaves_like 'ToLogin'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'NG'
      it_behaves_like 'ToTop'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like 'NG'
      it_behaves_like 'ToTop'
    end
  end
end
