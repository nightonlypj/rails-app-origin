NOT_TOKEN = 'not'.freeze

TEST_IMAGE_FILE = 'public/images/user/noimage.jpg'.freeze
TEST_IMAGE_TYPE = 'image/jpeg'.freeze

FRONT_SITE_URL = 'http://front.localhost.test/'.freeze
BAD_SITE_URL   = 'http://badsite.com/'.freeze

ACCEPT_INC_HTML = { 'accept' => 'text/html,application/xhtml+xml,application/xml,*/*' }.freeze
ACCEPT_INC_JSON = { 'accept' => 'application/json,text/plain,*/*' }.freeze

# メールタイトルを返却
def get_subject(key)
  I18n.t(key, app_name: I18n.t('app_name'), env_name: Settings['env_name'])
end

# テスト内容
shared_examples_for 'To406' do
  it 'HTTPステータスが406' do
    is_expected.to eq(406)
  end
end
