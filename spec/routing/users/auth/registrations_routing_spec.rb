require 'rails_helper'

RSpec.describe Users::Auth::RegistrationsController, type: :routing do
  describe 'routing' do
    it 'routes to #new' do
      # expect(get: '/users/auth/sign_up').to route_to('users/auth/registrations#new')
      expect(get: '/users/auth/sign_up').not_to be_routable
    end
    it 'routes to #create' do
      # expect(post: '/users/auth').to route_to('users/auth/registrations#create')
      expect(post: '/users/auth').not_to be_routable
      expect(post: '/users/auth/sign_up').to route_to('users/auth/registrations#create')
      expect(post: '/users/auth/sign_up.json').to route_to('users/auth/registrations#create', format: 'json')
    end
    it 'routes to #edit' do
      # expect(get: '/users/auth/edit').to route_to('users/auth/registrations#edit')
      expect(get: '/users/auth/edit').not_to be_routable
    end
    it 'routes to #update' do
      # expect(put: '/users/auth').to route_to('users/auth/registrations#update')
      # expect(patch: '/users/auth').to route_to('users/auth/registrations#update')
      expect(put: '/users/auth').not_to be_routable
      expect(patch: '/users/auth').not_to be_routable
      expect(put: '/users/auth/update').to route_to('users/auth/registrations#update')
      expect(patch: '/users/auth/update').to route_to('users/auth/registrations#update')
      expect(put: '/users/auth/update.json').to route_to('users/auth/registrations#update', format: 'json')
      expect(patch: '/users/auth/update.json').to route_to('users/auth/registrations#update', format: 'json')
    end
    it 'routes to #image_update' do
      # expect(put: '/users/auth/image').to route_to('users/auth/registrations#image_update')
      # expect(patch: '/users/auth/image').to route_to('users/auth/registrations#image_update')
      # expect(get: '/users/auth/image').to be_routable
    end
    it 'routes to #image_destroy' do
      # expect(delete: '/users/auth/image').to route_to('users/auth/registrations#image_destroy')
    end
    it 'routes to #delete' do
      # expect(get: '/users/auth/delete').to be_routable
    end
    it 'routes to #destroy' do
      # expect(delete: '/users/auth').to route_to('users/auth/registrations#destroy')
      expect(delete: '/users/auth').not_to be_routable
      expect(delete: '/users/auth/destroy').to route_to('users/auth/registrations#destroy')
      expect(delete: '/users/auth/destroy.json').to route_to('users/auth/registrations#destroy', format: 'json')
    end
    it 'routes to #undo_delete' do
      # expect(get: '/users/auth/undo_delete').to be_routable
    end
    it 'routes to #undo_destroy' do
      # expect(delete: '/users/auth/undo_delete').to route_to('users/auth/registrations#undo_destroy')
    end
    it 'routes to #cancel' do
      # expect(get: '/users/auth/cancel').to route_to('users/auth/registrations#cancel')
      expect(get: '/users/auth/cancel').not_to be_routable
    end
  end
end
