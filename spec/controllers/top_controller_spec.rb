require 'rails_helper'

RSpec.describe TopController, type: :controller do
  let!(:user) { create(:user) }

  describe 'GET #index' do
    context '未ログイン' do
      it 'returns a success response' do
        get :index
        expect(response).to be_successful
      end
      it 'use index template' do
        get :index
        should render_template('index')
      end
    end

    context 'ログイン中' do
      before do
        login_user user
      end
      it 'returns a success response' do
        get :index
        expect(response).to be_successful
      end
      it 'use index template' do
        get :index
        should render_template('index')
      end
    end
  end
end
