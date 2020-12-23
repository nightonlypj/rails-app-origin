shared_context 'ログイン処理' do |destroy_reserved_flag = false|
  let!(:user) { FactoryBot.create(:user) }
  before do
    if destroy_reserved_flag
      user.destroy_requested_at = Time.now.utc
      user.destroy_schedule_at = Time.now.utc + Settings['destroy_schedule_days'].days
      user.save!
    end
    sign_in user
  end
end

shared_context '画像登録処理' do
  before do
    user.image = fixture_file_upload(TEST_IMAGE_FILE, TEST_IMAGE_TYPE)
    user.save!
  end
end
shared_context '画像削除処理' do
  after do
    user.remove_image!
    user.save!
  end
end

shared_context 'パスワードリセットトークン作成' do |valid_flag|
  let!(:reset_password_token) { Faker::Internet.password(min_length: 20, max_length: 20) }
  before do
    digest_token = Devise.token_generator.digest(self, :reset_password_token, reset_password_token)
    sent_at = valid_flag ? Time.now.utc : '0000-01-01'
    @send_user = FactoryBot.create(:user, reset_password_token: digest_token, reset_password_sent_at: sent_at)
  end
end

shared_context 'メールアドレス確認トークン作成' do |valid_flag|
  let!(:confirmation_token) { Faker::Internet.password(min_length: 20, max_length: 20) }
  before do
    @send_user = FactoryBot.build(:user, confirmation_token: confirmation_token, confirmed_at: nil)
    @send_user.confirmation_sent_at = valid_flag ? Time.now.utc : Time.now.utc - @send_user.class.confirm_within - 1.hour
    @send_user.save!
  end
end
shared_context 'メールアドレス確認トークン確認' do |confirmed_before_flag|
  before do
    @send_user.confirmed_at = @send_user.confirmation_sent_at + (confirmed_before_flag ? -1.hour : 1.hour)
    @send_user.unconfirmed_email = "a#{@send_user.email}"
    @send_user.save!
  end
end

shared_context 'アカウントロック解除トークン作成' do
  let!(:unlock_token) { Faker::Internet.password(min_length: 20, max_length: 20) }
  before do
    digest_token = Devise.token_generator.digest(self, :unlock_token, unlock_token)
    @send_user = FactoryBot.create(:user, locked_at: Time.now.utc, unlock_token: digest_token)
  end
end
shared_context 'アカウントロック解除トークン解除' do
  before do
    @send_user.locked_at = nil
    @send_user.save!
  end
end
