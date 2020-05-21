require 'rails_helper'

RSpec.describe 'Top', type: :request do
  let!(:user) { create(:user) }

  describe 'GET #index' do
    context '未ログイン' do
      it 'renders a successful response' do
        get root_path
        expect(response).to be_successful
      end
      it 'use index template' do
        get root_path
        should render_template('index')
      end
    end

    context 'ログイン中' do
      before do
        sign_in user
      end
      it 'renders a successful response' do
        get root_path
        expect(response).to be_successful
      end
      it 'use index template' do
        get root_path
        should render_template('index')
      end
    end
  end
end
