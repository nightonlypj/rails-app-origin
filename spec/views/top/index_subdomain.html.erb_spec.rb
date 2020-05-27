require 'rails_helper'

RSpec.describe 'top/index_subdomain', type: :view do
  let!(:user) { FactoryBot.create(:user) }
  shared_context 'login' do
    before { login_user user }
  end

  shared_examples_for 'common' do
    it 'Welcome!が含まれる' do
      render
      expect(rendered).to match('Welcome!')
    end
  end

  context '未ログイン' do
    it_behaves_like 'common'
  end

  context 'ログイン中' do
    include_context 'login'
    it_behaves_like 'common'
  end
end
