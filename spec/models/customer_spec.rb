require 'rails_helper'

RSpec.describe Customer, type: :model do
  # 新規作成
  # 前提条件
  #   なし
  # テストパターン
  #   ない, nil, 'true', 'false', 未定義 → データ作成
  describe 'validates :create_flag' do
    shared_context 'データ作成' do |create_flag|
      let!(:customer) { FactoryBot.build(:customer, create_flag: create_flag) }
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
    context 'ない' do
      include_context 'データ作成', ''
      it_behaves_like 'ToNG'
    end
    context 'nil' do
      include_context 'データ作成', nil
      it_behaves_like 'ToOK'
    end
    context "'true'" do
      include_context 'データ作成', 'true'
      it_behaves_like 'ToOK'
    end
    context "'false'" do
      include_context 'データ作成', 'false'
      it_behaves_like 'ToOK'
    end
    context '未定義' do
      include_context 'データ作成', 'not'
      it_behaves_like 'ToNG'
    end
  end

  # 顧客コード
  # 前提条件
  #   新規作成が正常値
  # テストパターン
  #   新規作成: nil, 'true', 'false' → データ作成
  #   顧客コード: ない, 正常値, 重複 → データ作成
  describe 'validates :code' do
    shared_context 'データ作成' do |code|
      let!(:customer) { FactoryBot.build(:customer, create_flag: create_flag, code: code) }
    end
    shared_context '重複データ作成' do
      let!(:create_customer) { FactoryBot.create(:customer) }
      let!(:customer) { FactoryBot.build(:customer, create_flag: create_flag, code: create_customer.code) }
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
    shared_examples_for '[*]顧客コードがない' do
      include_context 'データ作成', ''
      it_behaves_like 'ToNG'
    end
    shared_examples_for '[*]顧客コードが正常値' do
      include_context 'データ作成', Zlib.crc32(SecureRandom.uuid)
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[*]顧客コードが重複' do
      include_context '重複データ作成', Zlib.crc32(SecureRandom.uuid)
      it_behaves_like 'ToNG'
    end

    context '新規作成がnil' do
      let!(:create_flag) { nil }
      it_behaves_like '[*]顧客コードがない'
      it_behaves_like '[*]顧客コードが正常値'
      it_behaves_like '[*]顧客コードが重複'
    end
    context "新規作成が'true'" do
      let!(:create_flag) { 'true' }
      it_behaves_like '[*]顧客コードがない'
      it_behaves_like '[*]顧客コードが正常値'
      it_behaves_like '[*]顧客コードが重複'
    end
    context "新規作成が'false'" do
      let!(:create_flag) { 'false' }
      it_behaves_like '[*]顧客コードがない'
      it_behaves_like '[*]顧客コードが正常値'
      # it_behaves_like '[*]顧客コードが重複' # Tips: 存在しないケース
    end
  end

  # 組織・団体名
  # 前提条件
  #   新規作成が正常値
  # テストパターン
  #   新規作成: nil, 'true', 'false' → データ作成
  #   組織・団体名: ない, 最小文字数よりも少ない, 最小文字数, 最大文字数, 最大文字数よりも多い → データ作成
  describe 'validates :name' do
    shared_context 'データ作成' do |name|
      let!(:customer) { FactoryBot.build(:customer, create_flag: create_flag, name: name) }
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
    shared_examples_for '[*]組織・団体名がない' do
      include_context 'データ作成', ''
      it_behaves_like 'ToNG'
    end
    shared_examples_for '[*]組織・団体名が最小文字数よりも少ない' do
      include_context 'データ作成', 'a' * (Settings['customer_name_minimum'] - 1)
      it_behaves_like 'ToNG'
    end
    shared_examples_for '[*]組織・団体名が最小文字数' do
      include_context 'データ作成', 'a' * Settings['customer_name_minimum']
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[*]組織・団体名が最大文字数' do
      include_context 'データ作成', 'a' * Settings['customer_name_maximum']
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[*]組織・団体名が最大文字数よりも多い' do
      include_context 'データ作成', 'a' * (Settings['customer_name_maximum'] + 1)
      it_behaves_like 'ToNG'
    end

    context '新規作成がnil' do
      let!(:create_flag) { nil }
      it_behaves_like '[*]組織・団体名がない'
      it_behaves_like '[*]組織・団体名が最小文字数よりも少ない'
      it_behaves_like '[*]組織・団体名が最小文字数'
      it_behaves_like '[*]組織・団体名が最大文字数'
      it_behaves_like '[*]組織・団体名が最大文字数よりも多い'
    end
    context "新規作成が'true'" do
      let!(:create_flag) { 'true' }
      it_behaves_like '[*]組織・団体名がない'
      it_behaves_like '[*]組織・団体名が最小文字数よりも少ない'
      it_behaves_like '[*]組織・団体名が最小文字数'
      it_behaves_like '[*]組織・団体名が最大文字数'
      it_behaves_like '[*]組織・団体名が最大文字数よりも多い'
    end
    context "新規作成が'false'" do
      let!(:create_flag) { 'false' }
      # it_behaves_like '[*]組織・団体名がない' # Tips: 存在しないケース
      # it_behaves_like '[*]組織・団体名が最小文字数よりも少ない' # Tips: 存在しないケース
      it_behaves_like '[*]組織・団体名が最小文字数'
      it_behaves_like '[*]組織・団体名が最大文字数'
      # it_behaves_like '[*]組織・団体名が最大文字数よりも多い' # Tips: 存在しないケース
    end
  end
end
