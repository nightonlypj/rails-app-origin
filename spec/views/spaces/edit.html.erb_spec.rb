require 'rails_helper'

RSpec.describe "spaces/edit", type: :view do
  before(:each) do
    @space = assign(:space, Space.create!(
      subdomain: "MyString",
      name: "MyString"
    ))
  end

  it "renders the edit space form" do
    render

    assert_select "form[action=?][method=?]", space_path(@space), "post" do

      assert_select "input[name=?]", "space[subdomain]"

      assert_select "input[name=?]", "space[name]"
    end
  end
end
