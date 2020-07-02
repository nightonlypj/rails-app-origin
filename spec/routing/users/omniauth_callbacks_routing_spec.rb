require 'rails_helper'

RSpec.describe Users::OmniauthCallbacksController, type: :routing do
  describe 'routing' do
    it 'routes to #passthru' do
      # expect(get: '/users/auth/twitter').to route_to('users/omniauth_callbacks#passthru')
      # expect(post: '/users/auth/twitter').to route_to('users/omniauth_callbacks#passthru')
      expect(get: '/users/auth/twitter').not_to be_routable
      expect(post: '/users/auth/twitter').not_to be_routable
    end
    it 'routes to #failure' do
      # expect(get: '/users/auth/twitter/callback').to route_to('users/omniauth_callbacks#failure')
      # expect(post: '/users/auth/twitter/callback').to route_to('users/omniauth_callbacks#failure')
      expect(get: '/users/auth/twitter/callback').not_to be_routable
      expect(post: '/users/auth/twitter/callback').not_to be_routable
    end
  end
end
