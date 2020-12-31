shared_context '顧客作成' do |owner_count, admin_count, member_count|
  before do
    count = owner_count + admin_count + member_count
    customers = FactoryBot.create_list(:customer, count)
    index = 0
    (1..owner_count).each do
      FactoryBot.create(:member, customer_id: customers[index].id, user_id: user.id, power: :Owner)
      index += 1
    end
    (1..admin_count).each do
      FactoryBot.create(:member, customer_id: customers[index].id, user_id: user.id, power: :Admin)
      index += 1
    end
    (1..member_count).each do
      FactoryBot.create(:member, customer_id: customers[index].id, user_id: user.id, power: :Member)
      index += 1
    end
    @create_customers = Customer.order(created_at: 'ASC', id: 'ASC')
                                .includes(:member).where(members: { user_id: user.id })
    raise "#{@create_customers.count} != #{count}" if @create_customers.count != count
  end
end
