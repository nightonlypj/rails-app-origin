require 'rails_helper'

RSpec.describe Users::PasswordsController, type: :routing do
  describe 'routing' do
    it 'routes to #new' do
      expect(get: '/users/password/new').to route_to('users/passwords#new')
    end
    it 'routes to #new' do
      # expect(post: '/users/password').to route_to('users/passwords#create')
      # expect(post: '/users/password').not_to be_routable # Tips: users/passwords#update
      expect(post: '/users/password/new').to route_to('users/passwords#create')
    end
    it 'routes to #edit' do
      # expect(get: '/users/password/edit').to route_to('users/passwords#edit')
      expect(get: '/users/password/edit').not_to be_routable
      expect(get: '/users/password').to route_to('users/passwords#edit')
    end
    it 'routes to #update' do
      # expect(put: '/users/password').to route_to('users/passwords#update')
      # expect(patch: '/users/password').to route_to('users/passwords#update')
      expect(put: '/users/password').not_to be_routable
      expect(patch: '/users/password').not_to be_routable
      expect(post: '/users/password').to route_to('users/passwords#update')
    end
  end
end
