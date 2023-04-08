require 'rails_helper'

RSpec.describe SpacesController, type: :routing do
  describe 'routing' do
    let(:code) { 'code0001' }

    it 'routes to #index' do
      expect(get: '/spaces').to route_to('spaces#index')
      expect(get: '/spaces.json').to route_to('spaces#index', format: 'json')
    end

    it 'routes to #show' do
      expect(get: '/spaces/1').not_to be_routable
      expect(get: "/-/#{code}").to route_to('spaces#show', code: code)
      expect(get: "/-/#{code}.json").to route_to('spaces#show', code: code, format: 'json')
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
      expect(get: "/spaces/update/#{code}").to route_to('spaces#edit', code: code)
    end

    it 'routes to #update' do
      expect(put: '/spaces/1').not_to be_routable
      expect(patch: '/spaces/1').not_to be_routable
      expect(post: "/spaces/update/#{code}").to route_to('spaces#update', code: code)
      expect(post: "/spaces/update/#{code}.json").to route_to('spaces#update', code: code, format: 'json')
    end

    it 'routes to #delete' do
      expect(get: "/spaces/delete/#{code}").to route_to('spaces#delete', code: code)
    end

    it 'routes to #destroy' do
      expect(delete: '/spaces/1').not_to be_routable
      expect(post: "/spaces/delete/#{code}").to route_to('spaces#destroy', code: code)
      expect(post: "/spaces/delete/#{code}.json").to route_to('spaces#destroy', code: code, format: 'json')
    end

    it 'routes to #undo_delete' do
      expect(get: "/spaces/undo_delete/#{code}").to route_to('spaces#undo_delete', code: code)
    end

    it 'routes to #undo_destroy' do
      expect(post: "/spaces/undo_delete/#{code}").to route_to('spaces#undo_destroy', code: code)
      expect(post: "/spaces/undo_delete/#{code}.json").to route_to('spaces#undo_destroy', code: code, format: 'json')
    end
  end
end
