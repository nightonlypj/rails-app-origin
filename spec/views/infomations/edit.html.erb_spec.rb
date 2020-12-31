require 'rails_helper'

RSpec.describe 'infomations/edit', type: :view do
  before(:each) do
    @infomation = assign(:infomation, Infomation.create!(
                                        title: 'MyString',
                                        body: 'MyText',
                                        target: 1,
                                        user: nil
                                      ))
  end

  it 'renders the edit infomation form' do
    render

    assert_select 'form[action=?][method=?]', infomation_path(@infomation), 'post' do
      assert_select 'input[name=?]', 'infomation[title]'

      assert_select 'textarea[name=?]', 'infomation[body]'

      assert_select 'input[name=?]', 'infomation[target]'

      assert_select 'input[name=?]', 'infomation[user_id]'
    end
  end
end
