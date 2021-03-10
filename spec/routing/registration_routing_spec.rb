require 'rails_helper'

RSpec.describe RegistrationController, type: :routing do
  describe 'routing' do
    it 'routes to #new' do
      expect(get: '/registration/member').to route_to('registration#new')
    end
    it 'routes to #create' do
      expect(post: '/registration/member').to route_to('registration#create')
    end
  end
end
