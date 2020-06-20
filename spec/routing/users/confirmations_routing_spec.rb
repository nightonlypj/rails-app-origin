require 'rails_helper'

RSpec.describe Users::ConfirmationsController, type: :routing do
  describe 'routing' do
    it 'routes to #new' do
      expect(get: '/users/confirmation/new').to route_to('users/confirmations#new')
    end
    it 'routes to #create' do
      expect(post: '/users/confirmation').to route_to('users/confirmations#create')
    end
    it 'routes to #show' do
      expect(get: '/users/confirmation').to route_to('users/confirmations#show')
    end
  end
end
