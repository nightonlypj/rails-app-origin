require 'rails_helper'

RSpec.describe 'Users::Sessions', type: :request do
  # テスト内容（共通）
  shared_examples_for 'ToOK' do
    it 'HTTPステータスが200' do
      is_expected.to eq(200)
    end
  end
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

  # GET /users/sign_in ログイン
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）
  describe 'GET #new' do
    subject { get new_user_session_path }

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
  #   有効なパラメータ（未ロック, ロック中, メール未確認, メールアドレス変更中, 削除予約済み）, 無効なパラメータ（存在しない, ロック前, ロック前の前, ロック前の前の前）
  describe 'POST #create' do
    subject { post create_user_session_path, params: { user: attributes } }
    let(:send_user_unlocked)         { FactoryBot.create(:user) }
    let(:send_user_locked)           { FactoryBot.create(:user_locked) }
    let(:send_user_unconfirmed)      { FactoryBot.create(:user_unconfirmed) }
    let(:send_user_email_changed)    { FactoryBot.create(:user_email_changed) }
    let(:send_user_destroy_reserved) { FactoryBot.create(:user_destroy_reserved) }
    let(:not_user)                   { FactoryBot.attributes_for(:user) }
    let(:send_user_before_lock1)     { FactoryBot.create(:user_before_lock1) }
    let(:send_user_before_lock2)     { FactoryBot.create(:user_before_lock2) }
    let(:send_user_before_lock3)     { FactoryBot.create(:user_before_lock3) }
    let(:valid_attributes)        { { email: send_user.email, password: send_user.password } }
    let(:invalid_not_attributes)  { { email: not_user[:email], password: not_user[:password] } }
    let(:invalid_pass_attributes) { { email: send_user.email, password: "n#{send_user.password}" } }

    # テスト内容
    shared_examples_for 'SendLocked' do
      let(:url) { "http://#{Settings['base_domain']}#{user_unlock_path}" }
      it 'メールが送信される' do
        subject
        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect(ActionMailer::Base.deliveries[0].subject).to eq(get_subject('devise.mailer.unlock_instructions.subject')) # アカウントロックのお知らせ
        expect(ActionMailer::Base.deliveries[0].html_part.body).to include(url)
        expect(ActionMailer::Base.deliveries[0].text_part.body).to include(url)
      end
    end
    shared_examples_for 'NotSendLocked' do
      it 'メールが送信されない' do
        expect { subject }.to change(ActionMailer::Base.deliveries, :count).by(0)
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]有効なパラメータ（未ロック）' do
      let(:send_user)  { send_user_unlocked }
      let(:attributes) { valid_attributes }
      it_behaves_like 'ToTop', nil, 'devise.sessions.signed_in'
      it_behaves_like 'NotSendLocked'
    end
    shared_examples_for '[ログイン中/削除予約済み]有効なパラメータ（未ロック）' do
      let(:send_user)  { send_user_unlocked }
      let(:attributes) { valid_attributes }
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
      it_behaves_like 'NotSendLocked'
    end
    shared_examples_for '[未ログイン]有効なパラメータ（ロック中）' do
      let(:send_user)  { send_user_locked }
      let(:attributes) { valid_attributes }
      it_behaves_like 'ToError', 'devise.failure.locked'
      it_behaves_like 'NotSendLocked'
    end
    shared_examples_for '[ログイン中/削除予約済み]有効なパラメータ（ロック中）' do
      let(:send_user)  { send_user_locked }
      let(:attributes) { valid_attributes }
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
      it_behaves_like 'NotSendLocked'
    end
    shared_examples_for '[未ログイン]有効なパラメータ（メール未確認）' do
      let(:send_user)  { send_user_unconfirmed }
      let(:attributes) { valid_attributes }
      it_behaves_like 'ToLogin', 'devise.failure.unconfirmed', nil
      it_behaves_like 'NotSendLocked'
    end
    shared_examples_for '[ログイン中/削除予約済み]有効なパラメータ（メール未確認）' do
      let(:send_user)  { send_user_unconfirmed }
      let(:attributes) { valid_attributes }
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
      it_behaves_like 'NotSendLocked'
    end
    shared_examples_for '[未ログイン]有効なパラメータ（メールアドレス変更中）' do
      let(:send_user)  { send_user_email_changed }
      let(:attributes) { valid_attributes }
      it_behaves_like 'ToTop', nil, 'devise.sessions.signed_in'
      it_behaves_like 'NotSendLocked'
    end
    shared_examples_for '[ログイン中/削除予約済み]有効なパラメータ（メールアドレス変更中）' do
      let(:send_user)  { send_user_email_changed }
      let(:attributes) { valid_attributes }
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
      it_behaves_like 'NotSendLocked'
    end
    shared_examples_for '[未ログイン]有効なパラメータ（削除予約済み）' do
      let(:send_user)  { send_user_destroy_reserved }
      let(:attributes) { valid_attributes }
      it_behaves_like 'ToTop', nil, 'devise.sessions.signed_in'
      it_behaves_like 'NotSendLocked'
    end
    shared_examples_for '[ログイン中/削除予約済み]有効なパラメータ（削除予約済み）' do
      let(:send_user)  { send_user_destroy_reserved }
      let(:attributes) { valid_attributes }
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
      it_behaves_like 'NotSendLocked'
    end
    shared_examples_for '[未ログイン]無効なパラメータ（存在しない）' do
      let(:attributes) { invalid_not_attributes }
      it_behaves_like 'ToError', 'devise.failure.not_found_in_database'
      it_behaves_like 'NotSendLocked'
    end
    shared_examples_for '[ログイン中/削除予約済み]無効なパラメータ（存在しない）' do
      let(:attributes) { invalid_not_attributes }
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
      it_behaves_like 'NotSendLocked'
    end
    shared_examples_for '[未ログイン]無効なパラメータ（ロック前）' do
      let(:send_user)  { send_user_before_lock1 }
      let(:attributes) { invalid_pass_attributes }
      it_behaves_like 'ToError', 'devise.failure.send_locked'
      it_behaves_like 'SendLocked'
    end
    shared_examples_for '[ログイン中/削除予約済み]無効なパラメータ（ロック前）' do
      let(:send_user)  { send_user_before_lock1 }
      let(:attributes) { invalid_pass_attributes }
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
      it_behaves_like 'NotSendLocked'
    end
    shared_examples_for '[未ログイン]無効なパラメータ（ロック前の前）' do
      let(:send_user)  { send_user_before_lock2 }
      let(:attributes) { invalid_pass_attributes }
      it_behaves_like 'ToError', 'devise.failure.last_attempt'
      it_behaves_like 'NotSendLocked'
    end
    shared_examples_for '[ログイン中/削除予約済み]無効なパラメータ（ロック前の前）' do
      let(:send_user)  { send_user_before_lock2 }
      let(:attributes) { invalid_pass_attributes }
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
      it_behaves_like 'NotSendLocked'
    end
    shared_examples_for '[未ログイン]無効なパラメータ（ロック前の前の前）' do
      let(:send_user)  { send_user_before_lock3 }
      let(:attributes) { invalid_pass_attributes }
      it_behaves_like 'ToError', 'devise.failure.invalid'
      it_behaves_like 'NotSendLocked'
    end
    shared_examples_for '[ログイン中/削除予約済み]無効なパラメータ（ロック前の前の前）' do
      let(:send_user)  { send_user_before_lock3 }
      let(:attributes) { invalid_pass_attributes }
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
      it_behaves_like 'NotSendLocked'
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]有効なパラメータ（未ロック）'
      it_behaves_like '[未ログイン]有効なパラメータ（ロック中）'
      it_behaves_like '[未ログイン]有効なパラメータ（メール未確認）'
      it_behaves_like '[未ログイン]有効なパラメータ（メールアドレス変更中）'
      it_behaves_like '[未ログイン]有効なパラメータ（削除予約済み）'
      it_behaves_like '[未ログイン]無効なパラメータ（存在しない）'
      it_behaves_like '[未ログイン]無効なパラメータ（ロック前）'
      it_behaves_like '[未ログイン]無効なパラメータ（ロック前の前）'
      it_behaves_like '[未ログイン]無効なパラメータ（ロック前の前の前）'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ（未ロック）'
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ（ロック中）'
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ（メール未確認）'
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ（メールアドレス変更中）'
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ（削除予約済み）'
      it_behaves_like '[ログイン中/削除予約済み]無効なパラメータ（存在しない）'
      it_behaves_like '[ログイン中/削除予約済み]無効なパラメータ（ロック前）'
      it_behaves_like '[ログイン中/削除予約済み]無効なパラメータ（ロック前の前）'
      it_behaves_like '[ログイン中/削除予約済み]無効なパラメータ（ロック前の前の前）'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', :user_destroy_reserved
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ（未ロック）'
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ（ロック中）'
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ（メール未確認）'
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ（メールアドレス変更中）'
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ（削除予約済み）'
      it_behaves_like '[ログイン中/削除予約済み]無効なパラメータ（存在しない）'
      it_behaves_like '[ログイン中/削除予約済み]無効なパラメータ（ロック前）'
      it_behaves_like '[ログイン中/削除予約済み]無効なパラメータ（ロック前の前）'
      it_behaves_like '[ログイン中/削除予約済み]無効なパラメータ（ロック前の前の前）'
    end
  end

  # GET /users/sign_out ログアウト
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）
  describe 'GET #delete' do
    subject { get delete_user_session_path }

    # テストケース
    context '未ログイン' do
      it_behaves_like 'ToTop', 'devise.sessions.already_signed_out', nil
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'ToOK'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', :user_destroy_reserved
      it_behaves_like 'ToOK'
    end
  end

  # DELETE /users/sign_out ログアウト(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）
  describe 'DELETE #destroy' do
    subject { delete destroy_user_session_path }

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
