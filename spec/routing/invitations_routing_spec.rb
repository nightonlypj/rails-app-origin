require 'rails_helper'

RSpec.describe InvitationsController, type: :routing do
  describe 'routing' do
    let(:space_code) { 'code0001' }
    let(:code)       { 'invitation000000000000001' }

    it 'routes to #index' do
      expect(get: '/invitations').not_to be_routable
      expect(get: "/invitations/#{space_code}").to route_to('invitations#index', space_code: space_code)
      expect(get: "/invitations/#{space_code}.json").to route_to('invitations#index', space_code: space_code, format: 'json')
    end

    it 'routes to #show' do
      # expect(get: '/invitations/1').not_to be_routable # NOTE: invitations#index
      expect(get: "/invitations/#{space_code}/detail/#{code}").to route_to('invitations#show', space_code: space_code, code: code)
      expect(get: "/invitations/#{space_code}/detail/#{code}.json").to route_to('invitations#show', space_code: space_code, code: code, format: 'json')
    end

    it 'routes to #new' do
      # expect(get: '/invitations/new').not_to be_routable # NOTE: invitations#index
      expect(get: "/invitations/#{space_code}/create").to route_to('invitations#new', space_code: space_code)
    end

    it 'routes to #create' do
      expect(post: '/invitations').not_to be_routable
      expect(post: "/invitations/#{space_code}/create").to route_to('invitations#create', space_code: space_code)
      expect(post: "/invitations/#{space_code}/create.json").to route_to('invitations#create', space_code: space_code, format: 'json')
    end

    it 'routes to #edit' do
      expect(get: '/invitations/1/edit').not_to be_routable
      expect(get: "/invitations/#{space_code}/update").not_to be_routable
      expect(get: "/invitations/#{space_code}/update/#{code}").to route_to('invitations#edit', space_code: space_code, code: code)
    end

    it 'routes to #update' do
      expect(put: '/invitations/1').not_to be_routable
      expect(patch: '/invitations/1').not_to be_routable
      expect(post: "/invitations/#{space_code}/update").not_to be_routable
      expect(post: "/invitations/#{space_code}/update/#{code}").to route_to('invitations#update', space_code: space_code, code: code)
      expect(post: "/invitations/#{space_code}/update/#{code}.json").to route_to('invitations#update', space_code: space_code, code: code, format: 'json')
    end

    it 'routes to #destroy' do
      expect(delete: '/invitations/1').not_to be_routable
    end
  end
end
