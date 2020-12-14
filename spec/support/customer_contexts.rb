shared_context '顧客作成' do |count|
  before do
    @create_customers = FactoryBot.create_list(:customer, count)
  end
end
