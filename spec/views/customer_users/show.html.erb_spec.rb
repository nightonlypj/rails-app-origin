require 'rails_helper'

RSpec.describe 'customer_users/show', type: :view do
  before(:each) do
    @customer_user = assign(:customer_user, CustomerUser.create!(
                                              customer: nil,
                                              user: nil,
                                              power: 2
                                            ))
  end

  it 'renders attributes in <p>' do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(/2/)
  end
end
