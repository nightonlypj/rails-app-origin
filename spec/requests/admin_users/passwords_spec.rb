require 'rails_helper'

RSpec.describe 'AdminUsers::Passwords', type: :request do
  # GET /admin_users/password/new パスワード再設定メール送信
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中 → データ＆状態作成
  describe 'GET /new' do
    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get new_admin_user_password_path
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToAdmin' do |alert, notice|
      it 'RailsAdminにリダイレクト' do
        get new_admin_user_password_path
        expect(response).to redirect_to(rails_admin_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    context '未ログイン' do
      it_behaves_like 'ToOK'
    end
    context 'ログイン中' do
      include_context 'ログイン処理（管理者）'
      it_behaves_like 'ToAdmin', 'devise.failure.already_authenticated', nil
    end
  end

  # POST /admin_users/password パスワード再設定メール送信(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中 → データ＆状態作成
  #   有効なパラメータ, 無効なパラメータ → 事前にデータ作成
  describe 'POST /create' do
    let!(:send_admin_user) { FactoryBot.create(:admin_user) }
    let!(:valid_attributes) { FactoryBot.attributes_for(:admin_user, email: send_admin_user.email) }
    let!(:invalid_attributes) { FactoryBot.attributes_for(:admin_user, email: nil) }

    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        post admin_user_password_path, params: { admin_user: attributes }
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToAdmin' do |alert, notice|
      it 'RailsAdminにリダイレクト' do
        post admin_user_password_path, params: { admin_user: attributes }
        expect(response).to redirect_to(rails_admin_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToLogin' do |alert, notice|
      it 'ログインにリダイレクト' do
        post admin_user_password_path, params: { admin_user: attributes }
        expect(response).to redirect_to(new_admin_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like 'ToLogin', nil, 'devise.passwords.send_instructions'
    end
    shared_examples_for '[ログイン中]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like 'ToAdmin', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'ToOK' # Tips: 再入力
    end
    shared_examples_for '[ログイン中]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'ToAdmin', 'devise.failure.already_authenticated', nil
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

  # GET /admin_users/password/edit パスワード再設定
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中 → データ＆状態作成
  #   期限内のtoken, 期限切れのtoken, 存在しないtoken, tokenなし → データ作成
  describe 'GET /edit' do
    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get edit_admin_user_password_path(reset_password_token: reset_password_token)
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToAdmin' do |alert, notice|
      it 'RailsAdminにリダイレクト' do
        get edit_admin_user_password_path(reset_password_token: reset_password_token)
        expect(response).to redirect_to(rails_admin_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToLogin' do |alert, notice|
      it 'ログインにリダイレクト' do
        get edit_admin_user_password_path(reset_password_token: reset_password_token)
        expect(response).to redirect_to(new_admin_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToNew' do |alert, notice|
      it 'パスワード再設定メール送信にリダイレクト' do
        get edit_admin_user_password_path(reset_password_token: reset_password_token)
        expect(response).to redirect_to(new_admin_user_password_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]期限内のtoken' do
      include_context 'パスワードリセットトークン作成（管理者）', true
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[ログイン中]期限内のtoken' do
      include_context 'パスワードリセットトークン作成（管理者）', true
      it_behaves_like 'ToAdmin', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]期限切れのtoken' do
      include_context 'パスワードリセットトークン作成（管理者）', false
      it_behaves_like 'ToNew', 'activerecord.errors.models.admin_user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[ログイン中]期限切れのtoken' do
      include_context 'パスワードリセットトークン作成（管理者）', false
      it_behaves_like 'ToAdmin', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]存在しないtoken' do
      let!(:reset_password_token) { NOT_TOKEN }
      it_behaves_like 'ToNew', 'activerecord.errors.models.admin_user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[ログイン中]存在しないtoken' do
      let!(:reset_password_token) { NOT_TOKEN }
      it_behaves_like 'ToAdmin', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]tokenなし' do
      let!(:reset_password_token) { NO_TOKEN }
      it_behaves_like 'ToLogin', 'devise.passwords.no_token', nil
    end
    shared_examples_for '[ログイン中]tokenなし' do
      let!(:reset_password_token) { NO_TOKEN }
      it_behaves_like 'ToAdmin', 'devise.failure.already_authenticated', nil
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]期限内のtoken'
      it_behaves_like '[未ログイン]期限切れのtoken'
      it_behaves_like '[未ログイン]存在しないtoken'
      it_behaves_like '[未ログイン]tokenなし'
    end
    context 'ログイン中' do
      include_context 'ログイン処理（管理者）'
      it_behaves_like '[ログイン中]期限内のtoken'
      it_behaves_like '[ログイン中]期限切れのtoken'
      it_behaves_like '[ログイン中]存在しないtoken'
      it_behaves_like '[ログイン中]tokenなし'
    end
  end

  # PUT /admin_users/password パスワード再設定(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中 → データ＆状態作成
  #   期限内のtoken, 期限切れのtoken, 存在しないtoken, tokenなし → データ作成
  #   有効なパラメータ, 無効なパラメータ → 事前にデータ作成
  describe 'PUT /update' do
    let!(:valid_attributes) { FactoryBot.attributes_for(:admin_user) }
    let!(:invalid_attributes) { FactoryBot.attributes_for(:admin_user, password: nil) }

    # テスト内容
    shared_examples_for 'OK' do
      it 'パスワードリセット送信日時が空に変更される' do
        put admin_user_password_path, params: { admin_user: attributes.merge({ reset_password_token: reset_password_token }) }
        expect(AdminUser.find(@send_admin_user.id).reset_password_sent_at).to be_nil
      end
    end
    shared_examples_for 'NG' do
      it 'パスワードリセット送信日時が変更されない' do
        put admin_user_password_path, params: { admin_user: attributes.merge({ reset_password_token: reset_password_token }) }
        expect(AdminUser.find(@send_admin_user.id).reset_password_sent_at).to eq(@send_admin_user.reset_password_sent_at)
      end
    end

    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        put admin_user_password_path, params: { admin_user: attributes.merge({ reset_password_token: reset_password_token }) }
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToAdmin' do |alert, notice|
      it 'RailsAdminにリダイレクト' do
        put admin_user_password_path, params: { admin_user: attributes.merge({ reset_password_token: reset_password_token }) }
        expect(response).to redirect_to(rails_admin_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToNew' do |alert, notice|
      it 'パスワード再設定メール送信にリダイレクト' do
        put admin_user_password_path, params: { admin_user: attributes.merge({ reset_password_token: reset_password_token }) }
        expect(response).to redirect_to(new_admin_user_password_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[未ログイン][期限内のtoken]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      it_behaves_like 'ToAdmin', nil, 'devise.passwords.updated'
    end
    shared_examples_for '[ログイン中][期限内/期限切れのtoken]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToAdmin', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン][期限切れのtoken]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNew', 'activerecord.errors.models.admin_user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[未ログイン][存在しないtoken]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      # it_behaves_like 'NG' # Tips: tokenが存在しない為、送信日時がない
      it_behaves_like 'ToNew', 'activerecord.errors.models.admin_user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[ログイン中][存在しないtoken]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      # it_behaves_like 'NG' # Tips: tokenが存在しない為、送信日時がない
      it_behaves_like 'ToAdmin', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン][期限内のtoken]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToOK' # Tips: 再入力
    end
    shared_examples_for '[ログイン中][期限内/期限切れのtoken]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToAdmin', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン][期限切れのtoken]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNew', 'activerecord.errors.models.admin_user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[未ログイン][存在しないtoken]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      # it_behaves_like 'NG' # Tips: tokenが存在しない為、送信日時がない
      it_behaves_like 'ToNew', 'activerecord.errors.models.admin_user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[ログイン中][存在しないtoken]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      # it_behaves_like 'NG' # Tips: tokenが存在しない為、送信日時がない
      it_behaves_like 'ToAdmin', 'devise.failure.already_authenticated', nil
    end

    shared_examples_for '[未ログイン]期限内のtoken' do
      include_context 'パスワードリセットトークン作成（管理者）', true
      it_behaves_like '[未ログイン][期限内のtoken]有効なパラメータ'
      it_behaves_like '[未ログイン][期限内のtoken]無効なパラメータ'
    end
    shared_examples_for '[ログイン中]期限内のtoken' do
      include_context 'パスワードリセットトークン作成（管理者）', true
      it_behaves_like '[ログイン中][期限内/期限切れのtoken]有効なパラメータ'
      it_behaves_like '[ログイン中][期限内/期限切れのtoken]無効なパラメータ'
    end
    shared_examples_for '[未ログイン]期限切れのtoken' do
      include_context 'パスワードリセットトークン作成（管理者）', false
      it_behaves_like '[未ログイン][期限切れのtoken]有効なパラメータ'
      it_behaves_like '[未ログイン][期限切れのtoken]無効なパラメータ'
    end
    shared_examples_for '[ログイン中]期限切れのtoken' do
      include_context 'パスワードリセットトークン作成（管理者）', false
      it_behaves_like '[ログイン中][期限内/期限切れのtoken]有効なパラメータ'
      it_behaves_like '[ログイン中][期限内/期限切れのtoken]無効なパラメータ'
    end
    shared_examples_for '[未ログイン]存在しないtoken' do
      let!(:reset_password_token) { NOT_TOKEN }
      it_behaves_like '[未ログイン][存在しないtoken]有効なパラメータ'
      it_behaves_like '[未ログイン][存在しないtoken]無効なパラメータ'
    end
    shared_examples_for '[ログイン中]存在しないtoken' do
      let!(:reset_password_token) { NOT_TOKEN }
      it_behaves_like '[ログイン中][存在しないtoken]有効なパラメータ'
      it_behaves_like '[ログイン中][存在しないtoken]無効なパラメータ'
    end
    shared_examples_for '[未ログイン]tokenなし' do
      let!(:reset_password_token) { NO_TOKEN }
      it_behaves_like '[未ログイン][存在しないtoken]有効なパラメータ'
      it_behaves_like '[未ログイン][存在しないtoken]無効なパラメータ'
    end
    shared_examples_for '[ログイン中]tokenなし' do
      let!(:reset_password_token) { NO_TOKEN }
      it_behaves_like '[ログイン中][存在しないtoken]有効なパラメータ'
      it_behaves_like '[ログイン中][存在しないtoken]無効なパラメータ'
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]期限内のtoken'
      it_behaves_like '[未ログイン]期限切れのtoken'
      it_behaves_like '[未ログイン]存在しないtoken'
      it_behaves_like '[未ログイン]tokenなし'
    end
    context 'ログイン中' do
      include_context 'ログイン処理（管理者）'
      it_behaves_like '[ログイン中]期限内のtoken'
      it_behaves_like '[ログイン中]期限切れのtoken'
      it_behaves_like '[ログイン中]存在しないtoken'
      it_behaves_like '[ログイン中]tokenなし'
    end
  end
end
