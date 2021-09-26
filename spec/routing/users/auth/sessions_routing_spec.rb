require 'rails_helper'

RSpec.describe Users::Auth::SessionsController, type: :routing do
  describe 'routing' do
    it 'routes to #new' do
      # expect(get: '/users/auth/sign_in').to route_to('users/auth/sessions#new')
      expect(get: '/users/auth/sign_in').not_to be_routable
    end
    it 'routes to #create' do
      expect(post: '/users/auth/sign_in').to route_to('users/auth/sessions#create')
      expect(post: '/users/auth/sign_in.json').to route_to('users/auth/sessions#create', format: 'json')
    end
    it 'routes to #destroy' do
      expect(delete: '/users/auth/sign_out').to route_to('users/auth/sessions#destroy')
      expect(delete: '/users/auth/sign_out.json').to route_to('users/auth/sessions#destroy', format: 'json')
      expect(get: '/users/auth/sign_out').not_to be_routable
    end
  end
end
