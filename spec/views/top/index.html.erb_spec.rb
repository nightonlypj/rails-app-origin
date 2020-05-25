require 'rails_helper'

RSpec.describe 'top/index', type: :view do
  let!(:user) { FactoryBot.create(:user) }

  context '未ログイン' do
    it 'Hello World!が含まれる' do
      render
      expect(rendered).to match('Hello World!')
    end
  end

  context 'ログイン中' do
    before do
      login_user user
    end
    it 'Hello World!が含まれる' do
      render
      expect(rendered).to match('Hello World!')
    end
  end
end
