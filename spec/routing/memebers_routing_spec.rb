require 'rails_helper'

RSpec.describe MembersController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/members').not_to be_routable
      expect(get: '/members/c1').to route_to('members#index', customer_code: 'c1')
    end
    it 'routes to #new' do
      # expect(get: '/members/new').not_to be_routable # Tips: members#index(new)
      expect(get: '/members/c1/new').to route_to('members#new', customer_code: 'c1')
    end
    it 'routes to #show' do
      # expect(get: '/members/1').not_to be_routable # Tips: members#index(1)
      expect(get: '/members/c1/u1').not_to be_routable
    end
    it 'routes to #edit' do
      expect(get: '/members/1/edit').not_to be_routable
      expect(get: '/members/c1/u1/edit').to route_to('members#edit', customer_code: 'c1', user_code: 'u1')
    end
    it 'routes to #create' do
      expect(post: '/members').not_to be_routable
      expect(post: '/members/c1/new').to route_to('members#create', customer_code: 'c1')
    end
    it 'routes to #update via PUT' do
      expect(put: '/members/1').not_to be_routable
      expect(put: '/members/c1/u1/edit').to route_to('members#update', customer_code: 'c1', user_code: 'u1')
    end
    it 'routes to #update via PATCH' do
      expect(patch: '/members/1').not_to be_routable
      expect(patch: '/members/c1/u1/edit').to route_to('members#update', customer_code: 'c1', user_code: 'u1')
    end
    it 'routes to #delete' do
      expect(get: '/members/c1/u1/delete').to route_to('members#delete', customer_code: 'c1', user_code: 'u1')
    end
    it 'routes to #destroy' do
      expect(delete: '/members/1').not_to be_routable
      expect(delete: '/members/c1/u1/delete').to route_to('members#destroy', customer_code: 'c1', user_code: 'u1')
    end
  end
end
