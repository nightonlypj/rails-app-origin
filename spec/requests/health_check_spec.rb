require 'rails_helper'

RSpec.describe 'HealthChecks', type: :request do
  describe 'GET #index' do
    subject { get health_check_path }

    it 'HTTPステータスが200。OKが返却される' do
      is_expected.to eq(200)
      expect(response.body).to eq('OK')
    end
  end
end
