require 'rails_helper'

RSpec.describe CustomerUsersController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/customer_users').to route_to('customer_users#index')
    end

    it 'routes to #new' do
      expect(get: '/customer_users/new').to route_to('customer_users#new')
    end

    it 'routes to #show' do
      expect(get: '/customer_users/1').to route_to('customer_users#show', id: '1')
    end

    it 'routes to #edit' do
      expect(get: '/customer_users/1/edit').to route_to('customer_users#edit', id: '1')
    end

    it 'routes to #create' do
      expect(post: '/customer_users').to route_to('customer_users#create')
    end

    it 'routes to #update via PUT' do
      expect(put: '/customer_users/1').to route_to('customer_users#update', id: '1')
    end

    it 'routes to #update via PATCH' do
      expect(patch: '/customer_users/1').to route_to('customer_users#update', id: '1')
    end

    it 'routes to #destroy' do
      expect(delete: '/customer_users/1').to route_to('customer_users#destroy', id: '1')
    end
  end
end
