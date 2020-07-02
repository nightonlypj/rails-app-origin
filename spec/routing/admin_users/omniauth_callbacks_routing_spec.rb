require 'rails_helper'

RSpec.describe AdminUsers::OmniauthCallbacksController, type: :routing do
  describe 'routing' do
    it 'routes to #passthru' do
      # expect(get: '/admin_users/auth/twitter').to route_to('admin_users/omniauth_callbacks#passthru')
      # expect(post: '/admin_users/auth/twitter').to route_to('admin_users/omniauth_callbacks#passthru')
      expect(get: '/admin_users/auth/twitter').not_to be_routable
      expect(post: '/admin_users/auth/twitter').not_to be_routable
    end
    it 'routes to #failure' do
      # expect(get: '/admin_users/auth/twitter/callback').to route_to('admin_users/omniauth_callbacks#failure')
      # expect(post: '/admin_users/auth/twitter/callback').to route_to('admin_users/omniauth_callbacks#failure')
      expect(get: '/admin_users/auth/twitter/callback').not_to be_routable
      expect(post: '/admin_users/auth/twitter/callback').not_to be_routable
    end
  end
end
