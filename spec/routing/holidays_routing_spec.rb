require 'rails_helper'

RSpec.describe HolidaysController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/holidays').to route_to('holidays#index')
      expect(get: '/holidays.json').to route_to('holidays#index', format: 'json')
    end
    it 'routes to #show' do
      expect(get: '/holidays/1').not_to be_routable
    end
    it 'routes to #new' do
      expect(get: '/holidays/new').not_to be_routable
    end
    it 'routes to #edit' do
      expect(get: '/holidays/1/edit').not_to be_routable
    end
    it 'routes to #create' do
      expect(post: '/holidays').not_to be_routable
    end
    it 'routes to #update' do
      expect(put: '/holidays/1').not_to be_routable
      expect(patch: '/holidays/1').not_to be_routable
    end
    it 'routes to #destroy' do
      expect(delete: '/holidays/1').not_to be_routable
    end
  end
end
