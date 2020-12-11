require 'rails_helper'

RSpec.describe 'Spaces', type: :request do
  let!(:base_headers) { { 'Host' => Settings['base_domain'] } }
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

  # GET /spaces/edit（サブドメイン） スペース編集
  describe 'GET /edit' do
    shared_examples_for 'ベースドメイン' do
      it 'renders a not found response' do
        get edit_space_path, headers: base_headers
        expect(response).to be_not_found
      end
    end
    shared_examples_for '存在するサブドメイン' do
      include_context '存在するサブドメイン作成'
      it 'renders a successful response' do
        get edit_space_path, headers: @space_headers
        expect(response).to be_successful
      end
    end
    shared_examples_for '存在しないサブドメイン' do
      include_context '存在しないサブドメイン作成'
      it 'renders a not found response' do
        get edit_space_path, headers: @space_headers
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
