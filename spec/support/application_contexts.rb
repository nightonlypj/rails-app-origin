TEST_IMAGE_FILE = 'public/images/user/noimage.jpg'.freeze
TEST_IMAGE_TYPE = 'image/jpeg'.freeze

NO_TOKEN = ''.freeze
NOT_TOKEN = 'not'.freeze
NOT_USER_CODE = 'not'.freeze
NOT_CUSTOMER_CODE = 'not'.freeze

JSON_TIME_FORMAT = '%FT%T%:z'.freeze # Tips: ISO 8601 拡張形式(YYYY-MM-DDThh:mm:ss+09:00)

BASE_HEADER = { 'Host' => Settings['base_domain'] }.freeze
NOT_SPACE_HEADER = { 'Host' => "not.#{Settings['base_domain']}" }.freeze
