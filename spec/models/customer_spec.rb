require 'rails_helper'

RSpec.describe Customer, type: :model do
  describe 'validates code' do
    shared_context 'データ作成' do |code|
      let!(:customer) { FactoryBot.build(:customer, code: code, name: 'test') }
    end
    shared_context '重複データ作成' do
      let!(:create_customer) { FactoryBot.create(:customer) }
      let!(:customer) { FactoryBot.build(:customer, code: create_customer.code, name: 'test') }
    end

    # テスト内容
    shared_examples_for 'ToOK' do
      it 'OK' do
        expect(customer).to be_valid
      end
    end
    shared_examples_for 'ToNG' do
      it 'NG' do
        expect(customer).not_to be_valid
      end
    end

    # テストケース
    context "#{Settings['customer_code_minimum'] - 1}文字" do
      include_context 'データ作成', 'a' * (Settings['customer_code_minimum'] - 1)
      it_behaves_like 'ToNG'
    end
    context "#{Settings['customer_code_minimum']}文字" do
      include_context 'データ作成', 'a' * Settings['customer_code_minimum']
      it_behaves_like 'ToOK'
    end
    context "#{Settings['customer_code_maximum']}文字" do
      include_context 'データ作成', 'a' * Settings['customer_code_maximum']
      it_behaves_like 'ToOK'
    end
    context "#{Settings['customer_code_maximum'] + 1}文字" do
      include_context 'データ作成', 'a' * (Settings['customer_code_maximum'] + 1)
      it_behaves_like 'ToNG'
    end
    context 'アルファベット(小文字)・数字' do
      include_context 'データ作成', 'a' * [Settings['customer_code_minimum'] - 3, 1].max + 'z09'
      it_behaves_like 'ToOK'
    end
    context 'アルファベット(大文字)' do
      include_context 'データ作成', 'A' * Settings['customer_code_minimum']
      it_behaves_like 'ToNG'
    end
    context '重複' do
      include_context '重複データ作成'
      it_behaves_like 'ToNG'
    end
  end

  describe 'validates name' do
    shared_context 'データ作成' do |name|
      let!(:customer) { FactoryBot.build(:customer, name: name) }
    end

    # テスト内容
    shared_examples_for 'ToOK' do
      it 'OK' do
        expect(customer).to be_valid
      end
    end
    shared_examples_for 'ToNG' do
      it 'NG' do
        expect(customer).not_to be_valid
      end
    end

    # テストケース
    context "#{Settings['customer_name_minimum'] - 1}文字" do
      include_context 'データ作成', 'a' * (Settings['customer_name_minimum'] - 1)
      it_behaves_like 'ToNG'
    end
    context "#{Settings['customer_name_minimum']}文字" do
      include_context 'データ作成', 'a' * Settings['customer_name_minimum']
      it_behaves_like 'ToOK'
    end
    context "#{Settings['customer_name_maximum']}文字" do
      include_context 'データ作成', 'a' * Settings['customer_name_maximum']
      it_behaves_like 'ToOK'
    end
    context "#{Settings['customer_name_maximum'] + 1}文字" do
      include_context 'データ作成', 'a' * (Settings['customer_name_maximum'] + 1)
      it_behaves_like 'ToNG'
    end
  end
end
