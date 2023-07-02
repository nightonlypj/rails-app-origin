require 'rails_helper'

RSpec.describe MembersController, type: :routing do
  describe 'routing' do
    let(:space_code) { 'code0001' }
    let(:user_code)  { 'code000000000000000000001' }

    it 'routes to #index' do
      expect(get: '/members').not_to be_routable
      expect(get: "/members/#{space_code}").to route_to('members#index', space_code:)
      expect(get: "/members/#{space_code}.json").to route_to('members#index', space_code:, format: 'json')
    end

    it 'routes to #show' do
      # expect(get: '/members/1').not_to be_routable # NOTE: members#index
      expect(get: "/members/#{space_code}/detail/#{user_code}").to route_to('members#show', space_code:, user_code:)
      expect(get: "/members/#{space_code}/detail/#{user_code}.json").to route_to('members#show', space_code:, user_code:, format: 'json')
    end

    it 'routes to #new' do
      # expect(get: '/members/new').not_to be_routable # NOTE: members#index
      expect(get: "/members/#{space_code}/create").to route_to('members#new', space_code:)
    end

    it 'routes to #create' do
      expect(post: '/members').not_to be_routable
      expect(post: "/members/#{space_code}/create").to route_to('members#create', space_code:)
      expect(post: "/members/#{space_code}/create.json").to route_to('members#create', space_code:, format: 'json')
    end

    it 'routes to #result' do
      expect(get: "/members/#{space_code}/result").to route_to('members#result', space_code:)
    end

    it 'routes to #edit' do
      expect(get: '/members/1/edit').not_to be_routable
      expect(get: "/members/#{space_code}/update").not_to be_routable
      expect(get: "/members/#{space_code}/update/#{user_code}").to route_to('members#edit', space_code:, user_code:)
    end

    it 'routes to #update' do
      expect(put: '/members/1').not_to be_routable
      expect(patch: '/members/1').not_to be_routable
      expect(post: "/members/#{space_code}/update").not_to be_routable
      expect(post: "/members/#{space_code}/update/#{user_code}").to route_to('members#update', space_code:, user_code:)
      expect(post: "/members/#{space_code}/update/#{user_code}.json").to route_to('members#update', space_code:, user_code:, format: 'json')
    end

    it 'routes to #destroy' do
      expect(delete: '/members/1').not_to be_routable
      expect(get: "/members/#{space_code}/delete").to route_to('members#index', space_code:) # NOTE: URL直アクセス対応
      expect(post: "/members/#{space_code}/delete").to route_to('members#destroy', space_code:)
      expect(post: "/members/#{space_code}/delete.json").to route_to('members#destroy', space_code:, format: 'json')
    end
  end
end
