require 'rails_helper'

RSpec.describe 'top/index', type: :view do
  let!(:user) { FactoryBot.create(:user) }
  shared_context 'login' do
    before { login_user user }
  end

  shared_examples_for 'common' do
    it 'Hello World!が含まれる' do
      render
      expect(rendered).to match('Hello World!')
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
