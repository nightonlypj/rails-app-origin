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
shared_examples_for 'To404' do
  it 'HTTPステータスが404' do
    is_expected.to eq(404)
  end
end
shared_examples_for 'To404(html/html)' do
  let(:subject_format) { nil }
  let(:accept_headers) { ACCEPT_INC_HTML }
  it_behaves_like 'To404'
end
shared_examples_for 'To404(html/json)' do
  let(:subject_format) { nil }
  let(:accept_headers) { ACCEPT_INC_JSON }
  it_behaves_like 'To404'
end

shared_examples_for 'To406' do
  let(:redirect_url) { FRONT_SITE_URL }
  it 'HTTPステータスが406' do
    is_expected.to eq(406)
  end
end
shared_examples_for 'To406(json/json)' do
  let(:subject_format) { :json }
  let(:accept_headers) { ACCEPT_INC_JSON }
  it_behaves_like 'To406'
end
shared_examples_for 'To406(json/html)' do
  let(:subject_format) { :json }
  let(:accept_headers) { ACCEPT_INC_HTML }
  it_behaves_like 'To406'
end
shared_examples_for 'To406(html/json)' do
  let(:subject_format) { nil }
  let(:accept_headers) { ACCEPT_INC_JSON }
  it_behaves_like 'To406'
end
shared_examples_for 'To406(html/html)' do
  let(:subject_format) { nil }
  let(:accept_headers) { ACCEPT_INC_HTML }
  it_behaves_like 'To406'
end
