require 'rails_helper'

RSpec.describe Users::Auth::UnlocksController, type: :routing do
  describe 'routing' do
    it 'routes to #new' do
      # expect(get: '/users/auth/unlock/new').to route_to('users/auth/unlocks#new')
      expect(get: '/users/auth/unlock/new').not_to be_routable
    end
    it 'routes to #create' do
      expect(post: '/users/auth/unlock').to route_to('users/auth/unlocks#create')
    end
    it 'routes to #show' do
      expect(get: '/users/auth/unlock').to route_to('users/auth/unlocks#show')
    end
  end
end
