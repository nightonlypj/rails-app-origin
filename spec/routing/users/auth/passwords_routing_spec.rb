require 'rails_helper'

RSpec.describe Users::Auth::PasswordsController, type: :routing do
  describe 'routing' do
    it 'routes to #new' do
      # expect(get: '/users/auth/password/new').to route_to('users/auth/passwords#new')
      expect(get: '/users/auth/password/new').not_to be_routable
    end
    it 'routes to #new' do
      expect(post: '/users/auth/password').to route_to('users/auth/passwords#create')
      expect(post: '/users/auth/password.json').to route_to('users/auth/passwords#create', format: 'json')
    end
    it 'routes to #edit' do
      # expect(get: '/users/auth/password/edit').to route_to('users/auth/passwords#edit')
      expect(get: '/users/auth/password/edit').not_to be_routable
      expect(get: '/users/auth/password').to route_to('users/auth/passwords#edit')
      expect(get: '/users/auth/password.json').to route_to('users/auth/passwords#edit', format: 'json')
    end
    it 'routes to #update' do
      # expect(put: '/users/auth/password').to route_to('users/auth/passwords#update')
      # expect(patch: '/users/auth/password').to route_to('users/auth/passwords#update')
      expect(put: '/users/auth/password').not_to be_routable
      expect(patch: '/users/auth/password').not_to be_routable
      expect(put: '/users/auth/password/update').to route_to('users/auth/passwords#update')
      expect(patch: '/users/auth/password/update').to route_to('users/auth/passwords#update')
      expect(put: '/users/auth/password/update.json').to route_to('users/auth/passwords#update', format: 'json')
      expect(patch: '/users/auth/password/update.json').to route_to('users/auth/passwords#update', format: 'json')
    end
  end
end
