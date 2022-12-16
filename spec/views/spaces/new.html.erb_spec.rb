require 'rails_helper'

RSpec.describe 'spaces/new', type: :view do
  before_all do
    @space = Space.new
  end

  it '対象の送信先と項目が含まれる' do
    render
    assert_select 'form[action=?][method=?]', create_space_path, 'post' do
      assert_select 'input[name=?]', 'space[name]'
      assert_select 'textarea[name=?]', 'space[description]'
      assert_select 'input[name=?]', 'space[private]' if Settings['enable_public_space']
      assert_select 'input[name=?]', 'space[image]'
      assert_select 'input[type=?]', 'button'
    end
  end
end
