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
