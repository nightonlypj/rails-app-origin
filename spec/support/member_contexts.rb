shared_context '顧客・ユーザー紐付け' do |invitationed_at, power|
  let!(:member) { FactoryBot.create(:member, customer_id: customer.id, user_id: user.id, invitationed_at: invitationed_at, power: power) }
end
shared_context '顧客・ユーザー紐付け（公開）' do |invitationed_at, power|
  before do
    FactoryBot.create(:member, customer_id: public_customer.id, user_id: user.id, invitationed_at: invitationed_at, power: power)
  end
end

shared_context '顧客・ユーザー紐付け（3顧客・権限）' do
  let!(:member_owner) { FactoryBot.create(:member, customer_id: customers[0].id, user_id: user.id, invitationed_at: Time.current, power: :Owner) }
  let!(:member_admin) { FactoryBot.create(:member, customer_id: customers[1].id, user_id: user.id, invitationed_at: Time.current, power: :Admin) }
  let!(:member_member) { FactoryBot.create(:member, customer_id: customers[2].id, user_id: user.id, invitationed_at: Time.current, power: :Member) }
end

shared_context 'メンバー作成' do |owner_count, admin_count, member_count, before_count, sort = 'DESC'|
  before do
    count = owner_count + admin_count + member_count
    @create_users = FactoryBot.create_list(:user, count)
    index = 0
    (1..owner_count).each do
      FactoryBot.create(:member, customer_id: customer.id, user_id: @create_users[index].id, power: :Owner)
      index += 1
    end
    (1..admin_count).each do
      FactoryBot.create(:member, customer_id: customer.id, user_id: @create_users[index].id, power: :Admin)
      index += 1
    end
    (1..member_count).each do
      FactoryBot.create(:member, customer_id: customer.id, user_id: @create_users[index].id, power: :Member)
      index += 1
    end
    @create_members = Member.where(customer_id: customer.id).order(created_at: sort, id: sort)
                            .includes(:user)
    raise "#{@create_members.count} != #{count} + #{before_count}" if @create_members.count != count + before_count

    # Tips: 登録待ち(member.registrationed_atがnil)のユーザー
    @create_users[count - 1].invitation_requested_at = Time.current
    @create_users[count - 1].save!
  end
end

shared_context 'メンバー作成（対象外）' do |sort = 'DESC'|
  let!(:outside_customer) { FactoryBot.create(:customer) }
  before do
    @create_outside_users = FactoryBot.create_list(:user, 3)
    FactoryBot.create(:member, customer_id: outside_customer.id, user_id: @create_outside_users[0].id, power: :Owner)
    FactoryBot.create(:member, customer_id: outside_customer.id, user_id: @create_outside_users[1].id, power: :Admin)
    FactoryBot.create(:member, customer_id: outside_customer.id, user_id: @create_outside_users[2].id, power: :Member)
    @create_outside_members = Member.where(customer_id: outside_customer.id).order(created_at: sort, id: sort)
                                    .includes(:user)
    raise "#{@create_outside_members.count} != 3" if @create_outside_members.count != 3
  end
end
