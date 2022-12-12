shared_context 'ログイン処理（管理者）' do
  let_it_be(:admin_user) { FactoryBot.create(:admin_user) }
  before { sign_in admin_user }
end

shared_context 'パスワードリセットトークン作成（管理者）' do |valid, locked = false|
  let_it_be(:reset_password_token) { SecureRandom.uuid }
  let_it_be(:digest_token)         { Devise.token_generator.digest(self, :reset_password_token, reset_password_token) }
  let_it_be(:sent_at)              { valid ? Time.now.utc - 1.minute : '0000-01-01 00:00:00+0000' }
  let_it_be(:unlock_token)         { locked ? SecureRandom.uuid : nil }
  let_it_be(:locked_at)            { locked ? Time.now.utc - 1.minute : nil }
  let_it_be(:failed_attempts)      { locked ? Devise.maximum_attempts : 0 }
  let_it_be(:send_admin_user) do
    FactoryBot.create(:admin_user, reset_password_token: digest_token, reset_password_sent_at: sent_at,
                                   unlock_token: unlock_token, locked_at: locked_at, failed_attempts: failed_attempts)
  end
end

shared_context 'アカウントロック解除トークン作成（管理者）' do |locked, expired = false|
  let_it_be(:unlock_token)    { SecureRandom.uuid }
  let_it_be(:digest_token)    { Devise.token_generator.digest(self, :unlock_token, unlock_token) }
  let_it_be(:locked_time)     { Time.now.utc - 1.minute - (expired ? Devise.unlock_in : 0) }
  let_it_be(:locked_at)       { locked ? locked_time : nil }
  let_it_be(:failed_attempts) { locked ? Devise.maximum_attempts : 0 }
  let_it_be(:send_admin_user) { FactoryBot.create(:admin_user, unlock_token: digest_token, locked_at: locked_at, failed_attempts: failed_attempts) }
end

# テスト内容（共通）
shared_examples_for 'ToAdmin' do |alert, notice|
  it 'RailsAdminにリダイレクトする' do
    is_expected.to redirect_to(rails_admin_path)
    expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
    expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
  end
end
shared_examples_for 'ToAdminLogin' do |alert, notice|
  it 'ログイン（管理者）にリダイレクトする' do
    is_expected.to redirect_to(new_admin_user_session_path)
    expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
    expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
  end
end
