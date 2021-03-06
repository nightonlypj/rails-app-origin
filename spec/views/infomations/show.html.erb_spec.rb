require 'rails_helper'

RSpec.describe 'infomations/show', type: :view do
  before { @infomation = FactoryBot.create(:infomation) }

  context do
    it '対象のパスが含まれる' do
      render
      expect(rendered).to include("href=\"#{infomations_path}\"") # お知らせ一覧
    end
  end
end
