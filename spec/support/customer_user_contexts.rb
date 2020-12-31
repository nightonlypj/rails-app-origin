shared_context '顧客・ユーザー紐付け' do |invitationed_at, power|
  let!(:customer_user) { FactoryBot.create(:customer_user, customer_id: customer.id, user_id: user.id, invitationed_at: invitationed_at, power: power) }
end

shared_context 'メンバー作成' do |owner_count, admin_count, member_count, before_count, sort = 'DESC'|
  before do
    count = owner_count + admin_count + member_count
    @create_users = FactoryBot.create_list(:user, count)
    index = 0
    (1..owner_count).each do
      FactoryBot.create(:customer_user, customer_id: customer.id, user_id: @create_users[index].id, power: :Owner)
      index += 1
    end
    (1..admin_count).each do
      FactoryBot.create(:customer_user, customer_id: customer.id, user_id: @create_users[index].id, power: :Admin)
      index += 1
    end
    (1..member_count).each do
      FactoryBot.create(:customer_user, customer_id: customer.id, user_id: @create_users[index].id, power: :Member)
      index += 1
    end
    @create_customer_users = CustomerUser.where(customer_id: customer.id).order(created_at: sort, id: sort)
                                         .includes(:user)
    raise "#{@create_customer_users.count} != #{count} + #{before_count}" if @create_customer_users.count != count + before_count
  end
end

shared_context '対象外メンバー作成' do |sort = 'DESC'|
  let!(:outside_customer) { FactoryBot.create(:customer) }
  before do
    @create_outside_users = FactoryBot.create_list(:user, 3)
    FactoryBot.create(:customer_user, customer_id: outside_customer.id, user_id: @create_outside_users[0].id, power: :Owner)
    FactoryBot.create(:customer_user, customer_id: outside_customer.id, user_id: @create_outside_users[1].id, power: :Admin)
    FactoryBot.create(:customer_user, customer_id: outside_customer.id, user_id: @create_outside_users[2].id, power: :Member)
    @create_outside_customer_users = CustomerUser.where(customer_id: outside_customer.id).order(created_at: sort, id: sort)
                                                 .includes(:user)
    raise "#{@create_outside_customer_users.count} != 3" if @create_outside_customer_users.count != 3
  end
end
