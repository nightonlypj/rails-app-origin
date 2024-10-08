require 'rails_helper'

RSpec.describe InfomationsController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/infomations').to route_to('infomations#index')
      expect(get: '/infomations.json').to route_to('infomations#index', format: 'json')
    end
    it 'routes to #important' do
      expect(get: '/infomations/important').to route_to('infomations#important')
      expect(get: '/infomations/important.json').to route_to('infomations#important', format: 'json')
    end
    it 'routes to #show' do
      expect(get: '/infomations/1').to route_to('infomations#show', id: '1')
      expect(get: '/infomations/1.json').to route_to('infomations#show', id: '1', format: 'json')
    end
    # it 'routes to #new' do
    #   expect(get: '/infomations/new').not_to be_routable # NOTE: infomations#show
    # end
    it 'routes to #edit' do
      expect(get: '/infomations/1/edit').not_to be_routable
    end
    it 'routes to #create' do
      expect(post: '/infomations').not_to be_routable
    end
    it 'routes to #update' do
      expect(put: '/infomations/1').not_to be_routable
      expect(patch: '/infomations/1').not_to be_routable
    end
    it 'routes to #destroy' do
      expect(delete: '/infomations/1').not_to be_routable
    end
  end
end
