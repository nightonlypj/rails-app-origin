require 'rails_helper'

RSpec.describe AdminUsers::SessionsController, type: :routing do
  describe 'routing' do
    it 'routes to #new' do
      expect(get: '/admin_users/sign_in').to route_to('admin_users/sessions#new')
    end
    it 'routes to #create' do
      expect(post: '/admin_users/sign_in').to route_to('admin_users/sessions#create')
    end
    it 'routes to #destroy' do
      expect(delete: '/admin_users/sign_out').to route_to('admin_users/sessions#destroy')
      expect(get: '/admin_users/sign_out').to route_to('admin_users/sessions#destroy')
    end
  end
end
