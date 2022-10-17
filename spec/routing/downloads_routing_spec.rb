require 'rails_helper'

RSpec.describe DownloadsController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/downloads').to route_to('downloads#index')
      expect(get: '/downloads.json').to route_to('downloads#index', format: 'json')
    end

    it 'routes to #show' do
      expect(get: '/downloads/1').not_to be_routable
    end

    it 'routes to #file' do
      expect(get: '/downloads/file/1').to route_to('downloads#file', id: '1')
      expect(get: '/downloads/file/1.json').to route_to('downloads#file', id: '1', format: 'json')
    end

    it 'routes to #new' do
      expect(get: '/downloads/new').not_to be_routable
      expect(get: '/downloads/create').to route_to('downloads#new')
    end

    it 'routes to #create' do
      expect(post: '/downloads').not_to be_routable
      expect(post: '/downloads/create').to route_to('downloads#create')
      expect(post: '/downloads/create.json').to route_to('downloads#create', format: 'json')
    end

    it 'routes to #edit' do
      expect(get: '/downloads/1/edit').not_to be_routable
    end

    it 'routes to #update' do
      expect(put: '/downloads/1').not_to be_routable
      expect(patch: '/downloads/1').not_to be_routable
    end

    it 'routes to #destroy' do
      expect(delete: '/downloads/1').not_to be_routable
    end
  end
end
