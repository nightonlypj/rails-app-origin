require 'rails_helper'

RSpec.describe AdminUser, type: :model do
  describe 'validates name' do
    context "#{Settings['user_name_minimum'] - 1}文字" do
      it 'NG' do
        admin_user = FactoryBot.build(:admin_user, name: 'a' * (Settings['user_name_minimum'] - 1))
        expect(admin_user).not_to be_valid
      end
    end
    context "#{Settings['user_name_minimum']}文字" do
      it 'OK' do
        admin_user = FactoryBot.build(:admin_user, name: 'a' * Settings['user_name_minimum'])
        expect(admin_user).to be_valid
      end
    end
    context "#{Settings['user_name_maximum']}文字" do
      it 'OK' do
        admin_user = FactoryBot.build(:admin_user, name: 'a' * Settings['user_name_maximum'])
        expect(admin_user).to be_valid
      end
    end
    context "#{Settings['user_name_maximum'] + 1}文字" do
      it 'NG' do
        admin_user = FactoryBot.build(:admin_user, name: 'a' * (Settings['user_name_maximum'] + 1))
        expect(admin_user).not_to be_valid
      end
    end
  end
end
