require 'rails_helper'

RSpec.describe AdminUsers::PasswordsController, type: :routing do
  describe 'routing' do
    it 'routes to #new' do
      expect(get: '/admin_users/password/new').to route_to('devise/passwords#new')
    end
    it 'routes to #new' do
      expect(post: '/admin_users/password').to route_to('devise/passwords#create')
    end
    it 'routes to #edit' do
      expect(get: '/admin_users/password/edit').to route_to('devise/passwords#edit')
    end
    it 'routes to #update' do
      expect(put: '/admin_users/password').to route_to('devise/passwords#update')
    end
  end
end
