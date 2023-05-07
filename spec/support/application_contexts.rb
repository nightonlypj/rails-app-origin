NOT_TOKEN = 'not'.freeze

TEST_IMAGE_FILE = 'public/images/user/noimage.jpg'.freeze
TEST_IMAGE_TYPE = 'image/jpeg'.freeze

FRONT_SITE_URL = 'http://front.localhost.test/'.freeze
BAD_SITE_URL   = 'http://badsite.com/'.freeze

ACCEPT_INC_HTML = { 'accept' => 'text/html,application/xhtml+xml,application/xml,*/*' }.freeze
ACCEPT_INC_JSON = { 'accept' => 'application/json,text/plain,*/*' }.freeze

# メールタイトルを返却
def get_subject(key)
  I18n.t(key, app_name: I18n.t('app_name'), env_name: Settings.env_name || '')
end

# テスト内容（共通）
def expect_image_json(response_json_model, model)
  expect(response_json_model['upload_image']).to eq(model.image?)

  data = response_json_model['image_url']
  expect(data['mini']).to eq("#{Settings.base_image_url}#{model.image_url(:mini)}")
  expect(data['small']).to eq("#{Settings.base_image_url}#{model.image_url(:small)}")
  expect(data['medium']).to eq("#{Settings.base_image_url}#{model.image_url(:medium)}")
  expect(data['large']).to eq("#{Settings.base_image_url}#{model.image_url(:large)}")
  expect(data['xlarge']).to eq("#{Settings.base_image_url}#{model.image_url(:xlarge)}")
  expect(data.count).to eq(5)
end

def get_locale(key, **replace)
  result = I18n.t(key, **replace)
  raise if /translation missing:/.match(result)

  result
end

shared_examples_for 'ToRaise' do |message|
  it '例外が発生する' do
    expect { subject }.to raise_error(message)
  end
end

shared_examples_for 'ToOK[status]' do
  it 'HTTPステータスが200' do
    is_expected.to eq(200)
  end
end
shared_examples_for 'ToError' do |error_msg|
  it 'HTTPステータスが200。対象のエラーメッセージが含まれる' do # NOTE: 再入力
    is_expected.to eq(200)
    expect(response.body).to include(get_locale(error_msg))
  end
end

# :nocov:
shared_examples_for 'OK' do
  raise '各Specに作成してください。'
end
shared_examples_for 'NG' do
  raise '各Specに作成してください。'
end
# :nocov:
shared_examples_for 'OK(html)' do
  let(:subject_format) { nil }
  let(:accept_headers) { ACCEPT_INC_HTML }
  it_behaves_like 'OK'
end
shared_examples_for 'NG(html)' do
  let(:subject_format) { nil }
  let(:accept_headers) { ACCEPT_INC_HTML }
  it_behaves_like 'NG'
end
shared_examples_for 'OK(json)' do
  let(:subject_format) { :json }
  let(:accept_headers) { ACCEPT_INC_JSON }
  it_behaves_like 'OK'
end
shared_examples_for 'NG(json)' do
  let(:subject_format) { :json }
  let(:accept_headers) { ACCEPT_INC_JSON }
  it_behaves_like 'NG'
end

# :nocov:
shared_examples_for 'ToOK(html/*)' do
  raise '各Specに作成してください。'
end
shared_examples_for 'ToOK(json/json)' do
  raise '各Specに作成してください。'
end
# :nocov:
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

shared_examples_for 'ToNG(html/html)' do |code, errors = nil|
  let(:subject_format) { nil }
  let(:accept_headers) { ACCEPT_INC_HTML }
  it "HTTPステータスが#{code}#{'。エラーメッセージが含まれる' if errors.present?}" do
    is_expected.to eq(code)
    next if errors.blank?

    errors.each do |error|
      expect(response.body).to include(error)
    end
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
shared_examples_for 'ToNG(json/json)' do |code, errors, alert = nil, notice = nil|
  let(:subject_format) { :json }
  let(:accept_headers) { ACCEPT_INC_JSON }
  let(:alert_key) do
    return alert if alert.present?

    case code
    when 401
      'devise.failure.unauthenticated'
    when 403
      'alert.user.forbidden'
    when 404
      'alert.page.notfound'
    when 406
      nil
    when 422
      'errors.messages.not_saved.other'
    else
      # :nocov:
      raise "code not found.(#{code})"
      # :nocov:
    end
  end
  it "HTTPステータスが#{code}。対象項目が一致する" do
    is_expected.to eq(code)
    expect(response_json['success']).to eq(code == 406 ? nil : false)
    expect(response_json['errors']).to errors.present? ? eq(errors.stringify_keys) : be_nil
    expect(response_json['alert']).to alert_key.present? ? eq(get_locale(alert_key)) : be_nil
    expect(response_json['notice']).to notice.present? ? eq(get_locale(notice)) : be_nil
  end
end
shared_examples_for 'ToNG(html)' do |code, errors = nil|
  raise 'errors blank.' if code == 422 && errors.blank?

  let(:subject_page) { 1 }
  it_behaves_like 'ToNG(html/html)', code, errors
  it_behaves_like 'ToNG(html/json)', code
end
shared_examples_for 'ToNG(json)' do |code, errors = nil, alert = nil, notice = nil|
  let(:subject_page) { 1 }
  it_behaves_like 'ToNG(json/html)', 406
  it_behaves_like 'ToNG(json/json)', code, errors, alert, notice
end

shared_examples_for 'ToLogin(html/*)' do
  it 'ログインにリダイレクトする' do
    is_expected.to redirect_to(new_user_session_path)
    expect(flash[:alert]).to eq(get_locale('devise.failure.unauthenticated'))
    expect(flash[:notice]).to be_nil
  end
end
shared_examples_for 'ToLogin(html/html)' do
  let(:subject_format) { nil }
  let(:accept_headers) { ACCEPT_INC_HTML }
  it_behaves_like 'ToLogin(html/*)'
end
shared_examples_for 'ToLogin(html/json)' do
  let(:subject_format) { nil }
  let(:accept_headers) { ACCEPT_INC_JSON }
  it_behaves_like 'ToLogin(html/*)'
end
shared_examples_for 'ToLogin(html)' do
  let(:subject_page) { 1 }
  it_behaves_like 'ToLogin(html/html)'
  it_behaves_like 'ToLogin(html/json)'
end
