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

# テスト内容（共通）
shared_examples_for 'ToOK[status]' do
  it 'HTTPステータスが200' do
    is_expected.to eq(200)
  end
end
shared_examples_for 'ToError' do |error_msg|
  it 'HTTPステータスが200。対象のエラーメッセージが含まれる' do # NOTE: 再入力
    is_expected.to eq(200)
    expect(response.body).to include(I18n.t(error_msg))
  end
end

shared_examples_for 'ToOK(html/*)' do
  raise '各Specに作成してください。'
end
shared_examples_for 'ToOK(json/json)' do
  raise '各Specに作成してください。'
end
shared_examples_for 'ToOK(html/html)' do
  let(:subject_format) { nil }
  let(:accept_headers) { ACCEPT_INC_HTML }
  it_behaves_like 'ToOK(html/*)'
end
shared_examples_for 'ToOK(html/json)' do
  let(:subject_format) { nil }
  let(:accept_headers) { ACCEPT_INC_JSON }
  it_behaves_like 'ToOK(html/*)'
end
shared_examples_for 'ToOK(html)' do |page = nil|
  let(:subject_page) { page }
  it_behaves_like 'ToOK(html/html)'
  it_behaves_like 'ToOK(html/json)'
end
shared_examples_for 'ToOK(json)' do |page = nil|
  let(:subject_page) { page }
  it_behaves_like 'ToNG(json/html)', 406
  it_behaves_like 'ToOK(json/json)'
end

shared_examples_for 'ToNG(html/html)' do |code|
  let(:subject_format) { nil }
  let(:accept_headers) { ACCEPT_INC_HTML }
  it "HTTPステータスが#{code}" do
    is_expected.to eq(code)
  end
end
shared_examples_for 'ToNG(html/json)' do |code|
  let(:subject_format) { nil }
  let(:accept_headers) { ACCEPT_INC_JSON }
  it "HTTPステータスが#{code}" do
    is_expected.to eq(code)
  end
end
shared_examples_for 'ToNG(json/html)' do |code|
  let(:subject_format) { :json }
  let(:accept_headers) { ACCEPT_INC_HTML }
  it "HTTPステータスが#{code}" do
    is_expected.to eq(code)
  end
end
shared_examples_for 'ToNG(json/json)' do |code, alert, notice|
  let(:subject_format) { :json }
  let(:accept_headers) { ACCEPT_INC_JSON }
  it "HTTPステータスが#{code}。対象項目が一致する" do
    is_expected.to eq(code)
    expect(response_json['success']).to eq(false)
    expect(response_json['alert']).to alert.present? ? eq(I18n.t(alert)) : be_nil
    expect(response_json['notice']).to notice.present? ? eq(I18n.t(notice)) : be_nil
  end
end
shared_examples_for 'ToNG(html)' do |code|
  let(:subject_page) { 1 }
  it_behaves_like 'ToNG(html/html)', code
  it_behaves_like 'ToNG(html/json)', code
end
shared_examples_for 'ToNG(json)' do |code, alert = nil, notice = nil|
  let(:subject_page) { 1 }
  it_behaves_like 'ToNG(json/html)', 406
  it_behaves_like 'ToNG(json/json)', code, alert_key(code, alert), notice
end
def alert_key(code, alert)
  return alert if alert.present?

  case code
  when 401
    'devise.failure.unauthenticated'
  when 403
    'alert.user.forbidden'
  when 404
    'alert.page.notfound'
  else
    raise "code not found.(#{code})"
  end
end
