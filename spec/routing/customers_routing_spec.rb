require 'rails_helper'

RSpec.describe CustomersController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/customers').to route_to('customers#index')
    end
    it 'routes to #show' do
      expect(get: '/customers/c1').to route_to('customers#show', customer_code: 'c1')
    end
    it 'routes to #new' do
      # expect(get: '/customers/new').not_to be_routable # Tips: customers#show(new)
    end
    it 'routes to #edit' do
      expect(get: '/customers/c1/edit').to route_to('customers#edit', customer_code: 'c1')
    end
    it 'routes to #create' do
      expect(post: '/customers').not_to be_routable
    end
    it 'routes to #update via PUT' do
      expect(put: '/customers/1').not_to be_routable
      expect(put: '/customers/c1/edit').to route_to('customers#update', customer_code: 'c1')
    end
    it 'routes to #update via PATCH' do
      expect(patch: '/customers/1').not_to be_routable
      expect(patch: '/customers/c1/edit').to route_to('customers#update', customer_code: 'c1')
    end
    it 'routes to #destroy' do
      expect(delete: '/customers/1').not_to be_routable
    end
  end
end
