shared_context 'メンバー作成' do |owner_count, admin_count, member_count, other_owner_count, other_admin_count, other_member_count|
  let!(:other_user) { FactoryBot.create(:user) }
  before do
    index = 0
    (1..owner_count).each do
      FactoryBot.create(:customer_user, customer_id: @create_customers[index].id, user_id: user.id, power: :Owner)
      index += 1
    end
    (1..admin_count).each do
      FactoryBot.create(:customer_user, customer_id: @create_customers[index].id, user_id: user.id, power: :Admin)
      index += 1
    end
    (1..member_count).each do
      FactoryBot.create(:customer_user, customer_id: @create_customers[index].id, user_id: user.id, power: :Member)
      index += 1
    end

    (1..other_owner_count).each do
      FactoryBot.create(:customer_user, customer_id: @create_customers[index].id, user_id: other_user.id, power: :Owner)
      index += 1
    end
    (1..other_admin_count).each do
      FactoryBot.create(:customer_user, customer_id: @create_customers[index].id, user_id: other_user.id, power: :Admin)
      index += 1
    end
    (1..other_member_count).each do
      FactoryBot.create(:customer_user, customer_id: @create_customers[index].id, user_id: other_user.id, power: :Member)
      index += 1
    end
  end
end

shared_context '所属顧客取得' do |check_count|
  before do
    @inside_customers = Customer.order(created_at: 'ASC', id: 'ASC')
                                .includes(:customer_user).where(customer_users: { user_id: user.id })
    raise "所属顧客取得: #{@inside_customers.count} != #{check_count}" unless @inside_customers.count == check_count
  end
end
shared_context '未所属顧客取得' do |check_count|
  before do
    @outside_customers = Customer.order(created_at: 'ASC', id: 'ASC')
                                 .includes(:customer_user).where(customer_users: { user_id: other_user.id })
    raise "未所属顧客取得: #{@outside_customers.count} != #{check_count}" unless @outside_customers.count == check_count
  end
end
