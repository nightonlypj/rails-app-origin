require 'rails_helper'

RSpec.describe AdminUsers::UnlocksController, type: :routing do
  describe 'routing' do
    it 'routes to #new' do
      expect(get: '/admin_users/unlock/new').to route_to('admin_users/unlocks#new')
    end
    it 'routes to #create' do
      expect(post: '/admin_users/unlock').to route_to('admin_users/unlocks#create')
    end
    it 'routes to #show' do
      expect(get: '/admin_users/unlock').to route_to('admin_users/unlocks#show')
    end
  end
end
