require 'rails_helper'

RSpec.describe Users::Auth::ConfirmationsController, type: :routing do
  describe 'routing' do
    it 'routes to #new' do
      # expect(get: '/users/auth/confirmation/new').to route_to('users/auth/confirmations#new')
      expect(get: '/users/auth/confirmation/new').not_to be_routable
    end
    it 'routes to #create' do
      expect(post: '/users/auth/confirmation').to route_to('users/auth/confirmations#create')
      expect(post: '/users/auth/confirmation.json').to route_to('users/auth/confirmations#create', format: 'json')
    end
    it 'routes to #show' do
      expect(get: '/users/auth/confirmation').to route_to('users/auth/confirmations#show')
      expect(get: '/users/auth/confirmation.json').to route_to('users/auth/confirmations#show', format: 'json')
    end
  end
end
