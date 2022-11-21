require 'rails_helper'

RSpec.describe Users::RegistrationsController, type: :routing do
  describe 'routing' do
    it 'routes to #new' do
      expect(get: '/users/sign_up').to route_to('users/registrations#new')
    end
    it 'routes to #create' do
      # expect(post: '/users').to route_to('users/registrations#create')
      expect(post: '/users').not_to be_routable
      expect(post: '/users/sign_up').to route_to('users/registrations#create')
    end
    it 'routes to #edit' do
      expect(get: '/users/edit').not_to be_routable
      expect(get: '/users/update').to route_to('users/registrations#edit')
    end
    it 'routes to #update' do
      # expect(put: '/users').to route_to('users/registrations#update')
      # expect(patch: '/users').to route_to('users/registrations#update')
      expect(put: '/users').not_to be_routable
      expect(patch: '/users').not_to be_routable
      expect(put: '/users/update').to route_to('users/registrations#update')
    end
    it 'routes to #image_update' do
      expect(get: '/users/image/update').to route_to('users/registrations#edit') # NOTE: URL直アクセス対応
      expect(post: '/users/image/update').to route_to('users/registrations#image_update')
    end
    it 'routes to #image_destroy' do
      expect(delete: '/users/image/delete').not_to be_routable
      expect(get: '/users/image/delete').to route_to('users/registrations#edit') # NOTE: URL直アクセス対応
      expect(post: '/users/image/delete').to route_to('users/registrations#image_destroy')
    end
    it 'routes to #delete' do
      expect(get: '/users/delete').to route_to('users/registrations#delete')
    end
    it 'routes to #destroy' do
      # expect(delete: '/users').to route_to('users/registrations#destroy')
      expect(delete: '/users').not_to be_routable
      expect(post: '/users/delete').to route_to('users/registrations#destroy')
    end
    it 'routes to #undo_delete' do
      expect(get: '/users/undo_delete').to route_to('users/registrations#undo_delete')
    end
    it 'routes to #undo_destroy' do
      expect(post: '/users/undo_delete').to route_to('users/registrations#undo_destroy')
    end
    it 'routes to #cancel' do
      # expect(get: '/users/cancel').to route_to('users/registrations#cancel')
      expect(get: '/users/cancel').not_to be_routable
    end
  end
end
