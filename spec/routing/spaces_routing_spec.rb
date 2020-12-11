require 'rails_helper'

RSpec.describe SpacesController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/spaces').to route_to('spaces#index')
    end

    it 'routes to #new' do
      expect(get: '/spaces/new').to route_to('spaces#new')
    end

    it 'routes to #show' do
      expect(get: '/spaces/1').not_to be_routable
    end

    it 'routes to #edit' do
      expect(get: '/spaces/1/edit').not_to be_routable
      expect(get: '/spaces/edit').to route_to('spaces#edit')
    end

    it 'routes to #create' do
      expect(post: '/spaces').to route_to('spaces#create')
    end

    it 'routes to #update via PUT' do
      expect(put: '/spaces/1').not_to be_routable
      expect(put: '/spaces').to route_to('spaces#update')
    end

    it 'routes to #update via PATCH' do
      expect(patch: '/spaces/1').not_to be_routable
      expect(patch: '/spaces').to route_to('spaces#update')
    end

    it 'routes to #destroy' do
      expect(delete: '/spaces/1').not_to be_routable
    end
  end
end
