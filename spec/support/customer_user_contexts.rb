shared_context '顧客・ログインユーザー紐付け' do |invitationed_at, power|
  before { FactoryBot.create(:customer_user, customer_id: customer.id, user_id: user.id, invitationed_at: invitationed_at, power: power) }
end

shared_context '対象のメンバー作成' do |owner_count, admin_count, member_count, before_count|
  before do
    count = owner_count + admin_count + member_count
    users = FactoryBot.create_list(:user, count)
    index = 0
    (1..owner_count).each do
      FactoryBot.create(:customer_user, customer_id: customer.id, user_id: users[index].id, power: :Owner)
      index += 1
    end
    (1..admin_count).each do
      FactoryBot.create(:customer_user, customer_id: customer.id, user_id: users[index].id, power: :Admin)
      index += 1
    end
    (1..member_count).each do
      FactoryBot.create(:customer_user, customer_id: customer.id, user_id: users[index].id, power: :Member)
      index += 1
    end
    @inside_customer_users = CustomerUser.where(customer_id: customer.id).order(created_at: 'DESC', id: 'DESC')
                                         .includes(:user)
    raise "#{@inside_customer_users.count} != #{count} + #{before_count}" if @inside_customer_users.count != count + before_count
  end
end

shared_context '対象外のメンバー作成' do |owner_count, admin_count, member_count|
  let!(:other_customer) { FactoryBot.create(:customer) }
  before do
    count = owner_count + admin_count + member_count
    users = FactoryBot.create_list(:user, count)
    index = 0
    (1..owner_count).each do
      FactoryBot.create(:customer_user, customer_id: other_customer.id, user_id: users[index].id, power: :Owner)
      index += 1
    end
    (1..admin_count).each do
      FactoryBot.create(:customer_user, customer_id: other_customer.id, user_id: users[index].id, power: :Admin)
      index += 1
    end
    (1..member_count).each do
      FactoryBot.create(:customer_user, customer_id: other_customer.id, user_id: users[index].id, power: :Member)
      index += 1
    end
    @outside_customer_users = CustomerUser.where(customer_id: other_customer.id).order(created_at: 'DESC', id: 'DESC')
    raise "#{@outside_customer_users.count} != #{count}" if @outside_customer_users.count != count
  end
end
