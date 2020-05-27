require 'rails_helper'

RSpec.describe 'Top', type: :request do
  let!(:user) { FactoryBot.create(:user) }
  let!(:use_space) { FactoryBot.create(:space) }
  let!(:header_hash) { { 'Host' => Settings['base_domain'] } }
  let!(:space_header_hash) { { 'Host' => "#{use_space.subdomain}.#{Settings['base_domain']}" } }

  describe 'GET #index' do
    context '未ログイン' do
      it 'renders a successful response' do
        get root_path, headers: header_hash
        expect(response).to be_successful
      end
      it 'use index template' do
        get root_path, headers: header_hash
        should render_template('index')
      end
    end

    context 'ログイン中' do
      before do
        sign_in user
      end
      it 'renders a successful response' do
        get root_path, headers: header_hash
        expect(response).to be_successful
      end
      it 'use index template' do
        get root_path, headers: header_hash
        should render_template('index')
      end
    end

    context 'サブドメイン' do
      it 'renders a successful response' do
        get root_path, headers: space_header_hash
        expect(response).to be_successful
      end
      it 'use index_subdomain template' do
        get root_path, headers: space_header_hash
        should render_template('index_subdomain')
      end
    end
  end
end
