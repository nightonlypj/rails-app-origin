require 'rails_helper'

RSpec.describe 'top/index_subdomain', type: :view do
  let!(:user) { FactoryBot.create(:user) }

  context '未ログイン' do
    it 'Welcome!が含まれる' do
      render
      expect(rendered).to match('Welcome!')
    end
  end

  context 'ログイン中' do
    before do
      login_user user
    end
    it 'Welcome!が含まれる' do
      render
      expect(rendered).to match('Welcome!')
    end
  end
end
