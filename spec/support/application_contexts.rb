TEST_JSON_TIME_FORMAT = '%FT%T%:z'.freeze # Tips: ISO 8601 拡張形式(YYYY-MM-DDThh:mm:ss+09:00)
TEST_IMAGE_FILE = 'public/images/user/noimage.jpg'.freeze
TEST_IMAGE_TYPE = 'image/jpeg'.freeze

shared_context '共通ヘッダー' do
  let!(:base_headers) { { 'Host' => Settings['base_domain'] } }
  let!(:not_space_headers) { { 'Host' => "not.#{Settings['base_domain']}" } }
  let!(:json_headers) { { 'Content-Type' => 'application/json', 'Accept' => 'application/json' } }
end
