require 'rails_helper'

RSpec.describe 'Top', type: :request do
  let!(:base_headers) { { 'Host' => Settings['base_domain'] } }
  let!(:user) { FactoryBot.create(:user) }
  shared_context 'ログイン処理' do
    before { sign_in user }
  end

  # GET /（ベースドメイン） トップページ
  # GET /（サブドメイン） スペーストップ
  describe 'GET /' do
    shared_examples_for 'ベースドメイン' do
      it 'renders a successful response' do
        get root_path, headers: base_headers
        expect(response).to be_successful
      end
    end
    shared_examples_for 'サブドメイン' do
      it 'renders a successful response' do
        request_space = FactoryBot.create(:space)
        space_headers = { 'Host' => "#{request_space.subdomain}.#{Settings['base_domain']}" }
        get root_path, headers: space_headers
        expect(response).to be_successful
      end
    end
    shared_examples_for '存在しないサブドメイン' do
      it 'renders a not found response' do
        space_headers = { 'Host' => "not.#{Settings['base_domain']}" }
        get root_path, headers: space_headers
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

  describe 'GET / @new_spaces' do
    shared_context 'スペース作成' do |limit|
      before { @create_spaces = FactoryBot.create_list(:space, limit) }
    end

    shared_examples_for 'ベースドメイン、1番新しいスペース' do
      it '名前が含まれる' do
        get root_path, headers: base_headers
        expect(response.body).to include(@create_spaces[@create_spaces.count - 1].name)
      end
      it 'パスが含まれる' do
        get root_path, headers: base_headers
        expect(response.body).to include("//#{@create_spaces[@create_spaces.count - 1].subdomain}.#{Settings['base_domain']}")
      end
    end
    shared_examples_for "ベースドメイン、#{Settings['new_spaces_limit']}番目に新しいスペース" do
      it '名前が含まれる' do
        get root_path, headers: base_headers
        expect(response.body).to include(@create_spaces[@create_spaces.count - Settings['new_spaces_limit']].name)
      end
      it 'パスが含まれる' do
        get root_path, headers: base_headers
        expect(response.body).to include("//#{@create_spaces[@create_spaces.count - Settings['new_spaces_limit']].subdomain}.#{Settings['base_domain']}")
      end
    end
    shared_examples_for "ベースドメイン、#{Settings['new_spaces_limit'] + 1}番目に新しいスペース" do
      it '名前が含まれない' do
        get root_path, headers: base_headers
        expect(response.body).not_to include(@create_spaces[@create_spaces.count - (Settings['new_spaces_limit'] + 1)].name)
      end
      it 'パスが含まれない' do
        get root_path, headers: base_headers
        expect(response.body).not_to include("//#{@create_spaces[@create_spaces.count - (Settings['new_spaces_limit'] + 1)].subdomain}.#{Settings['base_domain']}")
      end
    end

    shared_examples_for 'ベースドメイン、スペースがない' do
      it 'ベースドメイン、もっと見るのパスが含まれない' do
        get root_path, headers: base_headers
        expect(response.body).not_to include("\"#{spaces_path}\"")
      end
    end
    shared_examples_for 'ベースドメイン、スペースがある' do
      it 'ベースドメイン、もっと見るのパスが含まれる' do
        get root_path, headers: base_headers
        expect(response.body).to include("\"#{spaces_path}\"")
      end
    end

    shared_examples_for 'ベースドメイン' do
      it 'スペース作成のパスが含まれる' do
        get root_path, headers: base_headers
        expect(response.body).to include("\"#{new_space_path}\"")
      end
    end

    shared_examples_for 'スペースが0件' do
      it_behaves_like 'ベースドメイン、スペースがない'
      it_behaves_like 'ベースドメイン'
    end
    shared_examples_for 'スペースが最大表示数と同じ' do
      include_context 'スペース作成', Settings['new_spaces_limit']
      it_behaves_like 'ベースドメイン、1番新しいスペース'
      it_behaves_like "ベースドメイン、#{Settings['new_spaces_limit']}番目に新しいスペース"
      it_behaves_like 'ベースドメイン、スペースがある'
      it_behaves_like 'ベースドメイン'
    end
    shared_examples_for 'スペースが最大表示数より多い' do
      include_context 'スペース作成', Settings['new_spaces_limit'] + 1
      it_behaves_like 'ベースドメイン、1番新しいスペース'
      it_behaves_like "ベースドメイン、#{Settings['new_spaces_limit']}番目に新しいスペース"
      it_behaves_like "ベースドメイン、#{Settings['new_spaces_limit'] + 1}番目に新しいスペース"
      it_behaves_like 'ベースドメイン、スペースがある'
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
