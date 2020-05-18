require 'rails_helper'

RSpec.describe "spaces/new", type: :view do
  before(:each) do
    assign(:space, Space.new(
      subdomain: "MyString",
      name: "MyString"
    ))
  end

  it "renders new space form" do
    render

    assert_select "form[action=?][method=?]", spaces_path, "post" do

      assert_select "input[name=?]", "space[subdomain]"

      assert_select "input[name=?]", "space[name]"
    end
  end
end
