require 'rails_helper'

RSpec.describe 'members/index', type: :view do
  before(:each) do
    assign(:members, [
             Member.create!(
               space: nil,
               user: nil
             ),
             Member.create!(
               space: nil,
               user: nil
             )
           ])
  end

  it 'renders a list of members' do
    render
    assert_select 'tr>td', text: nil.to_s, count: 2
    assert_select 'tr>td', text: nil.to_s, count: 2
  end
end
