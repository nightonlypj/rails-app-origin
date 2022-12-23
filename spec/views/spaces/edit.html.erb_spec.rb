require 'rails_helper'

RSpec.describe 'spaces/edit', type: :view do
  before_all { @space = FactoryBot.create(:space) }

  it '対象の送信先と項目が含まれる' do
    render
    assert_select 'form[action=?][method=?]', update_space_path(@space.code), 'post' do
      assert_select 'input[name=?]', 'space[name]'
      assert_select 'textarea[name=?]', 'space[description]'
      assert_select 'input[name=?]', 'space[private]' if Settings['enable_public_space']
      assert_select 'input[name=?]', 'space[image]'
      assert_select 'input[type=?]', 'button'
    end
  end
end
