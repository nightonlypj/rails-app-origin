require 'rails_helper'

RSpec.describe 'AdminUsers::Unlocks', type: :request do
  let!(:token) { Faker::Internet.password(min_length: 20, max_length: 20) }
  let!(:send_admin_user) { FactoryBot.create(:admin_user, locked_at: Time.now.utc, unlock_token: Devise.token_generator.digest(self, :unlock_token, token)) }
  let!(:valid_attributes) { FactoryBot.attributes_for(:admin_user, email: send_admin_user.email) }
  let!(:invalid_attributes) { FactoryBot.attributes_for(:admin_user, email: nil) }

  # GET /admin_users/unlock/new アカウントロック解除メール再送
  describe 'GET /admin_users/unlock/new' do
    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get new_admin_user_unlock_path
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToAdmin' do
      it 'RailsAdminにリダイレクト' do
        get new_admin_user_unlock_path
        expect(response).to redirect_to(rails_admin_path)
      end
    end

    # テストケース
    context '未ログイン' do
      it_behaves_like 'ToOK'
    end
    context 'ログイン中' do
      include_context 'ログイン処理（管理者）'
      it_behaves_like 'ToAdmin'
    end
  end

  # POST /admin_users/unlock アカウントロック解除メール再送(処理)
  describe 'POST /admin_users/unlock' do
    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        post admin_user_unlock_path, params: { admin_user: attributes }
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToAdmin' do
      it 'RailsAdminにリダイレクト' do
        post admin_user_unlock_path, params: { admin_user: attributes }
        expect(response).to redirect_to(rails_admin_path)
      end
    end
    shared_examples_for 'ToLogin' do
      it 'ログインにリダイレクト' do
        post admin_user_unlock_path, params: { admin_user: attributes }
        expect(response).to redirect_to(new_admin_user_session_path)
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
      it_behaves_like 'ToAdmin'
    end
    shared_examples_for '[ログイン中]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'ToAdmin'
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]有効なパラメータ'
      it_behaves_like '[未ログイン]無効なパラメータ'
    end
    context 'ログイン中' do
      include_context 'ログイン処理（管理者）'
      it_behaves_like '[ログイン中]有効なパラメータ'
      it_behaves_like '[ログイン中]無効なパラメータ'
    end
  end

  # GET /admin_users/unlock アカウントロック解除(処理)
  describe 'GET /admin_users/unlock' do
    # テスト内容
    shared_examples_for 'OK' do
      it 'アカウントロック日時が空に変更される' do
        get "#{admin_user_unlock_path}?unlock_token=#{token}"
        expect(AdminUser.find(send_admin_user.id).locked_at).to be_nil
      end
    end
    shared_examples_for 'NG' do
      let!(:before_admin_user) { send_admin_user }
      it 'アカウントロック日時が変更されない' do
        get "#{admin_user_unlock_path}?unlock_token=#{token}"
        expect(AdminUser.find(send_admin_user.id).locked_at).to eq(before_admin_user.locked_at)
      end
    end

    shared_examples_for 'ToAdmin' do
      it 'RailsAdminにリダイレクト' do
        get "#{admin_user_unlock_path}?unlock_token=#{token}"
        expect(response).to redirect_to(rails_admin_path)
      end
    end
    shared_examples_for 'ToLogin' do
      it 'ログインにリダイレクト' do
        get "#{admin_user_unlock_path}?unlock_token=#{token}"
        expect(response).to redirect_to(new_admin_user_session_path)
      end
    end

    # テストケース
    context '未ログイン' do
      it_behaves_like 'OK'
      it_behaves_like 'ToLogin'
    end
    context 'ログイン中' do
      include_context 'ログイン処理（管理者）'
      it_behaves_like 'NG'
      it_behaves_like 'ToAdmin'
    end
  end
end
