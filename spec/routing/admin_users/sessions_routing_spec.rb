require 'rails_helper'

RSpec.describe AdminUsers::SessionsController, type: :routing do
  describe 'routing' do
    it 'routes to #new' do
      # expect(get: '/admin_users/sign_in').to route_to('admin_users/sessions#new')
      expect(get: '/admin_users/sign_in').not_to be_routable
      expect(get: '/admin/sign_in').to route_to('admin_users/sessions#new')
    end
    it 'routes to #create' do
      # expect(post: '/admin_users/sign_in').to route_to('admin_users/sessions#create')
      expect(post: '/admin_users/sign_in').not_to be_routable
      expect(post: '/admin/sign_in').to route_to('admin_users/sessions#create')
    end
    it 'routes to #destroy' do
      # expect(delete: '/admin_users/sign_out').to route_to('admin_users/sessions#destroy')
      # expect(get: '/admin_users/sign_out').to route_to('admin_users/sessions#destroy')
      expect(delete: '/admin_users/sign_out').not_to be_routable
      expect(get: '/admin_users/sign_out').not_to be_routable
      expect(get: '/admin/sign_out').to route_to('admin_users/sessions#destroy') # NOTE: URL直アクセス対応
      expect(post: '/admin/sign_out').to route_to('admin_users/sessions#destroy')
      expect(delete: '/admin/sign_out').to route_to('admin_users/sessions#destroy') # NOTE: RailsAdmin用
    end
  end
end
