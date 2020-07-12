require 'rails_helper'

RSpec.describe 'Spaces', type: :request do
  let!(:valid_attributes) { FactoryBot.attributes_for(:space) }
  let!(:invalid_attributes) { FactoryBot.attributes_for(:space, subdomain: nil) }
  let!(:base_headers) { { 'Host' => Settings['base_domain'] } }
  let!(:json_headers) { { 'Content-Type' => 'application/json', 'Accept' => 'application/json' } }
  let!(:user) { FactoryBot.create(:user) }
  shared_context 'ログイン処理' do
    before { sign_in user }
  end

  shared_context '存在するサブドメイン作成' do
    before do
      request_space = FactoryBot.create(:space)
      @space_headers = { 'Host' => "#{request_space.subdomain}.#{Settings['base_domain']}" }
    end
  end
  shared_context '存在しないサブドメイン作成' do
    before { @space_headers = { 'Host' => "not.#{Settings['base_domain']}" } }
  end

  # POST /spaces/create（ベースドメイン） スペース登録(処理)
  # POST /spaces/create.json（ベースドメイン） スペース登録API
  describe 'POST /create' do
    shared_examples_for '有効なパラメータ' do
      it '作成に成功' do
        expect do
          post create_space_url, params: { space: valid_attributes }, headers: base_headers
        end.to change(Space, :count).by(1)
      end
      it '作成したスペースのトップページ（サブドメイン）にリダイレクト' do
        post create_space_url, params: { space: valid_attributes }, headers: base_headers
        expect(response).to redirect_to("//#{Space.last.subdomain}.#{Settings['base_domain_link']}")
      end
      it '(json)renders a created(201) response' do
        post create_space_url, params: valid_attributes, as: :json, headers: base_headers.merge(json_headers)
        expect(response).to be_created
      end
      it '(json)エラー件数が0と一致' do
        post create_space_url, params: valid_attributes, as: :json, headers: base_headers.merge(json_headers)
        expect(JSON.parse(response.body)['error_count']).to eq(0)
      end
      it '(json)エラーメッセージの項目が存在しない' do
        post create_space_url, params: valid_attributes, as: :json, headers: base_headers.merge(json_headers)
        expect(JSON.parse(response.body)['errors'].present?).to eq(false)
      end
    end
    shared_examples_for '無効なパラメータ' do
      it '作成に失敗' do
        expect do
          post create_space_url, params: { space: invalid_attributes }, headers: base_headers
        end.to change(Space, :count).by(0)
      end
      it 'renders a successful response' do
        post create_space_url, params: { space: invalid_attributes }, headers: base_headers
        expect(response).to be_successful
      end
      it '(json)renders a unprocessable(422) response' do
        post create_space_url, params: invalid_attributes, as: :json, headers: base_headers.merge(json_headers)
        expect(response).to be_unprocessable
      end
      it '(json)エラー件数が1と一致' do
        post create_space_url, params: invalid_attributes, as: :json, headers: base_headers.merge(json_headers)
        expect(JSON.parse(response.body)['error_count']).to eq(1)
      end
      it '(json)エラーメッセージの項目が存在する' do
        post create_space_url, params: invalid_attributes, as: :json, headers: base_headers.merge(json_headers)
        expect(JSON.parse(response.body)['errors'].present?).to eq(true)
      end
    end

    shared_examples_for 'ベースドメイン' do
      it_behaves_like '有効なパラメータ'
      it_behaves_like '無効なパラメータ'
    end
    shared_examples_for 'サブドメイン' do
      it 'スペース作成（ベースドメイン）にリダイレクト' do
        post create_space_url, params: { space: valid_attributes }, headers: @space_headers
        expect(response).to redirect_to("//#{Settings['base_domain_link']}#{new_space_path}")
      end
      it '(json)renders a not found response' do
        post create_space_url, params: valid_attributes, as: :json, headers: @space_headers.merge(json_headers)
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
end
