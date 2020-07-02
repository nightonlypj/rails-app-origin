require 'rails_helper'

RSpec.describe Users::UnlocksController, type: :routing do
  describe 'routing' do
    it 'routes to #new' do
      expect(get: '/users/unlock/new').to route_to('users/unlocks#new')
    end
    it 'routes to #create' do
      expect(post: '/users/unlock').to route_to('users/unlocks#create')
    end
    it 'routes to #show' do
      expect(get: '/users/unlock').to route_to('users/unlocks#show')
    end
  end
end
