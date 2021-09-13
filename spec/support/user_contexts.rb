shared_context '未ログイン処理' do
  let(:auth_headers) { {} }
end
shared_context 'ログイン処理' do |target = :user, use_image = false|
  include_context 'ユーザー作成', target, use_image
  before { sign_in user }
  let(:auth_headers) { {} }
end
shared_context 'APIログイン処理' do |target = :user, use_image = false|
  include_context 'ユーザー作成', target, use_image
  let(:auth_token) { user.create_new_auth_token }
  let(:auth_headers) do
    {
      'uid' => auth_token['uid'],
      'client' => auth_token['client'],
      'access-token' => auth_token['access-token']
    }
  end
end

shared_context 'ユーザー作成' do |target, use_image|
  let(:image) { use_image ? fixture_file_upload(TEST_IMAGE_FILE, TEST_IMAGE_TYPE) : nil }
  let!(:user) { FactoryBot.create(target, image: image) }
  include_context '画像削除処理' if use_image
end

shared_context '画像削除処理' do
  after do
    user.remove_image!
    user.save!
  end
end

shared_context 'パスワードリセットトークン作成' do |valid, locked = false, unconfirmed = false|
  let(:reset_password_token) { SecureRandom.uuid }
  let(:digest_token)         { Devise.token_generator.digest(self, :reset_password_token, reset_password_token) }
  let(:sent_at)              { valid ? Time.now.utc - 1.minute : '0000-01-01 00:00:00+0000' }
  let(:unlock_token)         { locked ? SecureRandom.uuid : nil }
  let(:locked_at)            { locked ? Time.now.utc - 1.minute : '0000-01-01 00:00:00+0000' }
  let(:confirmation_token)   { unconfirmed ? Devise.token_generator.digest(self, :confirmation_token, SecureRandom.uuid) : nil }
  let(:confirmation_sent_at) { unconfirmed ? Time.now.utc - 1.minute : nil }
  let(:confirmed_at)         { unconfirmed ? nil : '0000-01-01 00:00:00+0000' }
  let!(:send_user) do
    FactoryBot.create(:user, reset_password_token: digest_token, reset_password_sent_at: sent_at,
                             unlock_token: unlock_token, locked_at: locked_at,
                             confirmation_token: confirmation_token, confirmation_sent_at: confirmation_sent_at, confirmed_at: confirmed_at)
  end
end

shared_context 'メールアドレス確認トークン作成' do |confirmed, before|
  let(:confirmation_token) { Devise.token_generator.digest(self, :confirmation_token, SecureRandom.uuid) }
  let(:set_confirmed_at)   { confirmation_sent_at + (before ? -1.minute : 1.minute) }
  let(:confirmed_at)       { confirmed ? set_confirmed_at : nil }
  let(:unconfirmed_email)  { confirmed && before ? Faker::Internet.safe_email : nil }
  let!(:send_user) do
    FactoryBot.create(:user, confirmation_token: confirmation_token, confirmation_sent_at: confirmation_sent_at,
                             confirmed_at: confirmed_at, unconfirmed_email: unconfirmed_email)
  end
end

shared_context 'アカウントロック解除トークン作成' do |locked|
  let(:unlock_token) { SecureRandom.uuid }
  let(:digest_token) { Devise.token_generator.digest(self, :unlock_token, unlock_token) }
  let(:locked_at)    { locked ? Time.now.utc - 1.minute : nil }
  let!(:send_user)   { FactoryBot.create(:user, unlock_token: digest_token, locked_at: locked_at) }
end
