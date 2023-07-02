require 'rails_helper'

RSpec.describe 'Users::Sessions', type: :request do
  # GET /users/sign_in ログイン
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）
  describe 'GET #new' do
    subject { get new_user_session_path }

    # テストケース
    if Settings.api_only_mode
      it_behaves_like 'ToNG(html)', 404
      next
    end

    context '未ログイン' do
      it_behaves_like 'ToOK[status]'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', :destroy_reserved
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
  end

  # POST /users/sign_in ログイン(処理)
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）
  #   有効なパラメータ（未ロック, ロック中, メール未確認, メールアドレス変更中, 削除予約済み）, 無効なパラメータ（存在しない, ロック前, ロック前の前, ロック前の前の前）
  describe 'POST #create' do
    subject { post create_user_session_path, params: { user: attributes } }
    let_it_be(:send_user_unlocked)         { FactoryBot.create(:user) }
    let_it_be(:send_user_locked)           { FactoryBot.create(:user, :locked) }
    let_it_be(:send_user_unconfirmed)      { FactoryBot.create(:user, :unconfirmed) }
    let_it_be(:send_user_email_changed)    { FactoryBot.create(:user, :email_changed) }
    let_it_be(:send_user_destroy_reserved) { FactoryBot.create(:user, :destroy_reserved) }
    let_it_be(:not_user)                   { FactoryBot.attributes_for(:user) }
    let_it_be(:send_user_before_lock1)     { FactoryBot.create(:user, :before_lock1) }
    let_it_be(:send_user_before_lock2)     { FactoryBot.create(:user, :before_lock2) }
    let_it_be(:send_user_before_lock3)     { FactoryBot.create(:user, :before_lock3) }
    let(:valid_attributes)        { { email: send_user.email, password: send_user.password } }
    let(:invalid_attributes_not)  { { email: not_user[:email], password: not_user[:password] } }
    let(:invalid_attributes_pass) { { email: send_user.email, password: "n#{send_user.password}" } }

    # テスト内容
    shared_examples_for 'SendLocked' do
      let(:url) { "http://#{Settings.base_domain}#{user_unlock_path}" }
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
    if Settings.api_only_mode
      let(:send_user)  { send_user_unlocked }
      let(:attributes) { valid_attributes }
      it_behaves_like 'ToNG(html)', 404
      it_behaves_like 'NotSendLocked'
      next
    end

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
      let(:attributes) { invalid_attributes_not }
      it_behaves_like 'ToError', 'devise.failure.not_found_in_database'
      it_behaves_like 'NotSendLocked'
    end
    shared_examples_for '[ログイン中/削除予約済み]無効なパラメータ（存在しない）' do
      let(:attributes) { invalid_attributes_not }
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
      it_behaves_like 'NotSendLocked'
    end
    shared_examples_for '[未ログイン]無効なパラメータ（ロック前）' do
      let(:send_user)  { send_user_before_lock1 }
      let(:attributes) { invalid_attributes_pass }
      it_behaves_like 'ToError', 'devise.failure.send_locked'
      it_behaves_like 'SendLocked'
    end
    shared_examples_for '[ログイン中/削除予約済み]無効なパラメータ（ロック前）' do
      let(:send_user)  { send_user_before_lock1 }
      let(:attributes) { invalid_attributes_pass }
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
      it_behaves_like 'NotSendLocked'
    end
    shared_examples_for '[未ログイン]無効なパラメータ（ロック前の前）' do
      let(:send_user)  { send_user_before_lock2 }
      let(:attributes) { invalid_attributes_pass }
      it_behaves_like 'ToError', 'devise.failure.last_attempt'
      it_behaves_like 'NotSendLocked'
    end
    shared_examples_for '[ログイン中/削除予約済み]無効なパラメータ（ロック前の前）' do
      let(:send_user)  { send_user_before_lock2 }
      let(:attributes) { invalid_attributes_pass }
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
      it_behaves_like 'NotSendLocked'
    end
    shared_examples_for '[未ログイン]無効なパラメータ（ロック前の前の前）' do
      let(:send_user)  { send_user_before_lock3 }
      let(:attributes) { invalid_attributes_pass }
      it_behaves_like 'ToError', 'devise.failure.invalid'
      it_behaves_like 'NotSendLocked'
    end
    shared_examples_for '[ログイン中/削除予約済み]無効なパラメータ（ロック前の前の前）' do
      let(:send_user)  { send_user_before_lock3 }
      let(:attributes) { invalid_attributes_pass }
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
      it_behaves_like 'NotSendLocked'
    end

    shared_examples_for '[ログイン中/削除予約済み]' do
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
      it_behaves_like '[ログイン中/削除予約済み]'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', :destroy_reserved
      it_behaves_like '[ログイン中/削除予約済み]'
    end
  end

  # GET /users/sign_out ログアウト
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）
  describe 'GET #delete' do
    subject { get delete_user_session_path }

    # テストケース
    if Settings.api_only_mode
      include_context 'ログイン処理'
      it_behaves_like 'ToNG(html)', 404
      next
    end

    context '未ログイン' do
      it_behaves_like 'ToTop', 'devise.sessions.already_signed_out', nil
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'ToOK[status]'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', :destroy_reserved
      it_behaves_like 'ToOK[status]'
    end
  end

  # POST /users/sign_out ログアウト(処理)
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）
  describe 'POST #destroy' do
    subject { post destroy_user_session_path }

    # テストケース
    if Settings.api_only_mode
      include_context 'ログイン処理'
      it_behaves_like 'ToNG(html)', 404
      next
    end

    context '未ログイン' do
      it_behaves_like 'ToLogin', nil, 'devise.sessions.already_signed_out'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'ToLogin', nil, 'devise.sessions.signed_out'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', :destroy_reserved
      it_behaves_like 'ToLogin', nil, 'devise.sessions.signed_out'
    end
  end
end
