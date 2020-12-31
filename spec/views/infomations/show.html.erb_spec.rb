require 'rails_helper'

RSpec.describe 'infomations/show', type: :view do
  before(:each) do
    @infomation = assign(:infomation, Infomation.create!(
                                        title: 'Title',
                                        body: 'MyText',
                                        target: 2,
                                        user: nil
                                      ))
  end

  it 'renders attributes in <p>' do
    render
    expect(rendered).to match(/Title/)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(//)
  end
end
