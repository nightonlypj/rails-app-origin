require 'rails_helper'

RSpec.describe 'AdminUsers::Sessions', type: :request do
  # GET /admin/sign_in ログイン
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中 → データ＆状態作成
  describe 'GET #new' do
    subject { get new_admin_user_session_path }

    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        is_expected.to eq(200)
      end
    end
    shared_examples_for 'ToAdmin' do |alert, notice|
      it 'RailsAdminにリダイレクトする' do
        is_expected.to redirect_to(rails_admin_path)
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

  # POST /admin/sign_in ログイン(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中 → データ＆状態作成
  #   有効なパラメータ（未ロック, ロック中）, 無効なパラメータ → 事前にデータ作成
  describe 'POST #create' do
    subject { post create_admin_user_session_path, params: { admin_user: attributes } }
    let(:send_admin_user_unlocked) { FactoryBot.create(:admin_user) }
    let(:send_admin_user_locked)   { FactoryBot.create(:admin_user_locked) }
    let(:not_admin_user)           { FactoryBot.attributes_for(:admin_user) }
    let(:valid_attributes)   { { email: send_admin_user.email, password: send_admin_user.password } }
    let(:invalid_attributes) { { email: not_admin_user[:email], password: not_admin_user[:password] } }

    # テスト内容
    shared_examples_for 'ToError' do |error_msg|
      it '成功ステータス。対象のエラーメッセージが含まれる' do # Tips: 再入力
        is_expected.to eq(200)
        expect(response.body).to include(I18n.t(error_msg))
      end
    end
    shared_examples_for 'ToAdmin' do |alert, notice|
      it 'RailsAdminにリダイレクトする' do
        is_expected.to redirect_to(rails_admin_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]有効なパラメータ（未ロック）' do
      let(:send_admin_user) { send_admin_user_unlocked }
      let(:attributes)      { valid_attributes }
      it_behaves_like 'ToAdmin', nil, 'devise.sessions.signed_in'
    end
    shared_examples_for '[ログイン中]有効なパラメータ（未ロック）' do
      let(:send_admin_user) { send_admin_user_unlocked }
      let(:attributes)      { valid_attributes }
      it_behaves_like 'ToAdmin', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]有効なパラメータ（ロック中）' do
      let(:send_admin_user) { send_admin_user_locked }
      let(:attributes)      { valid_attributes }
      it_behaves_like 'ToError', 'devise.failure.locked'
    end
    shared_examples_for '[ログイン中]有効なパラメータ（ロック中）' do
      let(:send_admin_user) { send_admin_user_locked }
      let(:attributes)      { valid_attributes }
      it_behaves_like 'ToAdmin', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'ToError', 'devise.failure.invalid'
    end
    shared_examples_for '[ログイン中]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'ToAdmin', 'devise.failure.already_authenticated', nil
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]有効なパラメータ（未ロック）'
      it_behaves_like '[未ログイン]有効なパラメータ（ロック中）'
      it_behaves_like '[未ログイン]無効なパラメータ'
    end
    context 'ログイン中' do
      include_context 'ログイン処理（管理者）'
      it_behaves_like '[ログイン中]有効なパラメータ（未ロック）'
      it_behaves_like '[ログイン中]有効なパラメータ（ロック中）'
      it_behaves_like '[ログイン中]無効なパラメータ'
    end
  end

  # DELETE(GET) /admin/sign_out ログアウト(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中 → データ＆状態作成
  describe 'DELETE #destroy' do
    subject { delete destroy_admin_user_session_path }

    # テスト内容
    shared_examples_for 'ToLogin' do |alert, notice|
      it 'ログインにリダイレクトする' do
        is_expected.to redirect_to(new_admin_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    context '未ログイン' do
      it_behaves_like 'ToLogin', nil, 'devise.sessions.already_signed_out'
    end
    context 'ログイン中' do
      include_context 'ログイン処理（管理者）'
      it_behaves_like 'ToLogin', nil, 'devise.sessions.signed_out'
    end
  end
end
