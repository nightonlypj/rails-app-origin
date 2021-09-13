require 'rails_helper'

RSpec.describe 'Users::Sessions', type: :request do
  # GET /users/sign_in ログイン
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）
  describe 'GET #new' do
    subject { get new_user_session_path }

    # テスト内容
    shared_examples_for 'ToOK' do
      it 'HTTPステータスが200' do
        is_expected.to eq(200)
      end
    end
    shared_examples_for 'ToTop' do |alert, notice|
      it 'トップページにリダイレクトする' do
        is_expected.to redirect_to(root_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    context '未ログイン' do
      it_behaves_like 'ToOK'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', :user_destroy_reserved
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
  end

  # POST /users/sign_in ログイン(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）
  #   有効なパラメータ（未ロック, ロック中, メール未確認, メールアドレス変更中, 削除予約済み）, 無効なパラメータ
  describe 'POST #create' do
    subject { post create_user_session_path, params: { user: attributes } }
    let(:send_user_unlocked)         { FactoryBot.create(:user) }
    let(:send_user_locked)           { FactoryBot.create(:user_locked) }
    let(:send_user_unconfirmed)      { FactoryBot.create(:user_unconfirmed) }
    let(:send_user_email_changed)    { FactoryBot.create(:user_email_changed) }
    let(:send_user_destroy_reserved) { FactoryBot.create(:user_destroy_reserved) }
    let(:not_user)                   { FactoryBot.attributes_for(:user) }
    let(:valid_attributes)   { { email: send_user.email, password: send_user.password } }
    let(:invalid_attributes) { { email: not_user[:email], password: not_user[:password] } }

    # テスト内容
    shared_examples_for 'ToError' do |error_msg|
      it 'HTTPステータスが200。対象のエラーメッセージが含まれる' do # Tips: 再入力
        is_expected.to eq(200)
        expect(response.body).to include(I18n.t(error_msg))
      end
    end
    shared_examples_for 'ToTop' do |alert, notice|
      it 'トップページにリダイレクトする' do
        is_expected.to redirect_to(root_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToLogin' do |alert, notice|
      it 'ログインにリダイレクトする' do
        is_expected.to redirect_to(new_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]有効なパラメータ（未ロック）' do
      let(:send_user)  { send_user_unlocked }
      let(:attributes) { valid_attributes }
      it_behaves_like 'ToTop', nil, 'devise.sessions.signed_in'
    end
    shared_examples_for '[ログイン中/削除予約済み]有効なパラメータ（未ロック）' do
      let(:send_user)  { send_user_unlocked }
      let(:attributes) { valid_attributes }
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]有効なパラメータ（ロック中）' do
      let(:send_user)  { send_user_locked }
      let(:attributes) { valid_attributes }
      it_behaves_like 'ToError', 'devise.failure.locked'
    end
    shared_examples_for '[ログイン中/削除予約済み]有効なパラメータ（ロック中）' do
      let(:send_user)  { send_user_locked }
      let(:attributes) { valid_attributes }
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]有効なパラメータ（メール未確認）' do
      let(:send_user)  { send_user_unconfirmed }
      let(:attributes) { valid_attributes }
      it_behaves_like 'ToLogin', 'devise.failure.unconfirmed', nil
    end
    shared_examples_for '[ログイン中/削除予約済み]有効なパラメータ（メール未確認）' do
      let(:send_user)  { send_user_unconfirmed }
      let(:attributes) { valid_attributes }
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]有効なパラメータ（メールアドレス変更中）' do
      let(:send_user)  { send_user_email_changed }
      let(:attributes) { valid_attributes }
      it_behaves_like 'ToTop', nil, 'devise.sessions.signed_in'
    end
    shared_examples_for '[ログイン中/削除予約済み]有効なパラメータ（メールアドレス変更中）' do
      let(:send_user)  { send_user_email_changed }
      let(:attributes) { valid_attributes }
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]有効なパラメータ（削除予約済み）' do
      let(:send_user)  { send_user_destroy_reserved }
      let(:attributes) { valid_attributes }
      it_behaves_like 'ToTop', nil, 'devise.sessions.signed_in'
    end
    shared_examples_for '[ログイン中/削除予約済み]有効なパラメータ（削除予約済み）' do
      let(:send_user)  { send_user_destroy_reserved }
      let(:attributes) { valid_attributes }
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'ToError', 'devise.failure.invalid'
    end
    shared_examples_for '[ログイン中/削除予約済み]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]有効なパラメータ（未ロック）'
      it_behaves_like '[未ログイン]有効なパラメータ（ロック中）'
      it_behaves_like '[未ログイン]有効なパラメータ（メール未確認）'
      it_behaves_like '[未ログイン]有効なパラメータ（メールアドレス変更中）'
      it_behaves_like '[未ログイン]有効なパラメータ（削除予約済み）'
      it_behaves_like '[未ログイン]無効なパラメータ'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ（未ロック）'
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ（ロック中）'
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ（メール未確認）'
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ（メールアドレス変更中）'
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ（削除予約済み）'
      it_behaves_like '[ログイン中/削除予約済み]無効なパラメータ'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', :user_destroy_reserved
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ（未ロック）'
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ（ロック中）'
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ（メール未確認）'
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ（メールアドレス変更中）'
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ（削除予約済み）'
      it_behaves_like '[ログイン中/削除予約済み]無効なパラメータ'
    end
  end

  # DELETE(GET) /users/sign_out ログアウト(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）
  describe 'DELETE #destroy' do
    subject { delete destroy_user_session_path }

    # テスト内容
    shared_examples_for 'ToLogin' do |alert, notice|
      it 'ログインにリダイレクトする' do
        is_expected.to redirect_to(new_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    context '未ログイン' do
      it_behaves_like 'ToLogin', nil, 'devise.sessions.already_signed_out'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'ToLogin', nil, 'devise.sessions.signed_out'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', :user_destroy_reserved
      it_behaves_like 'ToLogin', nil, 'devise.sessions.signed_out'
    end
  end
end
