require 'rails_helper'

RSpec.describe 'infomations/new', type: :view do
  before(:each) do
    assign(:infomation, Infomation.new(
                          title: 'MyString',
                          body: 'MyText',
                          target: 1,
                          user: nil
                        ))
  end

  it 'renders new infomation form' do
    render

    assert_select 'form[action=?][method=?]', infomations_path, 'post' do
      assert_select 'input[name=?]', 'infomation[title]'

      assert_select 'textarea[name=?]', 'infomation[body]'

      assert_select 'input[name=?]', 'infomation[target]'

      assert_select 'input[name=?]', 'infomation[user_id]'
    end
  end
end
