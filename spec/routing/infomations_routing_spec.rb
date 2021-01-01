require 'rails_helper'

RSpec.describe InfomationsController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/infomations').to route_to('infomations#index')
    end

    it 'routes to #new' do
      # expect(get: '/infomations/new').not_to be_routable # Tips: infomations#show(new)
    end

    it 'routes to #show' do
      expect(get: '/infomations/1').to route_to('infomations#show', id: '1')
    end

    it 'routes to #edit' do
      expect(get: '/infomations/1/edit').not_to be_routable
    end

    it 'routes to #create' do
      expect(post: '/infomations').not_to be_routable
    end

    it 'routes to #update via PUT' do
      expect(put: '/infomations/1').not_to be_routable
    end

    it 'routes to #update via PATCH' do
      expect(patch: '/infomations/1').not_to be_routable
    end

    it 'routes to #destroy' do
      expect(delete: '/infomations/1').not_to be_routable
    end
  end
end
