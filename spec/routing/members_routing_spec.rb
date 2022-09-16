require 'rails_helper'

RSpec.describe MembersController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/members').not_to be_routable
      expect(get: '/members/code0001').to route_to('members#index', code: 'code0001')
    end

    it 'routes to #show' do
      # expect(get: '/members/1').not_to be_routable # Tips: members#index
    end

    it 'routes to #new' do
      # expect(get: '/members/new').not_to be_routable # Tips: members#index
      expect(get: '/members/code0001/create').to route_to('members#new', code: 'code0001')
    end

    it 'routes to #create' do
      expect(post: '/members').not_to be_routable
      expect(post: '/members/code0001/create').to route_to('members#create', code: 'code0001')
    end

    it 'routes to #edit' do
      expect(get: '/members/1/edit').not_to be_routable
      expect(get: '/members/code0001/update').to route_to('members#edit', code: 'code0001')
    end

    it 'routes to #update' do
      expect(put: '/members/1').not_to be_routable
      expect(patch: '/members/1').not_to be_routable
      expect(post: '/members/code0001/update').to route_to('members#update', code: 'code0001')
    end

    it 'routes to #delete' do
      expect(get: '/members/code0001/delete').to route_to('members#delete', code: 'code0001')
    end

    it 'routes to #destroy' do
      expect(delete: '/members/1').not_to be_routable
      expect(post: '/members/code0001/delete').to route_to('members#destroy', code: 'code0001')
    end
  end
end
