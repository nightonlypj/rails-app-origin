shared_context 'リクエストスペース作成' do |public_flag = false|
  let!(:customer) { FactoryBot.create(:customer) }
  before do
    @request_space = FactoryBot.create(:space, customer_id: customer.id, public_flag: public_flag)
    @space_header = { 'Host' => "#{@request_space.subdomain}.#{Settings['base_domain']}" }
  end
end

shared_context 'スペース作成' do |count, public_flag = false|
  before do
    customer = FactoryBot.create(:customer)
    @create_spaces = FactoryBot.create_list(:space, count, customer_id: customer.id, public_flag: public_flag)
  end
end
