shared_context '対象の顧客作成' do |owner_count, admin_count, member_count|
  before do
    count = owner_count + admin_count + member_count
    customers = FactoryBot.create_list(:customer, count)
    index = 0
    (1..owner_count).each do
      FactoryBot.create(:customer_user, customer_id: customers[index].id, user_id: user.id, power: :Owner)
      index += 1
    end
    (1..admin_count).each do
      FactoryBot.create(:customer_user, customer_id: customers[index].id, user_id: user.id, power: :Admin)
      index += 1
    end
    (1..member_count).each do
      FactoryBot.create(:customer_user, customer_id: customers[index].id, user_id: user.id, power: :Member)
      index += 1
    end
    @inside_customers = Customer.order(created_at: 'ASC', id: 'ASC')
                                .includes(:customer_user).where(customer_users: { user_id: user.id })
    raise "#{@inside_customers.count} != #{count}" if @inside_customers.count != count
  end
end

shared_context '対象外の顧客作成' do |owner_count, admin_count, member_count|
  before do
    count = owner_count + admin_count + member_count
    customers = FactoryBot.create_list(:customer, count)
    other_user = FactoryBot.create(:user)
    index = 0
    (1..owner_count).each do
      FactoryBot.create(:customer_user, customer_id: customers[index].id, user_id: other_user.id, power: :Owner)
      index += 1
    end
    (1..admin_count).each do
      FactoryBot.create(:customer_user, customer_id: customers[index].id, user_id: other_user.id, power: :Admin)
      index += 1
    end
    (1..member_count).each do
      FactoryBot.create(:customer_user, customer_id: customers[index].id, user_id: other_user.id, power: :Member)
      index += 1
    end
    @outside_customers = Customer.order(created_at: 'ASC', id: 'ASC')
                                 .includes(:customer_user).where(customer_users: { user_id: other_user.id })
    raise "#{@outside_customers.count} != #{count}" if @outside_customers.count != count
  end
end
