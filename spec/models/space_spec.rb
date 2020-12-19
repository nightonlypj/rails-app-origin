require 'rails_helper'

RSpec.describe Space, type: :model do
  let!(:customers) { FactoryBot.create_list(:customer, 2) }

  describe 'validates subdomain' do
    shared_context 'データ作成' do |subdomain|
      let!(:space) { FactoryBot.build(:space, customer_id: customers[0].id, subdomain: subdomain, name: 'test') }
    end
    shared_context '重複データ作成' do |same_customer_flag|
      let!(:create_space) { FactoryBot.create(:space, customer_id: customers[0].id) }
      let!(:space) { FactoryBot.build(:space, customer_id: customers[same_customer_flag ? 0 : 1].id, subdomain: create_space.subdomain, name: 'test') }
    end

    # テスト内容
    shared_examples_for 'ToOK' do
      it 'OK' do
        expect(space).to be_valid
      end
    end
    shared_examples_for 'ToNG' do
      it 'NG' do
        expect(space).not_to be_valid
      end
    end

    # テストケース
    context "#{Settings['subdomain_minimum'] - 1}文字" do
      include_context 'データ作成', 'a' * (Settings['subdomain_minimum'] - 1)
      it_behaves_like 'ToNG'
    end
    context "#{Settings['subdomain_minimum']}文字" do
      include_context 'データ作成', 'a' * Settings['subdomain_minimum']
      it_behaves_like 'ToOK'
    end
    context "#{Settings['subdomain_maximum']}文字" do
      include_context 'データ作成', 'a' * Settings['subdomain_maximum']
      it_behaves_like 'ToOK'
    end
    context "#{Settings['subdomain_maximum'] + 1}文字" do
      include_context 'データ作成', 'a' * (Settings['subdomain_maximum'] + 1)
      it_behaves_like 'ToNG'
    end
    context 'アルファベット(小文字)・数字・ハイフン(先頭不可)' do
      include_context 'データ作成', 'a' * [Settings['subdomain_minimum'] - 4, 1].max + 'z09-'
      it_behaves_like 'ToOK'
    end
    context 'アルファベット(大文字)' do
      include_context 'データ作成', 'A' * Settings['subdomain_minimum']
      it_behaves_like 'ToNG'
    end
    context 'ハイフン(先頭)' do
      include_context 'データ作成', '-' + 'a' * [Settings['subdomain_minimum'] - 1, 1].max
      it_behaves_like 'ToNG'
    end
    context 'ハイフン(後尾)' do
      include_context 'データ作成', 'a' * [Settings['subdomain_minimum'] - 1, 1].max + '-'
      it_behaves_like 'ToOK'
    end
    context '重複（同じ顧客）' do
      include_context '重複データ作成', true
      it_behaves_like 'ToNG'
    end
    context '重複（違う顧客）' do
      include_context '重複データ作成', false
      it_behaves_like 'ToNG'
    end
  end

  describe 'validates name' do
    shared_context 'データ作成' do |name|
      let!(:space) { FactoryBot.build(:space, customer_id: customers[0].id, name: name) }
    end

    # テスト内容
    shared_examples_for 'ToOK' do
      it 'OK' do
        expect(space).to be_valid
      end
    end
    shared_examples_for 'ToNG' do
      it 'NG' do
        expect(space).not_to be_valid
      end
    end

    # テストケース
    context "#{Settings['space_name_minimum'] - 1}文字" do
      include_context 'データ作成', 'a' * (Settings['space_name_minimum'] - 1)
      it_behaves_like 'ToNG'
    end
    context "#{Settings['space_name_minimum']}文字" do
      include_context 'データ作成', 'a' * Settings['space_name_minimum']
      it_behaves_like 'ToOK'
    end
    context "#{Settings['space_name_maximum']}文字" do
      include_context 'データ作成', 'a' * Settings['space_name_maximum']
      it_behaves_like 'ToOK'
    end
    context "#{Settings['space_name_maximum'] + 1}文字" do
      include_context 'データ作成', 'a' * (Settings['space_name_maximum'] + 1)
      it_behaves_like 'ToNG'
    end
  end
end
