require 'rails_helper'

RSpec.describe 'AdminUsers::Unlocks', type: :request do
  # GET /admin_users/unlock/new アカウントロック解除メール再送
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中 → データ＆状態作成
  describe 'GET /new' do
    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get new_admin_user_unlock_path
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToAdmin' do |alert, notice|
      it 'RailsAdminにリダイレクト' do
        get new_admin_user_unlock_path
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

  # POST /admin_users/unlock アカウントロック解除メール再送(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中 → データ＆状態作成
  #   有効なパラメータ, 無効なパラメータ → 事前にデータ作成
  describe 'POST /create' do
    include_context 'アカウントロック解除トークン作成（管理者）'
    let!(:valid_attributes) { FactoryBot.attributes_for(:admin_user, email: @send_admin_user.email) }
    let!(:invalid_attributes) { FactoryBot.attributes_for(:admin_user, email: nil) }

    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        post admin_user_unlock_path, params: { admin_user: attributes }
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToAdmin' do |alert, notice|
      it 'RailsAdminにリダイレクト' do
        post admin_user_unlock_path, params: { admin_user: attributes }
        expect(response).to redirect_to(rails_admin_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToLogin' do |alert, notice|
      it 'ログインにリダイレクト' do
        post admin_user_unlock_path, params: { admin_user: attributes }
        expect(response).to redirect_to(new_admin_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like 'ToLogin', nil, 'devise.unlocks.send_instructions'
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

  # GET /admin_users/unlock アカウントロック解除(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中 → データ＆状態作成
  #   存在するtoken, 存在しないtoken, tokenなし → データ作成
  #   未ロック（ロック日時がない）, ロック中（ロック日時がある） → データ作成
  describe 'GET /show' do
    # テスト内容
    shared_examples_for 'OK' do
      it 'アカウントロック日時が空に変更される' do
        get admin_user_unlock_path(unlock_token: unlock_token)
        expect(AdminUser.find(@send_admin_user.id).locked_at).to be_nil
      end
    end
    shared_examples_for 'NG' do
      it 'アカウントロック日時が変更されない' do
        get admin_user_unlock_path(unlock_token: unlock_token)
        expect(AdminUser.find(@send_admin_user.id).locked_at).to eq(@send_admin_user.locked_at)
      end
    end

    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get admin_user_unlock_path(unlock_token: unlock_token)
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToAdmin' do |alert, notice|
      it 'RailsAdminにリダイレクト' do
        get admin_user_unlock_path(unlock_token: unlock_token)
        expect(response).to redirect_to(rails_admin_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToLogin' do |alert, notice|
      it 'ログインにリダイレクト' do
        get admin_user_unlock_path(unlock_token: unlock_token)
        expect(response).to redirect_to(new_admin_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[未ログイン][存在するtoken]未ロック（ロック日時がない）' do
      include_context 'アカウントロック解除トークン解除（管理者）'
      # it_behaves_like 'NG' # Tips: 元々、ロック日時が空
      it_behaves_like 'ToLogin', nil, 'devise.unlocks.unlocked' # Tips: 既に解除済み
    end
    shared_examples_for '[ログイン中][存在するtoken]未ロック（ロック日時がない）' do
      include_context 'アカウントロック解除トークン解除（管理者）'
      # it_behaves_like 'NG' # Tips: 元々、ロック日時が空
      it_behaves_like 'ToAdmin', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン][存在しないtoken]未ロック（ロック日時がない）' do
      # it_behaves_like 'NG' # Tips: tokenが存在しない為、ロック日時がない
      it_behaves_like 'ToOK' # Tips: 再入力
    end
    shared_examples_for '[ログイン中][存在しないtoken]未ロック（ロック日時がない）' do
      # it_behaves_like 'NG' # Tips: tokenが存在しない為、ロック日時がない
      it_behaves_like 'ToAdmin', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン][存在するtoken]ロック中（ロック日時がある）' do
      it_behaves_like 'OK'
      it_behaves_like 'ToLogin', nil, 'devise.unlocks.unlocked'
    end
    shared_examples_for '[ログイン中][存在するtoken]ロック中（ロック日時がある）' do
      it_behaves_like 'NG'
      it_behaves_like 'ToAdmin', 'devise.failure.already_authenticated', nil
    end

    shared_examples_for '[未ログイン]存在するtoken' do
      include_context 'アカウントロック解除トークン作成（管理者）'
      it_behaves_like '[未ログイン][存在するtoken]未ロック（ロック日時がない）'
      it_behaves_like '[未ログイン][存在するtoken]ロック中（ロック日時がある）'
    end
    shared_examples_for '[ログイン中]存在するtoken' do
      include_context 'アカウントロック解除トークン作成（管理者）'
      it_behaves_like '[ログイン中][存在するtoken]未ロック（ロック日時がない）'
      it_behaves_like '[ログイン中][存在するtoken]ロック中（ロック日時がある）'
    end
    shared_examples_for '[未ログイン]存在しないtoken' do
      let!(:unlock_token) { NOT_TOKEN }
      it_behaves_like '[未ログイン][存在しないtoken]未ロック（ロック日時がない）'
      # it_behaves_like '[未ログイン][存在しないtoken]ロック中（ロック日時がある）' # Tips: tokenが存在しない為、ロック日時がない
    end
    shared_examples_for '[ログイン中]存在しないtoken' do
      let!(:unlock_token) { NOT_TOKEN }
      it_behaves_like '[ログイン中][存在しないtoken]未ロック（ロック日時がない）'
      # it_behaves_like '[ログイン中][存在しないtoken]ロック中（ロック日時がある）' # Tips: tokenが存在しない為、ロック日時がない
    end
    shared_examples_for '[未ログイン]tokenなし' do
      let!(:unlock_token) { NO_TOKEN }
      it_behaves_like '[未ログイン][存在しないtoken]未ロック（ロック日時がない）'
      # it_behaves_like '[未ログイン][存在しないtoken]ロック中（ロック日時がある）' # Tips: tokenが存在しない為、ロック日時がない
    end
    shared_examples_for '[ログイン中]tokenなし' do
      let!(:unlock_token) { NO_TOKEN }
      it_behaves_like '[ログイン中][存在しないtoken]未ロック（ロック日時がない）'
      # it_behaves_like '[ログイン中][存在しないtoken]ロック中（ロック日時がある）' # Tips: tokenが存在しない為、ロック日時がない
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]存在するtoken'
      it_behaves_like '[未ログイン]存在しないtoken'
      it_behaves_like '[未ログイン]tokenなし'
    end
    context 'ログイン中' do
      include_context 'ログイン処理（管理者）'
      it_behaves_like '[ログイン中]存在するtoken'
      it_behaves_like '[ログイン中]存在しないtoken'
      it_behaves_like '[ログイン中]tokenなし'
    end
  end
end
