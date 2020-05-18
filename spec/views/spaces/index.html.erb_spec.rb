require 'rails_helper'

RSpec.describe "spaces/index", type: :view do
  before(:each) do
    assign(:spaces, [
      Space.create!(
        subdomain: "Subdomain",
        name: "Name"
      ),
      Space.create!(
        subdomain: "Subdomain",
        name: "Name"
      )
    ])
  end

  it "renders a list of spaces" do
    render
    assert_select "tr>td", text: "Subdomain".to_s, count: 2
    assert_select "tr>td", text: "Name".to_s, count: 2
  end
end
