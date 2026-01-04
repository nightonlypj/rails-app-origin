require 'rails_helper'

RSpec.describe HealthCheckController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/_health').to route_to('health_check#index')
    end
  end
end
