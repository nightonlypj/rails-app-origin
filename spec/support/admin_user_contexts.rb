shared_context 'ログイン処理（管理者）' do
  let!(:admin_user) { FactoryBot.create(:admin_user) }
  before { sign_in admin_user }
end

shared_context 'パスワードリセットトークン作成（管理者）' do |valid_flag|
  let!(:reset_password_token) { Faker::Internet.password(min_length: 20, max_length: 20) }
  before do
    digest_token = Devise.token_generator.digest(self, :reset_password_token, reset_password_token)
    sent_at = valid_flag ? Time.now.utc : '0000-01-01 00:00:00+0000'
    @send_admin_user = FactoryBot.create(:admin_user, reset_password_token: digest_token, reset_password_sent_at: sent_at)
  end
end

shared_context 'アカウントロック解除トークン作成（管理者）' do
  let!(:unlock_token) { Faker::Internet.password(min_length: 20, max_length: 20) }
  before do
    digest_token = Devise.token_generator.digest(self, :unlock_token, unlock_token)
    @send_admin_user = FactoryBot.create(:admin_user, locked_at: Time.now.utc, unlock_token: digest_token)
  end
end
shared_context 'アカウントロック解除トークン解除（管理者）' do
  before do
    @send_admin_user.locked_at = nil
    @send_admin_user.save!
  end
end
