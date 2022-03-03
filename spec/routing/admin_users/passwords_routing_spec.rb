require 'rails_helper'

RSpec.describe AdminUsers::PasswordsController, type: :routing do
  describe 'routing' do
    it 'routes to #new' do
      # expect(get: '/admin_users/password/new').to route_to('admin_users/passwords#new')
      expect(get: '/admin_users/password/new').not_to be_routable
      expect(get: '/admin/password/new').to route_to('admin_users/passwords#new')
    end
    it 'routes to #new' do
      # expect(post: '/admin_users/password').to route_to('admin_users/passwords#create')
      expect(post: '/admin_users/password').not_to be_routable
      expect(post: '/admin_users/password/new').not_to be_routable
      # expect(post: '/admin/password').not_to be_routable # Tips: rails_admin/main#index
      expect(post: '/admin/password/new').to route_to('admin_users/passwords#create')
    end
    it 'routes to #edit' do
      # expect(get: '/admin_users/password/edit').to route_to('admin_users/passwords#edit')
      expect(get: '/admin_users/password/edit').not_to be_routable
      expect(get: '/admin_users/password').not_to be_routable
      # expect(get: '/admin/password/edit').not_to be_routable # Tips: rails_admin/main#show
      expect(get: '/admin/password').to route_to('admin_users/passwords#edit')
    end
    it 'routes to #update' do
      # expect(put: '/admin_users/password').to route_to('admin_users/passwords#update')
      expect(put: '/admin_users/password').not_to be_routable
      expect(put: '/admin/password').to route_to('admin_users/passwords#update')
    end
  end
end
