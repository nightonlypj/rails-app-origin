shared_context 'リクエストスペース作成' do
  let!(:customer) { FactoryBot.create(:customer) }
  before do
    @request_space = FactoryBot.create(:space, customer_id: customer.id, public_flag: false)
    @space_header = { 'Host' => "#{@request_space.subdomain}.#{Settings['base_domain']}" }
  end
end
shared_context 'リクエストスペース作成（公開）' do
  let!(:public_customer) { FactoryBot.create(:customer) }
  before do
    @public_request_space = FactoryBot.create(:space, customer_id: public_customer.id, public_flag: true)
    @public_space_header = { 'Host' => "#{@public_request_space.subdomain}.#{Settings['base_domain']}" }
  end
end

shared_context 'スペース作成' do |count, public_flag = false|
  let!(:customer) { FactoryBot.create(:customer) }
  before do
    @create_spaces = FactoryBot.create_list(:space, count, customer_id: customer.id, public_flag: public_flag)
  end
end

shared_context 'スペース作成（3顧客）' do |owner_count, admin_count, member_count, public_flag = false|
  let!(:customers) { FactoryBot.create_list(:customer, 3) }
  before do
    count = owner_count + admin_count + member_count
    FactoryBot.create_list(:space, owner_count, customer_id: customers[0].id, public_flag: public_flag)
    FactoryBot.create_list(:space, admin_count, customer_id: customers[1].id, public_flag: public_flag)
    FactoryBot.create_list(:space, member_count, customer_id: customers[2].id, public_flag: public_flag)
    @create_spaces = Space.where(customer_id: [customers[0].id, customers[1].id, customers[2].id]).order(created_at: 'ASC', id: 'ASC')
    raise "#{@create_spaces.count} != #{count}" if @create_spaces.count != count
  end
end

shared_context '画像登録処理（スペース）' do
  before do
    space.image = fixture_file_upload(TEST_IMAGE_FILE, TEST_IMAGE_TYPE)
    space.save!
  end
end
shared_context '画像削除処理（スペース）' do
  after do
    space.remove_image!
    space.save!
  end
end
