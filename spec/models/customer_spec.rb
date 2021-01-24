require 'rails_helper'

RSpec.describe Customer, type: :model do
  # 顧客コード
  # 前提条件
  #   なし
  # テストパターン
  #   最小文字数よりも少ない, 最小文字数, 最大文字数, 最大文字数よりも多い,
  #     アルファベット(小文字)・数字, アルファベット(大文字), 重複 → データ作成
  describe 'validates :code' do
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
    context '最小文字数よりも少ない' do
      include_context 'データ作成', 'a' * (Settings['customer_code_minimum'] - 1)
      it_behaves_like 'ToNG'
    end
    context '最小文字数' do
      include_context 'データ作成', 'a' * Settings['customer_code_minimum']
      it_behaves_like 'ToOK'
    end
    context '最大文字数' do
      include_context 'データ作成', 'a' * Settings['customer_code_maximum']
      it_behaves_like 'ToOK'
    end
    context '最大文字数よりも多い' do
      include_context 'データ作成', 'a' * (Settings['customer_code_maximum'] + 1)
      it_behaves_like 'ToNG'
    end
    context 'アルファベット(小文字)・数字' do
      include_context 'データ作成', "#{'a' * [Settings['customer_code_minimum'] - 3, 1].max}z09"
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

  # 顧客名
  # 前提条件
  #   なし
  # テストパターン
  #   最小文字数よりも少ない, 最小文字数, 最大文字数, 最大文字数よりも多い → データ作成
  describe 'validates :name' do
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
    context '最小文字数よりも少ない' do
      include_context 'データ作成', 'a' * (Settings['customer_name_minimum'] - 1)
      it_behaves_like 'ToNG'
    end
    context '最小文字数' do
      include_context 'データ作成', 'a' * Settings['customer_name_minimum']
      it_behaves_like 'ToOK'
    end
    context '最大文字数' do
      include_context 'データ作成', 'a' * Settings['customer_name_maximum']
      it_behaves_like 'ToOK'
    end
    context '最大文字数よりも多い' do
      include_context 'データ作成', 'a' * (Settings['customer_name_maximum'] + 1)
      it_behaves_like 'ToNG'
    end
  end
end
