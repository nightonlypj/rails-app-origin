shared_context 'ログイン処理' do |destroy_reserved_flag = false|
  let!(:user) { FactoryBot.create(:user) }
  before do
    if destroy_reserved_flag
      user.destroy_requested_at = Time.now.utc
      user.destroy_schedule_at = Time.now.utc + Settings['destroy_schedule_days'].days
    end
    sign_in user
  end
end

TEST_IMAGE_FILE = 'public/images/user/noimage.jpg'.freeze
TEST_IMAGE_TYPE = 'image/jpeg'.freeze
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
