shared_context 'メンバー一覧作成' do |admin_count, writer_count, reader_count|
  let_it_be(:members) do
    invitation_user = FactoryBot.create(:user)
    [FactoryBot.create(:member, power: user_power, space: space, user: user)] +
      FactoryBot.create_list(:member, admin_count, :admin, space: space, invitation_user: invitation_user, invitationed_at: Time.current - 3.days) +
      FactoryBot.create_list(:member, writer_count, :writer, space: space, invitation_user: invitation_user, invitationed_at: Time.current - 2.days) +
      FactoryBot.create_list(:member, reader_count, :reader, space: space, invitation_user: invitation_user, invitationed_at: Time.current - 1.day)
  end
end
