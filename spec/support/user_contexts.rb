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

shared_context 'パスワードリセットトークン作成' do |valid, locked = false, unconfirmed = false, change_email = false|
  let(:reset_password_token) { SecureRandom.uuid }
  let(:digest_token)         { Devise.token_generator.digest(self, :reset_password_token, reset_password_token) }
  let(:sent_at)              { valid ? Time.now.utc - 1.minute : '0000-01-01 00:00:00+0000' }
  let(:unlock_token)         { locked ? SecureRandom.uuid : nil }
  let(:locked_at)            { locked ? Time.now.utc - 1.minute : '0000-01-01 00:00:00+0000' }
  let(:confirmation_token)   { unconfirmed ? Devise.token_generator.digest(self, :confirmation_token, SecureRandom.uuid) : nil }
  let(:confirmation_sent_at) { unconfirmed ? Time.now.utc - 1.minute : nil }
  let(:confirmed_at)         { unconfirmed ? nil : '0000-01-01 00:00:00+0000' }
  let(:unconfirmed_email)    { change_email ? Faker::Internet.safe_email : nil }
  let!(:send_user) do
    FactoryBot.create(:user, reset_password_token: digest_token, reset_password_sent_at: sent_at,
                             unlock_token: unlock_token, locked_at: locked_at,
                             confirmation_token: confirmation_token, confirmation_sent_at: confirmation_sent_at, confirmed_at: confirmed_at,
                             unconfirmed_email: unconfirmed_email)
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

shared_context 'Authテスト内容' do
  let(:expect_success_json) do
    response_json = JSON.parse(response.body)
    expect(response_json['success']).to eq(true)
    expect(response_json['data']).to be_nil
    if current_user.blank?
      expect(response_json['user']).to be_nil
    else
      expect(response_json['user']['provider']).to eq(current_user.provider)
      expect(response_json['user']['code']).to eq(current_user.code)
      expect(response_json['user']['image_url']['mini']).to eq("#{Settings['base_image_url']}#{current_user.image_url(:mini)}")
      expect(response_json['user']['image_url']['small']).to eq("#{Settings['base_image_url']}#{current_user.image_url(:small)}")
      expect(response_json['user']['image_url']['medium']).to eq("#{Settings['base_image_url']}#{current_user.image_url(:medium)}")
      expect(response_json['user']['image_url']['large']).to eq("#{Settings['base_image_url']}#{current_user.image_url(:large)}")
      expect(response_json['user']['image_url']['xlarge']).to eq("#{Settings['base_image_url']}#{current_user.image_url(:xlarge)}")
      expect(response_json['user']['name']).to eq(current_user.name)
      expect(response_json['user']['email']).to eq(current_user.email)
      ## Trackable
      expect(response_json['user']['sign_in_count']).to eq(current_user.sign_in_count)
      current_sign_in_at = current_user.current_sign_in_at.present? ? I18n.l(current_user.current_sign_in_at, format: :json) : nil
      expect(response_json['user']['current_sign_in_at']).to eq(current_sign_in_at)
      expect(response_json['user']['last_sign_in_at']).to eq(current_user.last_sign_in_at.present? ? I18n.l(current_user.last_sign_in_at, format: :json) : nil)
      expect(response_json['user']['current_sign_in_ip']).to eq(current_user.current_sign_in_ip)
      expect(response_json['user']['last_sign_in_ip']).to eq(current_user.last_sign_in_ip)
      ## Confirmable
      expect(response_json['user']['confirmed_at']).to eq(current_user.confirmed_at.present? ? I18n.l(current_user.confirmed_at, format: :json) : nil)
      confirmation_sent_at = current_user.confirmation_sent_at.present? ? I18n.l(current_user.confirmation_sent_at, format: :json) : nil
      expect(response_json['user']['confirmation_sent_at']).to eq(confirmation_sent_at)
      expect(response_json['user']['unconfirmed_email']).to eq(current_user.unconfirmed_email)
      ## 削除予約
      destroy_requested_at = current_user.destroy_requested_at.present? ? I18n.l(current_user.destroy_requested_at, format: :json) : nil
      expect(response_json['user']['destroy_requested_at']).to eq(destroy_requested_at)
      destroy_schedule_at = current_user.destroy_schedule_at.present? ? I18n.l(current_user.destroy_schedule_at, format: :json) : nil
      expect(response_json['user']['destroy_schedule_at']).to eq(destroy_schedule_at)
    end
  end
  let(:expect_failure_json) do
    response_json = JSON.parse(response.body)
    expect(response_json['success']).to eq(false)
    expect(response_json['data']).to be_nil
    expect(response_json['user']).to be_nil
  end
  let(:expect_exist_auth_header) do
    expect(response.header['uid']).not_to be_nil
    expect(response.header['client']).not_to be_nil
    expect(response.header['access-token']).not_to be_nil
  end
  let(:expect_not_exist_auth_header) do
    expect(response.header['uid']).to be_nil
    expect(response.header['client']).to be_nil
    expect(response.header['access-token']).to be_nil
  end
end
