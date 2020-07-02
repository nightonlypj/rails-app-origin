require 'rails_helper'

RSpec.describe 'top/index', type: :view do
  let!(:user) { FactoryBot.create(:user) }
  shared_context 'ログイン処理' do
    before { login_user user }
  end

  shared_examples_for 'レスポンス' do
    it 'Hello World!が含まれる' do
      render
      expect(rendered).to include('Hello World!')
    end
  end

  context '未ログイン' do
    it_behaves_like 'レスポンス'
  end
  context 'ログイン中' do
    include_context 'ログイン処理'
    it_behaves_like 'レスポンス'
  end
end
