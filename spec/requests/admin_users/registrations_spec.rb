require 'rails_helper'

RSpec.describe 'AdminUsers::Registrations', type: :request do
  #   # GET /admin_users/sign_up アカウント登録
  #   # 前提条件
  #   #   なし
  #   # テストパターン
  #   #   未ログイン, ログイン中 → データ＆状態作成
  #   describe 'GET /new' do
  #     # テスト内容
  #     shared_examples_for 'ToOK' do
  #       it '成功ステータス' do
  #         get new_admin_user_registration_path
  #         expect(response).to be_successful
  #       end
  #     end
  #     shared_examples_for 'ToAdmin' do |alert, notice|
  #       it 'RailsAdminにリダイレクト' do
  #         get new_admin_user_registration_path
  #         expect(response).to redirect_to(rails_admin_path)
  #         expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
  #         expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
  #       end
  #     end
  #
  #     # テストケース
  #     context '未ログイン' do
  #       it_behaves_like 'ToOK'
  #     end
  #     context 'ログイン中' do
  #       include_context 'ログイン処理（管理者）'
  #       it_behaves_like 'ToAdmin', 'devise.failure.already_authenticated', nil
  #     end
  #   end
  #
  #   # POST /admin_users アカウント登録(処理)
  #   # 前提条件
  #   #   なし
  #   # テストパターン
  #   #   未ログイン, ログイン中 → データ＆状態作成
  #   #   有効なパラメータ, 無効なパラメータ → 事前にデータ作成
  #   describe 'POST /create' do
  #     let!(:valid_attributes) { FactoryBot.attributes_for(:admin_user) }
  #     let!(:invalid_attributes) { FactoryBot.attributes_for(:admin_user, email: nil) }
  #
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
  #     shared_examples_for 'ToAdmin' do |alert, notice|
  #       it 'RailsAdminにリダイレクト' do
  #         post admin_user_registration_path, params: { admin_user: attributes }
  #         expect(response).to redirect_to(rails_admin_path)
  #         expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
  #         expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
  #       end
  #     end
  #     shared_examples_for 'ToLogin' do |alert, notice|
  #       it 'ログインにリダイレクト' do
  #         post admin_user_registration_path, params: { admin_user: attributes }
  #         expect(response).to redirect_to(new_admin_user_session_path)
  #         expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
  #         expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
  #       end
  #     end
  #
  #     # テストケース
  #     shared_examples_for '[未ログイン]有効なパラメータ' do
  #       let!(:attributes) { valid_attributes }
  #       it_behaves_like 'OK'
  #       it_behaves_like 'ToLogin', nil, 'devise.registrations.signed_up_but_unconfirmed'
  #     end
  #     shared_examples_for '[ログイン中]有効なパラメータ' do
  #       let!(:attributes) { valid_attributes }
  #       it_behaves_like 'NG'
  #       it_behaves_like 'ToAdmin', 'devise.failure.already_authenticated', nil
  #     end
  #     shared_examples_for '[未ログイン]無効なパラメータ' do
  #       let!(:attributes) { invalid_attributes }
  #       it_behaves_like 'NG'
  #       it_behaves_like 'ToOK' # Tips: 再入力
  #     end
  #     shared_examples_for '[ログイン中]無効なパラメータ' do
  #       let!(:attributes) { invalid_attributes }
  #       it_behaves_like 'NG'
  #       it_behaves_like 'ToAdmin', 'devise.failure.already_authenticated', nil
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
  #   # 前提条件
  #   #   なし
  #   # テストパターン
  #   #   未ログイン, ログイン中 → データ＆状態作成
  #   describe 'GET /edit' do
  #     # テスト内容
  #     shared_examples_for 'ToOK' do
  #       it '成功ステータス' do
  #         get edit_admin_user_registration_path
  #         expect(response).to be_successful
  #       end
  #     end
  #     shared_examples_for 'ToLogin' do |alert, notice|
  #       it 'ログインにリダイレクト' do
  #         get edit_admin_user_registration_path
  #         expect(response).to redirect_to(new_admin_user_session_path)
  #         expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
  #         expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
  #       end
  #     end
  #
  #     # テストケース
  #     context '未ログイン' do
  #       it_behaves_like 'ToLogin', 'devise.failure.unauthenticated', nil
  #     end
  #     context 'ログイン中' do
  #       include_context 'ログイン処理（管理者）'
  #       it_behaves_like 'ToOK'
  #     end
  #   end
  #
  #   # PUT /admin_users 登録情報変更(処理)
  #   # 前提条件
  #   #   なし
  #   # テストパターン
  #   #   未ログイン, ログイン中 → データ＆状態作成
  #   #   有効なパラメータ, 無効なパラメータ → 事前にデータ作成
  #   describe 'PUT /update' do
  #     let!(:valid_attributes) { FactoryBot.attributes_for(:admin_user) }
  #     let!(:invalid_attributes) { FactoryBot.attributes_for(:admin_user, email: nil) }
  #
  #     # テスト内容
  #     shared_examples_for 'OK' do
  #       it '表示名が変更される' do
  #         put admin_user_registration_path, params: { admin_user: attributes.merge(current_password: current_password) }
  #         expect(AdminUser.find(admin_user.id).name).to eq(attributes[:name])
  #       end
  #     end
  #     shared_examples_for 'NG' do
  #       it '表示名が変更されない' do
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
  #     shared_examples_for 'ToTop' do |alert, notice|
  #       it 'トップページにリダイレクト' do
  #         put admin_user_registration_path, params: { admin_user: attributes.merge(current_password: current_password) }
  #         expect(response).to redirect_to(root_path)
  #         expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
  #         expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
  #       end
  #     end
  #     shared_examples_for 'ToLogin' do |alert, notice|
  #       it 'ログインにリダイレクト' do
  #         put admin_user_registration_path, params: { admin_user: attributes.merge(current_password: current_password) }
  #         expect(response).to redirect_to(new_admin_user_session_path)
  #         expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
  #         expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
  #       end
  #     end
  #
  #     # テストケース
  #     shared_examples_for '[未ログイン]有効なパラメータ' do
  #       let!(:attributes) { valid_attributes }
  #       # it_behaves_like 'NG' # Tips: 未ログインの為、対象がない
  #       it_behaves_like 'ToLogin', 'devise.failure.unauthenticated', nil
  #     end
  #     shared_examples_for '[ログイン中]有効なパラメータ' do
  #       let!(:attributes) { valid_attributes }
  #       it_behaves_like 'OK'
  #       it_behaves_like 'ToTop', nil, 'devise.registrations.update_needs_confirmation'
  #     end
  #     shared_examples_for '[未ログイン]無効なパラメータ' do
  #       let!(:attributes) { invalid_attributes }
  #       # it_behaves_like 'NG' # Tips: 未ログインの為、対象がない
  #       it_behaves_like 'ToLogin', 'devise.failure.unauthenticated', nil
  #     end
  #     shared_examples_for '[ログイン中]無効なパラメータ' do
  #       let!(:attributes) { invalid_attributes }
  #       it_behaves_like 'NG'
  #       it_behaves_like 'ToOK' # Tips: 再入力
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
  #   # 前提条件
  #   #   なし
  #   # テストパターン
  #   #   未ログイン, ログイン中 → データ＆状態作成
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
  #            delete admin_user_registration_path
  #         end.to change(AdminUser, :count).by(0)
  #        end
  #     end
  #
  #     shared_examples_for 'ToLogin' do |alert, notice|
  #       it 'ログインにリダイレクト' do
  #         delete admin_user_registration_path
  #         expect(response).to redirect_to(new_admin_user_session_path)
  #         expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
  #         expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
  #       end
  #     end
  #
  #     # テストケース
  #     context '未ログイン' do
  #       # it_behaves_like 'NG' # Tips: 未ログインの為、対象がない
  #       it_behaves_like 'ToLogin', 'devise.failure.unauthenticated', nil
  #     end
  #     context 'ログイン中' do
  #       include_context 'ログイン処理（管理者）'
  #       it_behaves_like 'OK'
  #       it_behaves_like 'ToLogin', nil, 'devise.registrations.destroyed'
  #     end
  #   end
end
