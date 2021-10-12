require 'rails_helper'

RSpec.describe Users::Auth::TokenValidationsController, type: :routing do
  describe 'routing' do
    it 'routes to #validate_token' do
      expect(get: '/users/auth/validate_token').to route_to('users/auth/token_validations#validate_token', format: :json)
      expect(get: '/users/auth/validate_token.json').to route_to('users/auth/token_validations#validate_token', format: 'json')
    end
  end
end
