require 'rails_helper'

RSpec.describe 'members/show', type: :view do
  before(:each) do
    @member = assign(:member, Member.create!(
                                space: nil,
                                user: nil
                              ))
  end

  it 'renders attributes in <p>' do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(//)
  end
end
