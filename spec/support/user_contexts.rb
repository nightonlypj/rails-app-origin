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
      # 'uid' => auth_token['uid'],
      'uid' => (user.id + (36**2)).to_s(36),
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
  let(:locked_at)            { locked ? Time.now.utc - 1.minute : nil }
  let(:failed_attempts)      { locked ? Devise.maximum_attempts : 0 }
  let(:confirmation_token)   { unconfirmed ? Devise.token_generator.digest(self, :confirmation_token, SecureRandom.uuid) : nil }
  let(:confirmation_sent_at) { unconfirmed ? Time.now.utc - 1.minute : nil }
  let(:confirmed_at)         { unconfirmed ? nil : '0000-01-01 00:00:00+0000' }
  let(:unconfirmed_email)    { change_email ? Faker::Internet.safe_email : nil }
  let!(:send_user) do
    FactoryBot.create(:user, reset_password_token: digest_token, reset_password_sent_at: sent_at,
                             unlock_token: unlock_token, locked_at: locked_at, failed_attempts: failed_attempts,
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

shared_context 'アカウントロック解除トークン作成' do |locked, expired = false|
  let(:unlock_token)    { SecureRandom.uuid }
  let(:digest_token)    { Devise.token_generator.digest(self, :unlock_token, unlock_token) }
  let(:locked_time)     { Time.now.utc - 1.minute - (expired ? Devise.unlock_in : 0) }
  let(:locked_at)       { locked ? locked_time : nil }
  let(:failed_attempts) { locked ? Devise.maximum_attempts : 0 }
  let!(:send_user)      { FactoryBot.create(:user, unlock_token: digest_token, locked_at: locked_at, failed_attempts: failed_attempts) }
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
      expect(response_json['user']['upload_image']).to eq(current_user.image?)
      expect(response_json['user']['image_url']['mini']).to eq("#{Settings['base_image_url']}#{current_user.image_url(:mini)}")
      expect(response_json['user']['image_url']['small']).to eq("#{Settings['base_image_url']}#{current_user.image_url(:small)}")
      expect(response_json['user']['image_url']['medium']).to eq("#{Settings['base_image_url']}#{current_user.image_url(:medium)}")
      expect(response_json['user']['image_url']['large']).to eq("#{Settings['base_image_url']}#{current_user.image_url(:large)}")
      expect(response_json['user']['image_url']['xlarge']).to eq("#{Settings['base_image_url']}#{current_user.image_url(:xlarge)}")
      expect(response_json['user']['name']).to eq(current_user.name)
      ## 削除予約
      expect(response_json['user']['destroy_schedule_days']).to eq(Settings['destroy_schedule_days'])
      destroy_requested_at = current_user.destroy_requested_at.present? ? I18n.l(current_user.destroy_requested_at, format: :json) : nil
      expect(response_json['user']['destroy_requested_at']).to eq(destroy_requested_at)
      destroy_schedule_at = current_user.destroy_schedule_at.present? ? I18n.l(current_user.destroy_schedule_at, format: :json) : nil
      expect(response_json['user']['destroy_schedule_at']).to eq(destroy_schedule_at)
      ## お知らせ
      expect(response_json['user']['infomation_unread_count']).to eq(current_user.infomation_unread_count)
    end
  end
  let(:expect_failure_json) do
    response_json = JSON.parse(response.body)
    expect(response_json['success']).to eq(false)
    expect(response_json['data']).to be_nil
    expect(response_json['user']).to be_nil
  end
  let(:expect_exist_auth_header) do
    # expect(response.header['uid']).to eq(current_user.email)
    expect(response.header['uid']).to eq((current_user.id + (36**2)).to_s(36))
    expect(response.header['client']).not_to be_nil
    expect(response.header['access-token']).not_to be_nil # Tips: 一定時間内のリクエスト(batch_request)は半角スペースが入る
    expect(response.header['expiry']).not_to be_nil # Tips: 同上
  end
  let(:expect_not_exist_auth_header) do
    expect(response.header['uid']).to be_nil
    expect(response.header['client']).to be_nil
    expect(response.header['access-token']).to be_nil
    expect(response.header['expiry']).to be_nil
  end
end
