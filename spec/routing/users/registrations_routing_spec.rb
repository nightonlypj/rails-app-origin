require 'rails_helper'

RSpec.describe Users::RegistrationsController, type: :routing do
  describe 'routing' do
    it 'routes to #new' do
      expect(get: '/users/sign_up').to route_to('users/registrations#new')
    end
    it 'routes to #create' do
      expect(post: '/users').to route_to('users/registrations#create')
    end
    it 'routes to #edit' do
      expect(get: '/users/edit').to route_to('users/registrations#edit')
    end
    it 'routes to #update' do
      expect(put: '/users').to route_to('users/registrations#update')
    end
    it 'routes to #delete' do
      expect(get: '/users/delete').to route_to('users/registrations#delete')
    end
    it 'routes to #destroy' do
      expect(delete: '/users').to route_to('users/registrations#destroy')
    end
    it 'routes to #cancel' do
      expect(get: '/users/cancel').to route_to('users/registrations#cancel')
    end
  end
end
