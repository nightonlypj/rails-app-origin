shared_context 'ログイン処理（管理者）' do
  let!(:admin_user) { FactoryBot.create(:admin_user) }
  before { sign_in admin_user }
end

shared_context 'パスワードリセットトークン作成（管理者）' do |valid, locked = false|
  let(:reset_password_token) { SecureRandom.uuid }
  let(:digest_token)         { Devise.token_generator.digest(self, :reset_password_token, reset_password_token) }
  let(:sent_at)              { valid ? Time.now.utc - 1.minute : '0000-01-01 00:00:00+0000' }
  let(:unlock_token)         { locked ? SecureRandom.uuid : nil }
  let(:locked_at)            { locked ? Time.now.utc - 1.minute : '0000-01-01 00:00:00+0000' }
  let!(:send_admin_user) do
    FactoryBot.create(:admin_user, reset_password_token: digest_token, reset_password_sent_at: sent_at,
                                   unlock_token: unlock_token, locked_at: locked_at)
  end
end

shared_context 'アカウントロック解除トークン作成（管理者）' do |locked|
  let(:unlock_token)     { SecureRandom.uuid }
  let(:digest_token)     { Devise.token_generator.digest(self, :unlock_token, unlock_token) }
  let(:locked_at)        { locked ? Time.now.utc - 1.minute : nil }
  let!(:send_admin_user) { FactoryBot.create(:admin_user, unlock_token: digest_token, locked_at: locked_at) }
end
