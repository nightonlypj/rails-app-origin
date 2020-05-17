require 'rails_helper'

RSpec.describe Users::PasswordsController, type: :routing do
  describe 'routing' do
    it 'routes to #new' do
      expect(get: '/users/password/new').to route_to('devise/passwords#new')
    end
    it 'routes to #new' do
      expect(post: '/users/password').to route_to('devise/passwords#create')
    end
    it 'routes to #edit' do
      expect(get: '/users/password/edit').to route_to('devise/passwords#edit')
    end
    it 'routes to #update' do
      expect(put: '/users/password').to route_to('devise/passwords#update')
    end
  end
end
