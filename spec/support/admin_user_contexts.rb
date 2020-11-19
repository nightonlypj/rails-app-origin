shared_context 'ログイン処理（管理者）' do
  let!(:admin_user) { FactoryBot.create(:admin_user) }
  before { sign_in admin_user }
end
