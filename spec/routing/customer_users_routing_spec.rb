require 'rails_helper'

RSpec.describe CustomerUsersController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/customer_users').not_to be_routable
      expect(get: '/customer_users/c1').to route_to('customer_users#index', customer_code: 'c1')
    end
    it 'routes to #new' do
      # expect(get: '/customer_users/new').not_to be_routable # Tips: customer_users#index(new)
      expect(get: '/customer_users/c1/new').to route_to('customer_users#new', customer_code: 'c1')
    end
    it 'routes to #show' do
      # expect(get: '/customer_users/1').not_to be_routable # Tips: customer_users#index(1)
      expect(get: '/customer_users/c1/u1').not_to be_routable
    end
    it 'routes to #edit' do
      expect(get: '/customer_users/1/edit').not_to be_routable
      expect(get: '/customer_users/c1/u1/edit').to route_to('customer_users#edit', customer_code: 'c1', user_code: 'u1')
    end
    it 'routes to #create' do
      expect(post: '/customer_users').not_to be_routable
      expect(post: '/customer_users/c1').to route_to('customer_users#create', customer_code: 'c1')
    end
    it 'routes to #update via PUT' do
      expect(put: '/customer_users/1').not_to be_routable
      expect(put: '/customer_users/c1/u1').to route_to('customer_users#update', customer_code: 'c1', user_code: 'u1')
    end
    it 'routes to #update via PATCH' do
      expect(patch: '/customer_users/1').not_to be_routable
      expect(patch: '/customer_users/c1/u1').to route_to('customer_users#update', customer_code: 'c1', user_code: 'u1')
    end
    it 'routes to #delete' do
      expect(get: '/customer_users/c1/u1/delete').to route_to('customer_users#delete', customer_code: 'c1', user_code: 'u1')
    end
    it 'routes to #destroy' do
      expect(delete: '/customer_users/1').not_to be_routable
      expect(delete: '/customer_users/c1/u1').to route_to('customer_users#destroy', customer_code: 'c1', user_code: 'u1')
    end
  end
end
