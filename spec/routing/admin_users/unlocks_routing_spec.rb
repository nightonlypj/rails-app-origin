require 'rails_helper'

RSpec.describe AdminUsers::UnlocksController, type: :routing do
  describe 'routing' do
    it 'routes to #new' do
      # expect(get: '/admin_users/unlock/new').to route_to('admin_users/unlocks#new')
      expect(get: '/admin_users/unlock/new').not_to be_routable
      expect(get: '/admin/unlock/resend').to route_to('admin_users/unlocks#new')
    end
    it 'routes to #create' do
      # expect(post: '/admin_users/unlock').to route_to('admin_users/unlocks#create')
      expect(post: '/admin_users/unlock').not_to be_routable
      expect(post: '/admin_users/unlock/new').not_to be_routable
      # expect(post: '/admin/unlock').not_to be_routable # Tips: rails_admin/main#index
      expect(post: '/admin/unlock/resend').to route_to('admin_users/unlocks#create')
    end
    it 'routes to #show' do
      # expect(get: '/admin_users/unlock').to route_to('admin_users/unlocks#show')
      expect(get: '/admin_users/unlock').not_to be_routable
      expect(get: '/admin/unlock').to route_to('admin_users/unlocks#show')
    end
  end
end
