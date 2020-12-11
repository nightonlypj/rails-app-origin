require 'rails_helper'

RSpec.describe 'Spaces', type: :request do
  let!(:base_headers) { { 'Host' => Settings['base_domain'] } }
  let!(:json_headers) { { 'Content-Type' => 'application/json', 'Accept' => 'application/json' } }
  let!(:user) { FactoryBot.create(:user) }
  shared_context 'ログイン処理' do
    before { sign_in user }
  end
  let!(:customer) { FactoryBot.create(:customer) }

  shared_context '存在するサブドメイン作成' do
    before do
      request_space = FactoryBot.create(:space, customer_id: customer.id)
      @space_headers = { 'Host' => "#{request_space.subdomain}.#{Settings['base_domain']}" }
    end
  end
  shared_context '存在しないサブドメイン作成' do
    before { @space_headers = { 'Host' => "not.#{Settings['base_domain']}" } }
  end

  # GET /spaces（ベースドメイン） スペース一覧
  # GET /spaces.json（ベースドメイン） スペース一覧API
  describe 'GET /index' do
    shared_examples_for 'ベースドメイン' do
      it 'renders a successful response' do
        get spaces_path, headers: base_headers
        expect(response).to be_successful
      end
      it '(json)renders a successful response' do
        get spaces_path, headers: base_headers.merge(json_headers)
        expect(response).to be_successful
      end
    end
    shared_examples_for 'サブドメイン' do
      it 'スペース一覧（ベースドメイン）にリダイレクト' do
        get spaces_path, headers: @space_headers
        expect(response).to redirect_to("//#{Settings['base_domain']}#{spaces_path}")
      end
      it '(json)renders a not found response' do
        get spaces_path, headers: @space_headers.merge(json_headers)
        expect(response).to be_not_found
      end
    end

    shared_examples_for '存在するサブドメイン' do
      include_context '存在するサブドメイン作成'
      it_behaves_like 'サブドメイン'
    end
    shared_examples_for '存在しないサブドメイン' do
      include_context '存在しないサブドメイン作成'
      it_behaves_like 'サブドメイン'
    end

    context '未ログイン' do
      it_behaves_like 'ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
  end

  describe 'GET /index @spaces' do
    shared_context 'スペース作成' do |limit|
      before { @create_spaces = FactoryBot.create_list(:space, limit, customer_id: customer.id) }
    end

    shared_examples_for 'ベースドメイン、1ページ、1番新しいスペース' do
      it '名前が含まれる' do
        get spaces_path, headers: base_headers
        expect(response.body).to include(@create_spaces[@create_spaces.count - 1].name)
      end
      it 'パスが含まれる' do
        get spaces_path, headers: base_headers
        expect(response.body).to include("//#{@create_spaces[@create_spaces.count - 1].subdomain}.#{Settings['base_domain']}")
      end
      it '(json)名前が一致する' do
        get spaces_path, headers: base_headers.merge(json_headers)
        response_spaces = JSON.parse(response.body)['spaces']
        expect(response_spaces[0]['name']).to eq(@create_spaces[@create_spaces.count - 1].name)
      end
      it '(json)サブドメインが一致する' do
        get spaces_path, headers: base_headers.merge(json_headers)
        response_spaces = JSON.parse(response.body)['spaces']
        expect(response_spaces[0]['subdomain']).to eq(@create_spaces[@create_spaces.count - 1].subdomain)
      end
    end
    shared_examples_for "ベースドメイン、1ページ、#{Settings['default_spaces_limit']}番目に新しいスペース" do
      it '名前が含まれる' do
        get spaces_path, headers: base_headers
        expect(response.body).to include(@create_spaces[@create_spaces.count - Settings['default_spaces_limit']].name)
      end
      it 'パスが含まれる' do
        get spaces_path, headers: base_headers
        expect(response.body).to include("//#{@create_spaces[@create_spaces.count - Settings['default_spaces_limit']].subdomain}.#{Settings['base_domain']}")
      end
      it '(json)名前が一致する' do
        get spaces_path, headers: base_headers.merge(json_headers)
        response_spaces = JSON.parse(response.body)['spaces']
        expect(response_spaces[Settings['default_spaces_limit'] - 1]['name']).to eq(@create_spaces[@create_spaces.count - Settings['default_spaces_limit']].name)
      end
      it '(json)サブドメインが一致する' do
        get spaces_path, headers: base_headers.merge(json_headers)
        response_spaces = JSON.parse(response.body)['spaces']
        expect(response_spaces[Settings['default_spaces_limit'] - 1]['subdomain']).to eq(@create_spaces[@create_spaces.count - Settings['default_spaces_limit']].subdomain)
      end
    end
    shared_examples_for "ベースドメイン、1ページ、#{Settings['default_spaces_limit'] + 1}番目に新しいスペース" do
      it '名前が含まれない' do
        get spaces_path, headers: base_headers
        expect(response.body).not_to include(@create_spaces[@create_spaces.count - (Settings['default_spaces_limit'] + 1)].name)
      end
      it 'パスが含まれない' do
        get spaces_path, headers: base_headers
        expect(response.body).not_to include("//#{@create_spaces[@create_spaces.count - (Settings['default_spaces_limit'] + 1)].subdomain}.#{Settings['base_domain']}")
      end
    end
    shared_examples_for "ベースドメイン、2ページ、#{Settings['default_spaces_limit'] + 1}番目に新しいスペース" do
      it '名前が含まれる' do
        get spaces_path(page: 2), headers: base_headers
        expect(response.body).to include(@create_spaces[@create_spaces.count - (Settings['default_spaces_limit'] + 1)].name)
      end
      it 'パスが含まれる' do
        get spaces_path(page: 2), headers: base_headers
        expect(response.body).to include("//#{@create_spaces[@create_spaces.count - (Settings['default_spaces_limit'] + 1)].subdomain}.#{Settings['base_domain']}")
      end
      it '(json)名前が一致する' do
        get spaces_path(page: 2), headers: base_headers.merge(json_headers)
        response_spaces = JSON.parse(response.body)['spaces']
        expect(response_spaces[0]['name']).to eq(@create_spaces[@create_spaces.count - (Settings['default_spaces_limit'] + 1)].name)
      end
      it '(json)サブドメインが一致する' do
        get spaces_path(page: 2), headers: base_headers.merge(json_headers)
        response_spaces = JSON.parse(response.body)['spaces']
        expect(response_spaces[0]['subdomain']).to eq(@create_spaces[@create_spaces.count - (Settings['default_spaces_limit'] + 1)].subdomain)
      end
    end

    shared_examples_for 'ベースドメイン、スペースが最大数以下' do
      it '2ページ目のパスが含まれない' do
        get spaces_path, headers: base_headers
        expect(response.body).not_to include("\"#{spaces_path(page: 2)}\"")
      end
    end
    shared_examples_for 'ベースドメイン、スペースが最大表示数より多い' do
      it '2ページ目のパスが含まれる' do
        get spaces_path, headers: base_headers
        expect(response.body).to include("\"#{spaces_path(page: 2)}\"")
      end
    end

    shared_examples_for 'ベースドメイン' do
      it 'スペース作成のパスが含まれる' do
        get spaces_path, headers: base_headers
        expect(response.body).to include("\"#{new_space_path}\"")
      end
      it '(json)全件数が一致する' do
        get spaces_path, headers: base_headers.merge(json_headers)
        expect(JSON.parse(response.body)['total_count']).to eq(@create_spaces.count)
      end
      it '(json)1ページ、現在ページが一致する' do
        get spaces_path, headers: base_headers.merge(json_headers)
        expect(JSON.parse(response.body)['current_page']).to eq(1)
      end
      it '(json)2ページ、現在ページが一致する' do
        get spaces_path(page: 2), headers: base_headers.merge(json_headers)
        expect(JSON.parse(response.body)['current_page']).to eq(2)
      end
      it '(json)全ページ数が一致する' do
        get spaces_path, headers: base_headers.merge(json_headers)
        expect(JSON.parse(response.body)['total_pages']).to eq((@create_spaces.count - 1).div(Settings['default_spaces_limit']) + 1)
      end
      it '(json)最大表示件数が一致する' do
        get spaces_path, headers: base_headers.merge(json_headers)
        expect(JSON.parse(response.body)['limit_value']).to eq(Settings['default_spaces_limit'])
      end
    end

    shared_examples_for 'スペースが0件' do
      include_context 'スペース作成', 0
      it_behaves_like 'ベースドメイン、スペースが最大数以下'
      it_behaves_like 'ベースドメイン'
    end
    shared_examples_for 'スペースが最大表示数と同じ' do
      include_context 'スペース作成', Settings['default_spaces_limit']
      it_behaves_like 'ベースドメイン、1ページ、1番新しいスペース'
      it_behaves_like "ベースドメイン、1ページ、#{Settings['default_spaces_limit']}番目に新しいスペース"
      it_behaves_like 'ベースドメイン、スペースが最大数以下'
      it_behaves_like 'ベースドメイン'
    end
    shared_examples_for 'スペースが最大表示数より多い' do
      include_context 'スペース作成', Settings['default_spaces_limit'] + 1
      it_behaves_like 'ベースドメイン、1ページ、1番新しいスペース'
      it_behaves_like "ベースドメイン、1ページ、#{Settings['default_spaces_limit']}番目に新しいスペース"
      it_behaves_like "ベースドメイン、1ページ、#{Settings['default_spaces_limit'] + 1}番目に新しいスペース"
      it_behaves_like "ベースドメイン、2ページ、#{Settings['default_spaces_limit'] + 1}番目に新しいスペース"
      it_behaves_like 'ベースドメイン、スペースが最大表示数より多い'
      it_behaves_like 'ベースドメイン'
    end

    context '未ログイン' do
      it_behaves_like 'スペースが0件'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'スペースが0件'
    end

    context '未ログイン' do
      it_behaves_like 'スペースが最大表示数と同じ'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'スペースが最大表示数と同じ'
    end

    context '未ログイン' do
      it_behaves_like 'スペースが最大表示数より多い'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'スペースが最大表示数より多い'
    end
  end
end
