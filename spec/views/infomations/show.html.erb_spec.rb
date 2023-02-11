require 'rails_helper'

RSpec.describe 'infomations/show', type: :view do
  next if Settings.api_only_mode

  before_all { @infomation = FactoryBot.create(:infomation) }

  context do
    it '対象のパスが含まれる' do
      render
      expect(rendered).to include("href=\"#{infomations_path}\"") # お知らせ一覧
    end
  end
end
