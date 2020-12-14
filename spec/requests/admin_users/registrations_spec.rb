require 'rails_helper'

RSpec.describe 'AdminUsers::Registrations', type: :request do
  #   let!(:valid_attributes) { FactoryBot.attributes_for(:admin_user) }
  #   let!(:invalid_attributes) { FactoryBot.attributes_for(:admin_user, email: nil) }
  #
  #   # GET /admin_users/sign_up アカウント登録
  #   describe 'GET /new' do
  #     # テスト内容
  #     shared_examples_for 'ToOK' do
  #       it '成功ステータス' do
  #         get new_admin_user_registration_path
  #         expect(response).to be_successful
  #       end
  #     end
  #     shared_examples_for 'ToAdmin' do
  #       it 'RailsAdminにリダイレクト' do
  #         get new_admin_user_registration_path
  #         expect(response).to redirect_to(rails_admin_path)
  #       end
  #     end
  #
  #     # テストケース
  #     context '未ログイン' do
  #       it_behaves_like 'ToOK'
  #     end
  #     context 'ログイン中' do
  #       include_context 'ログイン処理（管理者）'
  #       it_behaves_like 'ToAdmin'
  #     end
  #   end
  #
  #   # POST /admin_users アカウント登録(処理)
  #   describe 'POST /create' do
  #     # テスト内容
  #     shared_examples_for 'OK' do
  #       it '作成される' do
  #         expect do
  #           post admin_user_registration_path, params: { admin_user: attributes }
  #         end.to change(AdminUser, :count).by(1)
  #       end
  #     end
  #     shared_examples_for 'NG' do
  #       it '作成されない' do
  #         expect do
  #           post admin_user_registration_path, params: { admin_user: attributes }
  #         end.to change(AdminUser, :count).by(0)
  #       end
  #     end
  #
  #     shared_examples_for 'ToOK' do
  #       it '成功ステータス' do
  #         post admin_user_registration_path, params: { admin_user: attributes }
  #         expect(response).to be_successful
  #       end
  #     end
  #     shared_examples_for 'ToAdmin' do
  #       it 'RailsAdminにリダイレクト' do
  #         post admin_user_registration_path, params: { admin_user: attributes }
  #         expect(response).to redirect_to(rails_admin_path)
  #       end
  #     end
  #     shared_examples_for 'ToLogin' do
  #       it 'ログインにリダイレクト' do
  #         post admin_user_registration_path, params: { admin_user: attributes }
  #         expect(response).to redirect_to(new_admin_user_session_path)
  #       end
  #     end
  #
  #     # テストケース
  #     shared_examples_for '[未ログイン]有効なパラメータ' do
  #       let!(:attributes) { valid_attributes }
  #       it_behaves_like 'OK'
  #       it_behaves_like 'ToLogin'
  #     end
  #     shared_examples_for '[未ログイン]無効なパラメータ' do
  #       let!(:attributes) { invalid_attributes }
  #       it_behaves_like 'NG'
  #       it_behaves_like 'ToOK' # Tips: 再入力の為
  #     end
  #     shared_examples_for '[ログイン中]有効なパラメータ' do
  #       let!(:attributes) { valid_attributes }
  #       it_behaves_like 'NG'
  #       it_behaves_like 'ToAdmin'
  #     end
  #     shared_examples_for '[ログイン中]無効なパラメータ' do
  #       let!(:attributes) { invalid_attributes }
  #       it_behaves_like 'NG'
  #       it_behaves_like 'ToAdmin'
  #     end
  #
  #     context '未ログイン' do
  #       it_behaves_like '[未ログイン]有効なパラメータ'
  #       it_behaves_like '[未ログイン]無効なパラメータ'
  #     end
  #     context 'ログイン中' do
  #       include_context 'ログイン処理（管理者）'
  #       it_behaves_like '[ログイン中]有効なパラメータ'
  #       it_behaves_like '[ログイン中]無効なパラメータ'
  #     end
  #   end
  #
  #   # GET /admin_users/edit 登録情報変更
  #   describe 'GET /edit' do
  #     # テスト内容
  #     shared_examples_for 'ToOK' do
  #       it '成功ステータス' do
  #         get edit_admin_user_registration_path
  #         expect(response).to be_successful
  #       end
  #     end
  #     shared_examples_for 'ToLogin' do
  #       it 'ログインにリダイレクト' do
  #         get edit_admin_user_registration_path
  #         expect(response).to redirect_to(new_admin_user_session_path)
  #       end
  #     end
  #
  #     # テストケース
  #     context '未ログイン' do
  #       it_behaves_like 'ToLogin'
  #     end
  #     context 'ログイン中' do
  #       include_context 'ログイン処理（管理者）'
  #       it_behaves_like 'ToOK'
  #     end
  #   end
  #
  #   # PUT /admin_users 登録情報変更(処理)
  #   describe 'PUT /update' do
  #     # テスト内容
  #     shared_examples_for 'OK' do
  #       it '名前が変更される' do
  #         put admin_user_registration_path, params: { admin_user: attributes.merge(current_password: current_password) }
  #         expect(AdminUser.find(admin_user.id).name).to eq(attributes[:name])
  #       end
  #     end
  #     shared_examples_for 'NG' do
  #       it '名前が変更されない' do
  #         put admin_user_registration_path, params: { admin_user: attributes.merge(current_password: current_password) }
  #         expect(AdminUser.find(admin_user.id).name).to eq(admin_user.name)
  #       end
  #     end
  #
  #     shared_examples_for 'ToOK' do
  #       it '成功ステータス' do
  #         put admin_user_registration_path, params: { admin_user: attributes.merge(current_password: current_password) }
  #         expect(response).to be_successful
  #       end
  #     end
  #     shared_examples_for 'ToTop' do
  #       it 'トップページにリダイレクト' do
  #         put admin_user_registration_path, params: { admin_user: attributes.merge(current_password: current_password) }
  #         expect(response).to redirect_to(root_path)
  #       end
  #     end
  #     shared_examples_for 'ToLogin' do
  #       it 'ログインにリダイレクト' do
  #         put admin_user_registration_path, params: { admin_user: attributes.merge(current_password: current_password) }
  #         expect(response).to redirect_to(new_admin_user_session_path)
  #       end
  #     end
  #
  #     # テストケース
  #     shared_examples_for '[未ログイン]有効なパラメータ' do
  #       let!(:attributes) { valid_attributes }
  #       it_behaves_like 'ToLogin'
  #     end
  #     shared_examples_for '[未ログイン]無効なパラメータ' do
  #       let!(:attributes) { invalid_attributes }
  #       it_behaves_like 'ToLogin'
  #     end
  #     shared_examples_for '[ログイン中]有効なパラメータ' do
  #       let!(:attributes) { valid_attributes }
  #       it_behaves_like 'OK'
  #       it_behaves_like 'ToTop'
  #     end
  #     shared_examples_for '[ログイン中]無効なパラメータ' do
  #       let!(:attributes) { invalid_attributes }
  #       it_behaves_like 'NG'
  #       it_behaves_like 'ToOK' # Tips: 再入力の為
  #     end
  #
  #     context '未ログイン' do
  #       let!(:current_password) { nil }
  #       it_behaves_like '[未ログイン]有効なパラメータ'
  #       it_behaves_like '[未ログイン]無効なパラメータ'
  #     end
  #     context 'ログイン中' do
  #       include_context 'ログイン処理（管理者）'
  #       let!(:current_password) { admin_user.password }
  #       it_behaves_like '[ログイン中]有効なパラメータ'
  #       it_behaves_like '[ログイン中]無効なパラメータ'
  #     end
  #   end
  #
  #   # DELETE /admin_users アカウント削除(処理)
  #   describe 'DELETE /destroy' do
  #     # テスト内容
  #     shared_examples_for 'OK' do
  #       it '削除される' do
  #         expect do
  #           delete admin_user_registration_path
  #         end.to change(AdminUser, :count).by(-1)
  #       end
  #     end
  #     shared_examples_for 'NG' do
  #       it '削除されない' do
  #         expect do
  #           delete admin_user_registration_path
  #         end.to change(AdminUser, :count).by(0)
  #       end
  #     end
  #
  #     shared_examples_for 'ToLogin' do
  #       it 'ログインにリダイレクト' do
  #         delete admin_user_registration_path
  #         expect(response).to redirect_to(new_admin_user_session_path)
  #       end
  #     end
  #
  #     # テストケース
  #     context '未ログイン' do
  #       it_behaves_like 'NG'
  #       it_behaves_like 'ToLogin'
  #     end
  #     context 'ログイン中' do
  #       include_context 'ログイン処理（管理者）'
  #       it_behaves_like 'OK'
  #       it_behaves_like 'ToLogin'
  #     end
  #   end
end
