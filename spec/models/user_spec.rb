require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validates name' do
    context "#{Settings['user_name_minimum'] - 1}文字" do
      it 'NG' do
        user = FactoryBot.build(:user, name: 'a' * (Settings['user_name_minimum'] - 1))
        expect(user).not_to be_valid
      end
    end
    context "#{Settings['user_name_minimum']}文字" do
      it 'OK' do
        user = FactoryBot.build(:user, name: 'a' * Settings['user_name_minimum'])
        expect(user).to be_valid
      end
    end
    context "#{Settings['user_name_maximum']}文字" do
      it 'OK' do
        user = FactoryBot.build(:user, name: 'a' * Settings['user_name_maximum'])
        expect(user).to be_valid
      end
    end
    context "#{Settings['user_name_maximum'] + 1}文字" do
      it 'NG' do
        user = FactoryBot.build(:user, name: 'a' * (Settings['user_name_maximum'] + 1))
        expect(user).not_to be_valid
      end
    end
  end
end
