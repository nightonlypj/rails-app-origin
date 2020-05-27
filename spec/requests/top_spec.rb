require 'rails_helper'

RSpec.describe 'Top', type: :request do
  let!(:user) { FactoryBot.create(:user) }
  shared_context 'sign_in' do
    before { sign_in user }
  end

  let!(:use_space) { FactoryBot.create(:space) }
  let!(:header_hash) { { 'Host' => Settings['base_domain'] } }
  let!(:space_header_hash) { { 'Host' => "#{use_space.subdomain}.#{Settings['base_domain']}" } }

  describe 'GET #index' do
    shared_context 'ベースドメイン' do
      it 'renders a successful response' do
        get root_path, headers: header_hash
        expect(response).to be_successful
      end
      it 'use index template' do
        get root_path, headers: header_hash
        should render_template('index')
      end
      space_limit = 10
      it "新しいスペースが#{space_limit}件取得できる" do
        FactoryBot.create_list(:space, space_limit + 1)
        new_spaces = Space.all.order(id: 'DESC').limit(space_limit)
        get root_path, headers: header_hash
        expect(assigns(:new_spaces)).to match_array new_spaces
      end
    end

    context '未ログイン' do
      it_behaves_like 'ベースドメイン'
    end

    context 'ログイン中' do
      include_context 'sign_in'
      it_behaves_like 'ベースドメイン'
    end

    shared_context 'サブドメイン' do
      it 'renders a successful response' do
        get root_path, headers: space_header_hash
        expect(response).to be_successful
      end
      it 'use index_subdomain template' do
        get root_path, headers: space_header_hash
        should render_template('index_subdomain')
      end
    end

    context '未ログイン' do
      it_behaves_like 'サブドメイン'
    end

    context 'ログイン中' do
      include_context 'sign_in'
      it_behaves_like 'サブドメイン'
    end
  end
end
