require 'rails_helper'

RSpec.describe AdminUsers::RegistrationsController, type: :routing do
  describe 'routing' do
    it 'routes to #new' do
      expect(get: '/admin_users/sign_up').to_not be_routable
    end
    it 'routes to #create' do
      expect(post: '/admin_users').to_not be_routable
    end
    it 'routes to #edit' do
      expect(get: '/admin_users/edit').to_not be_routable
    end
    it 'routes to #update' do
      expect(put: '/admin_users').to_not be_routable
    end
    it 'routes to #destroy' do
      expect(delete: '/admin_users').to_not be_routable
    end
    it 'routes to #cancel' do
      expect(get: '/admin_users/cancel').to_not be_routable
    end
  end
end