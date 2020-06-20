require 'rails_helper'

RSpec.describe AdminUsers::ConfirmationsController, type: :routing do
  describe 'routing' do
    it 'routes to #new' do
      # expect(get: '/admin_users/confirmation/new').to route_to('admin_users/confirmations#new')
      expect(get: '/admin_users/confirmation/new').not_to be_routable
    end
    it 'routes to #create' do
      # expect(post: '/admin_users/confirmation').to route_to('admin_users/confirmations#create')
      expect(post: '/admin_users/confirmation').not_to be_routable
    end
    it 'routes to #show' do
      # expect(get: '/admin_users/confirmation').to route_to('admin_users/confirmations#show')
      expect(get: '/admin_users/confirmation').not_to be_routable
    end
  end
end
