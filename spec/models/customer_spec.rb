require 'rails_helper'

RSpec.describe Customer, type: :model do
  describe 'validates code' do
    context "#{Settings['customer_code_minimum'] - 1}文字" do
      it 'NG' do
        customer = FactoryBot.build(:customer, code: 'a' * (Settings['customer_code_minimum'] - 1), name: 'test')
        expect(customer).not_to be_valid
      end
    end
    context "#{Settings['customer_code_minimum']}文字" do
      it 'OK' do
        customer = FactoryBot.build(:customer, code: 'a' * Settings['customer_code_minimum'], name: 'test')
        expect(customer).to be_valid
      end
    end
    context "#{Settings['customer_code_maximum']}文字" do
      it 'OK' do
        customer = FactoryBot.build(:customer, code: 'a' * Settings['customer_code_maximum'], name: 'test')
        expect(customer).to be_valid
      end
    end
    context "#{Settings['customer_code_maximum'] + 1}文字" do
      it 'NG' do
        customer = FactoryBot.build(:customer, code: 'a' * (Settings['customer_code_maximum'] + 1), name: 'test')
        expect(customer).not_to be_valid
      end
    end
    context 'アルファベット(小文字)・数字' do
      it 'OK' do
        customer = FactoryBot.build(:customer, code: 'a' * [Settings['subdomain_minimum'] - 3, 1].max + 'z09', name: 'test')
        expect(customer).to be_valid
      end
    end
    context 'アルファベット(大文字)' do
      it 'NG' do
        customer = FactoryBot.build(:customer, code: 'A' * Settings['subdomain_minimum'], name: 'test')
        expect(customer).not_to be_valid
      end
    end
    context '重複' do
      it 'NG' do
        customer1 = FactoryBot.create(:customer)
        customer2 = FactoryBot.build(:customer, code: customer1.code, name: 'test')
        expect(customer2).not_to be_valid
      end
    end
  end

  describe 'validates name' do
    context "#{Settings['customer_name_minimum'] - 1}文字" do
      it 'NG' do
        customer = FactoryBot.build(:customer, name: 'a' * (Settings['customer_name_minimum'] - 1))
        expect(customer).not_to be_valid
      end
    end
    context "#{Settings['customer_name_minimum']}文字" do
      it 'OK' do
        customer = FactoryBot.build(:customer, name: 'a' * Settings['customer_name_minimum'])
        expect(customer).to be_valid
      end
    end
    context "#{Settings['customer_name_maximum']}文字" do
      it 'OK' do
        customer = FactoryBot.build(:customer, name: 'a' * Settings['customer_name_maximum'])
        expect(customer).to be_valid
      end
    end
    context "#{Settings['customer_name_maximum'] + 1}文字" do
      it 'NG' do
        customer = FactoryBot.build(:customer, name: 'a' * (Settings['customer_name_maximum'] + 1))
        expect(customer).not_to be_valid
      end
    end
  end
end
