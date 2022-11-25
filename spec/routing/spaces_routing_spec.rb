require 'rails_helper'

RSpec.describe SpacesController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/spaces').to route_to('spaces#index')
      expect(get: '/spaces.json').to route_to('spaces#index', format: 'json')
    end

    it 'routes to #show' do
      expect(get: '/spaces/1').not_to be_routable
      expect(get: '/s/code0001').to route_to('spaces#show', code: 'code0001')
      expect(get: '/s/code0001.json').to route_to('spaces#show', code: 'code0001', format: 'json')
    end

    it 'routes to #new' do
      expect(get: '/spaces/new').not_to be_routable
      expect(get: '/spaces/create').to route_to('spaces#new')
    end

    it 'routes to #create' do
      expect(post: '/spaces').not_to be_routable
      expect(post: '/spaces/create').to route_to('spaces#create')
      expect(post: '/spaces/create.json').to route_to('spaces#create', format: 'json')
    end

    it 'routes to #edit' do
      expect(get: '/spaces/1/edit').not_to be_routable
      expect(get: '/spaces/code0001/update').to route_to('spaces#edit', code: 'code0001')
    end

    it 'routes to #update' do
      expect(put: '/spaces/1').not_to be_routable
      expect(patch: '/spaces/1').not_to be_routable
      expect(post: '/spaces/code0001/update').to route_to('spaces#update', code: 'code0001')
      expect(post: '/spaces/code0001/update.json').to route_to('spaces#update', code: 'code0001', format: 'json')
    end

    it 'routes to #delete' do
      expect(get: '/spaces/code0001/delete').to route_to('spaces#delete', code: 'code0001')
    end

    it 'routes to #destroy' do
      expect(delete: '/spaces/1').not_to be_routable
      expect(post: '/spaces/code0001/delete').to route_to('spaces#destroy', code: 'code0001')
      expect(post: '/spaces/code0001/delete.json').to route_to('spaces#destroy', code: 'code0001', format: 'json')
    end
  end
end
