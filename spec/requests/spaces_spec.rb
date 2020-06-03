require 'rails_helper'

RSpec.describe '/spaces', type: :request do
  # Space. As you add validations to Space, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) do
    skip('Add a hash of attributes valid for your model')
  end

  let(:invalid_attributes) do
    skip('Add a hash of attributes invalid for your model')
  end

  let!(:base_headers) { { 'Host' => Settings['base_domain'] } }
  let!(:json_headers) { { 'Content-Type' => 'application/json', 'Accept' => 'application/json' } }
  let!(:user) { FactoryBot.create(:user) }
  shared_context 'ログイン処理' do
    before { sign_in user }
  end

  describe 'GET /index' do
    shared_examples_for 'ベースドメイン' do
      it 'renders a successful response' do
        get spaces_url, headers: base_headers
        expect(response).to be_successful
      end
      it '(json)renders a successful response' do
        get spaces_url, headers: base_headers.merge(json_headers)
        expect(response).to be_successful
      end
    end
    shared_examples_for 'サブドメイン' do
      before do
        use_space = FactoryBot.create(:space)
        @space_headers = { 'Host' => "#{use_space.subdomain}.#{Settings['base_domain']}" }
      end
      it 'renders a redirect base_domain' do
        get spaces_url, headers: @space_headers
        expect(response).to redirect_to("//#{Settings['base_domain_link']}/spaces")
      end
      it '(json)renders a not found response' do
        get spaces_url, headers: @space_headers.merge(json_headers)
        expect(response).to be_not_found
      end
    end
    shared_examples_for '存在しないサブドメイン' do
      before do
        @space_headers = { 'Host' => "not.#{Settings['base_domain']}" }
      end
      it 'renders a redirect base_domain' do
        get spaces_url, headers: @space_headers
        expect(response).to redirect_to("//#{Settings['base_domain_link']}/spaces")
      end
      it '(json)renders a not found response' do
        get spaces_url, headers: @space_headers.merge(json_headers)
        expect(response).to be_not_found
      end
    end

    context '未ログイン' do
      it_behaves_like 'ベースドメイン'
      it_behaves_like 'サブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'ベースドメイン'
      it_behaves_like 'サブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
  end

  describe 'GET /index @spaces' do
    shared_context 'スペース作成' do |limit|
      before { @create_spaces = FactoryBot.create_list(:space, limit) }
    end

    shared_examples_for 'ベースドメイン、1ページ、1番新しいスペース' do
      it '名前が含まれる' do
        get spaces_url, headers: base_headers
        expect(response.body).to include(@create_spaces[@create_spaces.count - 1].name)
      end
      it 'パスが含まれる' do
        get spaces_url, headers: base_headers
        expect(response.body).to include("//#{@create_spaces[@create_spaces.count - 1].subdomain}.#{Settings['base_domain_link']}")
      end
      it '(json)名前が一致する' do
        get spaces_url, headers: base_headers.merge(json_headers)
        response_spaces = JSON.parse(response.body)['spaces']
        expect(response_spaces[0]['name']).to eq(@create_spaces[@create_spaces.count - 1].name)
      end
      it '(json)サブドメインが一致する' do
        get spaces_url, headers: base_headers.merge(json_headers)
        response_spaces = JSON.parse(response.body)['spaces']
        expect(response_spaces[0]['subdomain']).to eq(@create_spaces[@create_spaces.count - 1].subdomain)
      end
    end
    shared_examples_for "ベースドメイン、1ページ、#{Settings['default_spaces_limit']}番目に新しいスペース" do
      it '名前が含まれる' do
        get spaces_url, headers: base_headers
        expect(response.body).to include(@create_spaces[@create_spaces.count - Settings['default_spaces_limit']].name)
      end
      it 'パスが含まれる' do
        get spaces_url, headers: base_headers
        expect(response.body).to include("//#{@create_spaces[@create_spaces.count - Settings['default_spaces_limit']].subdomain}.#{Settings['base_domain_link']}")
      end
      it '(json)名前が一致する' do
        get spaces_url, headers: base_headers.merge(json_headers)
        response_spaces = JSON.parse(response.body)['spaces']
        expect(response_spaces[Settings['default_spaces_limit'] - 1]['name']).to eq(@create_spaces[@create_spaces.count - Settings['default_spaces_limit']].name)
      end
      it '(json)サブドメインが一致する' do
        get spaces_url, headers: base_headers.merge(json_headers)
        response_spaces = JSON.parse(response.body)['spaces']
        expect(response_spaces[Settings['default_spaces_limit'] - 1]['subdomain']).to eq(@create_spaces[@create_spaces.count - Settings['default_spaces_limit']].subdomain)
      end
    end
    shared_examples_for "ベースドメイン、1ページ、#{Settings['default_spaces_limit'] + 1}番目に新しいスペース" do
      it '名前が含まれない' do
        get spaces_url, headers: base_headers
        expect(response.body).not_to include(@create_spaces[@create_spaces.count - (Settings['default_spaces_limit'] + 1)].name)
      end
      it 'パスが含まれない' do
        get spaces_url, headers: base_headers
        expect(response.body).not_to include("//#{@create_spaces[@create_spaces.count - (Settings['default_spaces_limit'] + 1)].subdomain}.#{Settings['base_domain_link']}")
      end
    end
    shared_examples_for "ベースドメイン、2ページ、#{Settings['default_spaces_limit'] + 1}番目に新しいスペース" do
      it '名前が含まれる' do
        get spaces_url(page: 2), headers: base_headers
        expect(response.body).to include(@create_spaces[@create_spaces.count - (Settings['default_spaces_limit'] + 1)].name)
      end
      it 'パスが含まれる' do
        get spaces_url(page: 2), headers: base_headers
        expect(response.body).to include("//#{@create_spaces[@create_spaces.count - (Settings['default_spaces_limit'] + 1)].subdomain}.#{Settings['base_domain_link']}")
      end
      it '(json)名前が一致する' do
        get spaces_url(page: 2), headers: base_headers.merge(json_headers)
        response_spaces = JSON.parse(response.body)['spaces']
        expect(response_spaces[0]['name']).to eq(@create_spaces[@create_spaces.count - (Settings['default_spaces_limit'] + 1)].name)
      end
      it '(json)サブドメインが一致する' do
        get spaces_url(page: 2), headers: base_headers.merge(json_headers)
        response_spaces = JSON.parse(response.body)['spaces']
        expect(response_spaces[0]['subdomain']).to eq(@create_spaces[@create_spaces.count - (Settings['default_spaces_limit'] + 1)].subdomain)
      end
    end

    shared_examples_for 'ベースドメイン、スペースが最大数以下' do
      it '2ページ目のパスが含まれない' do
        get spaces_url, headers: base_headers
        expect(response.body).not_to include("\"#{spaces_path(page: 2)}\"")
      end
    end
    shared_examples_for 'ベースドメイン、スペースが最大表示数より多い' do
      it '2ページ目のパスが含まれる' do
        get spaces_url, headers: base_headers
        expect(response.body).to include("\"#{spaces_path(page: 2)}\"")
      end
    end

    shared_examples_for 'ベースドメイン' do
      it 'スペース作成のパスが含まれる' do
        get spaces_url, headers: base_headers
        expect(response.body).to include("\"#{new_space_path}\"")
      end
      it '(json)total_countが一致する' do
        get spaces_url, headers: base_headers.merge(json_headers)
        expect(JSON.parse(response.body)['total_count']).to eq(@create_spaces.count)
      end
      it '(json)1ページ、current_pageが一致する' do
        get spaces_url, headers: base_headers.merge(json_headers)
        expect(JSON.parse(response.body)['current_page']).to eq(1)
      end
      it '(json)2ページ、current_pageが一致する' do
        get spaces_url(page: 2), headers: base_headers.merge(json_headers)
        expect(JSON.parse(response.body)['current_page']).to eq(2)
      end
      it '(json)total_pagesが一致する' do
        get spaces_url, headers: base_headers.merge(json_headers)
        expect(JSON.parse(response.body)['total_pages']).to eq((@create_spaces.count - 1).div(Settings['default_spaces_limit']) + 1)
      end
      it '(json)limit_valueが一致する' do
        get spaces_url, headers: base_headers.merge(json_headers)
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

  describe 'GET /show' do
    it 'renders a successful response' do
      space = Space.create! valid_attributes
      get space_url(space)
      expect(response).to be_successful
    end
  end

  describe 'GET /new' do
    it 'renders a successful response' do
      get new_space_url
      expect(response).to be_successful
    end
  end

  describe 'GET /edit' do
    it 'render a successful response' do
      space = Space.create! valid_attributes
      get edit_space_url(space)
      expect(response).to be_successful
    end
  end

  describe 'POST /create' do
    context 'with valid parameters' do
      it 'creates a new Space' do
        expect do
          post spaces_url, params: { space: valid_attributes }
        end.to change(Space, :count).by(1)
      end

      it 'redirects to the created space' do
        post spaces_url, params: { space: valid_attributes }
        expect(response).to redirect_to(space_url(Space.last))
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new Space' do
        expect do
          post spaces_url, params: { space: invalid_attributes }
        end.to change(Space, :count).by(0)
      end

      it "renders a successful response (i.e. to display the 'new' template)" do
        post spaces_url, params: { space: invalid_attributes }
        expect(response).to be_successful
      end
    end
  end

  describe 'PATCH /update' do
    context 'with valid parameters' do
      let(:new_attributes) do
        skip('Add a hash of attributes valid for your model')
      end

      it 'updates the requested space' do
        space = Space.create! valid_attributes
        patch space_url(space), params: { space: new_attributes }
        space.reload
        skip('Add assertions for updated state')
      end

      it 'redirects to the space' do
        space = Space.create! valid_attributes
        patch space_url(space), params: { space: new_attributes }
        space.reload
        expect(response).to redirect_to(space_url(space))
      end
    end

    context 'with invalid parameters' do
      it "renders a successful response (i.e. to display the 'edit' template)" do
        space = Space.create! valid_attributes
        patch space_url(space), params: { space: invalid_attributes }
        expect(response).to be_successful
      end
    end
  end

  describe 'DELETE /destroy' do
    it 'destroys the requested space' do
      space = Space.create! valid_attributes
      expect do
        delete space_url(space)
      end.to change(Space, :count).by(-1)
    end

    it 'redirects to the spaces list' do
      space = Space.create! valid_attributes
      delete space_url(space)
      expect(response).to redirect_to(spaces_url)
    end
  end
end
