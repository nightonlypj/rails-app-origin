shared_context '未ログイン処理' do
  let(:auth_headers) { {} }
end
shared_context 'ログイン処理' do |trait = nil, use_image = false|
  include_context 'ユーザー作成', trait, use_image
  before { sign_in user }
  let(:auth_headers) { {} }
end
shared_context 'APIログイン処理' do |trait = nil, use_image = false|
  include_context 'ユーザー作成', trait, use_image
  let_it_be(:auth_token) { user.create_new_auth_token }
  let(:auth_headers) do
    {
      # 'uid' => auth_token['uid'],
      'uid' => (user.id + (36**2)).to_s(36),
      'client' => auth_token['client'],
      'access-token' => auth_token['access-token']
    }
  end
end

shared_context 'ユーザー作成' do |trait, use_image|
  let_it_be(:image) { use_image ? fixture_file_upload(TEST_IMAGE_FILE, TEST_IMAGE_TYPE) : nil }
  let_it_be(:user)  { FactoryBot.create(:user, trait, image:) }
end

shared_context 'パスワードリセットトークン作成' do |valid, locked = false, unconfirmed = false, change_email = false|
  let_it_be(:reset_password_token) { SecureRandom.uuid }
  let_it_be(:digest_token)         { Devise.token_generator.digest(self, :reset_password_token, reset_password_token) }
  let_it_be(:sent_at)              { valid ? Time.now.utc - 1.minute : '0000-01-01 00:00:00+0000' }
  let_it_be(:unlock_token)         { locked ? SecureRandom.uuid : nil }
  let_it_be(:locked_at)            { locked ? Time.now.utc - 1.minute : nil }
  let_it_be(:failed_attempts)      { locked ? Devise.maximum_attempts : 0 }
  let_it_be(:confirmation_token)   { unconfirmed ? Devise.token_generator.digest(self, :confirmation_token, SecureRandom.uuid) : nil }
  let_it_be(:confirmation_sent_at) { unconfirmed ? Time.now.utc - 1.minute : nil }
  let_it_be(:confirmed_at)         { unconfirmed ? nil : '0000-01-01 00:00:00+0000' }
  let_it_be(:unconfirmed_email)    { change_email ? Faker::Internet.email : nil }
  let_it_be(:send_user) do
    FactoryBot.create(:user, reset_password_token: digest_token, reset_password_sent_at: sent_at,
                             unlock_token:, locked_at:, failed_attempts:,
                             confirmation_token:, confirmation_sent_at:, confirmed_at:,
                             unconfirmed_email:)
  end
end

shared_context 'メールアドレス確認トークン作成' do |confirmed, before|
  let_it_be(:confirmation_token) { Devise.token_generator.digest(self, :confirmation_token, SecureRandom.uuid) }
  let_it_be(:set_confirmed_at)   { confirmation_sent_at + (before ? -1.minute : 1.minute) }
  let_it_be(:confirmed_at)       { confirmed ? set_confirmed_at : nil }
  let_it_be(:unconfirmed_email)  { confirmed && before ? Faker::Internet.email : nil }
  let_it_be(:send_user) do
    FactoryBot.create(:user, confirmation_token:, confirmation_sent_at:,
                             confirmed_at:, unconfirmed_email:)
  end
end

shared_context 'アカウントロック解除トークン作成' do |locked, expired = false|
  let_it_be(:unlock_token)    { SecureRandom.uuid }
  let_it_be(:digest_token)    { Devise.token_generator.digest(self, :unlock_token, unlock_token) }
  let_it_be(:locked_time)     { Time.now.utc - 1.minute - (expired ? Devise.unlock_in : 0) }
  let_it_be(:locked_at)       { locked ? locked_time : nil }
  let_it_be(:failed_attempts) { locked ? Devise.maximum_attempts : 0 }
  let_it_be(:send_user)       { FactoryBot.create(:user, unlock_token: digest_token, locked_at:, failed_attempts:) }
end

# テスト内容（共通）
def expect_user_json(response_json_user, user, use = { email: false })
  return 0 if user.blank?

  result = 6
  expect(response_json_user['code']).to eq(user.code)
  expect_image_json(response_json_user, user)
  expect(response_json_user['name']).to eq(user.name)
  if use[:email]
    expect(response_json_user['email']).to eq(user.email)
    result += 1
  else
    expect(response_json_user['email']).to be_nil
  end

  expect(response_json_user['destroy_requested_at']).to eq(I18n.l(user.destroy_requested_at, format: :json, default: nil))
  expect(response_json_user['destroy_schedule_at']).to eq(I18n.l(user.destroy_schedule_at, format: :json, default: nil))

  result
end

shared_examples_for 'ToTop' do |alert, notice|
  it 'トップページにリダイレクトする' do
    is_expected.to redirect_to(root_path)
    expect(flash[:alert]).to alert.present? ? eq(get_locale(alert)) : be_nil
    expect(flash[:notice]).to notice.present? ? eq(get_locale(notice)) : be_nil
  end
end
shared_examples_for 'ToLogin' do |alert, notice|
  it 'ログインにリダイレクトする' do
    is_expected.to redirect_to(new_user_session_path)
    expect(flash[:alert]).to alert.present? ? eq(get_locale(alert)) : be_nil
    expect(flash[:notice]).to notice.present? ? eq(get_locale(notice)) : be_nil
  end
end

shared_context 'Authテスト内容' do
  let(:response_json_user) { response_json['user'] }
  let(:expect_success_json) do
    expect(response_json['success']).to be(true)
    expect(response_json['data']).to be_nil
    if current_user.blank?
      expect(response_json_user).to be_nil
    else
      count = expect_user_json(response_json_user, current_user, { email: false })
      expect(response_json_user['provider']).to eq(current_user.provider)
      ## アカウント削除の猶予期間
      expect(response_json_user['destroy_schedule_days']).to eq(Settings.user_destroy_schedule_days)
      ## お知らせ
      expect(response_json_user['infomation_unread_count']).to eq(current_user.infomation_unread_count)
      expect(response_json_user.count).to eq(count + 3)
    end
  end
  let(:expect_failure_json) do
    expect(response_json['success']).to be(false)
    expect(response_json['data']).to be_nil
    expect(response_json_user).to be_nil
  end
  let(:expect_exist_auth_header) do
    # expect(response.header['uid']).to eq(current_user.email)
    expect(response.header['uid']).to eq((current_user.id + (36**2)).to_s(36))
    expect(response.header['client']).not_to be_nil
    expect(response.header['access-token']).not_to be_nil # NOTE: 一定時間内のリクエスト(batch_request)は半角スペースが入る
    expect(response.header['expiry']).not_to be_nil # NOTE: 同上
  end
  let(:expect_not_exist_auth_header) do
    expect(response.header['uid']).to be_nil
    expect(response.header['client']).to be_nil
    expect(response.header['access-token']).to be_nil
    expect(response.header['expiry']).to be_nil
  end
end
