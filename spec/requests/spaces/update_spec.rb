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
  let!(:customer) { FactoryBot.create(:customer) }

  shared_context '存在するサブドメイン作成' do
    before do
      @request_space = FactoryBot.create(:space, customer_id: customer.id)
      @space_headers = { 'Host' => "#{@request_space.subdomain}.#{Settings['base_domain']}" }
    end
  end
  shared_context '存在しないサブドメイン作成' do
    before { @space_headers = { 'Host' => "not.#{Settings['base_domain']}" } }
  end

  # PATCH/PUT /spaces/update（サブドメイン） スペース更新(処理)
  # PATCH/PUT /spaces/update.json（サブドメイン） スペース更新API
  describe 'PATCH /update' do
    shared_examples_for '有効なパラメータ' do
      it '更新に成功' do
        patch space_path, params: { space: valid_attributes }, headers: @space_headers
        expect(Space.last.subdomain).to eq(valid_attributes[:subdomain])
      end
      it '更新したスペースのトップページ（サブドメイン）にリダイレクト' do
        patch space_path, params: { space: valid_attributes }, headers: @space_headers
        expect(response).to redirect_to("//#{Space.last.subdomain}.#{Settings['base_domain']}")
      end
      it '(json)renders a ok(200) response' do
        patch space_path, params: valid_attributes, as: :json, headers: @space_headers.merge(json_headers)
        expect(response).to be_ok
      end
      it '(json)エラー件数が0と一致' do
        patch space_path, params: valid_attributes, as: :json, headers: @space_headers.merge(json_headers)
        expect(JSON.parse(response.body)['error_count']).to eq(0)
      end
      it '(json)エラーメッセージの項目が存在しない' do
        patch space_path, params: valid_attributes, as: :json, headers: @space_headers.merge(json_headers)
        expect(JSON.parse(response.body)['errors'].present?).to eq(false)
      end
    end
    shared_examples_for '無効なパラメータ' do
      it '更新に失敗' do
        patch space_path, params: { space: invalid_attributes }, headers: @space_headers
        expect(Space.find(@request_space.id).subdomain).not_to be_nil
      end
      it 'renders a successful response' do
        patch space_path, params: { space: invalid_attributes }, headers: @space_headers
        expect(response).to be_successful
      end
      it '(json)renders a unprocessable(422) response' do
        patch space_path, params: invalid_attributes, as: :json, headers: @space_headers.merge(json_headers)
        expect(response).to be_unprocessable
      end
      it '(json)エラー件数が1と一致' do
        patch space_path, params: invalid_attributes, as: :json, headers: @space_headers.merge(json_headers)
        expect(JSON.parse(response.body)['error_count']).to eq(1)
      end
      it '(json)エラーメッセージの項目が存在する' do
        patch space_path, params: invalid_attributes, as: :json, headers: @space_headers.merge(json_headers)
        expect(JSON.parse(response.body)['errors'].present?).to eq(true)
      end
    end

    shared_examples_for 'ベースドメイン' do
      it 'renders a not found response' do
        patch space_path, headers: base_headers
        expect(response).to be_not_found
      end
      it '(json)renders a not found response' do
        patch space_path, as: :json, headers: base_headers.merge(json_headers)
        expect(response).to be_not_found
      end
    end
    shared_examples_for '存在するサブドメイン' do
      include_context '存在するサブドメイン作成'
      it_behaves_like '有効なパラメータ'
      it_behaves_like '無効なパラメータ'
    end
    shared_examples_for '存在しないサブドメイン' do
      include_context '存在しないサブドメイン作成'
      it 'renders a not found response' do
        patch space_path, headers: @space_headers
        expect(response).to be_not_found
      end
      it '(json)renders a not found response' do
        patch space_path, as: :json, headers: @space_headers.merge(json_headers)
        expect(response).to be_not_found
      end
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
