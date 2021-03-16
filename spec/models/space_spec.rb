require 'rails_helper'

RSpec.describe Space, type: :model do
  # サブドメイン
  # 前提条件
  #   なし
  # テストパターン
  #   ない, 最小文字数よりも少ない, 最小文字数と同じ, 最大文字数と同じ, 最大文字数よりも多い,
  #     アルファベット(小文字)・数字・ハイフン(先頭不可), アルファベット(大文字),
  #     ハイフン(先頭), ハイフン(後尾), 重複（同じ顧客）, 重複（違う顧客） → データ作成
  describe 'validates :subdomain' do
    let!(:customers) { FactoryBot.create_list(:customer, 2) }
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
    context 'ない' do
      include_context 'データ作成', ''
      it_behaves_like 'ToNG'
    end
    context '最小文字数よりも少ない' do
      include_context 'データ作成', 'a' * (Settings['subdomain_minimum'] - 1)
      it_behaves_like 'ToNG'
    end
    context '最小文字数と同じ' do
      include_context 'データ作成', 'a' * Settings['subdomain_minimum']
      it_behaves_like 'ToOK'
    end
    context '最大文字数と同じ' do
      include_context 'データ作成', 'a' * Settings['subdomain_maximum']
      it_behaves_like 'ToOK'
    end
    context '最大文字数よりも多い' do
      include_context 'データ作成', 'a' * (Settings['subdomain_maximum'] + 1)
      it_behaves_like 'ToNG'
    end
    context 'アルファベット(小文字)・数字・ハイフン(先頭不可)' do
      include_context 'データ作成', "#{'a' * [Settings['subdomain_minimum'] - 4, 1].max}z09-"
      it_behaves_like 'ToOK'
    end
    context 'アルファベット(大文字)' do
      include_context 'データ作成', 'A' * Settings['subdomain_minimum']
      it_behaves_like 'ToNG'
    end
    context 'ハイフン(先頭)' do
      include_context 'データ作成', "-#{'a' * [Settings['subdomain_minimum'] - 1, 1].max}"
      it_behaves_like 'ToNG'
    end
    context 'ハイフン(後尾)' do
      include_context 'データ作成', "#{'a' * [Settings['subdomain_minimum'] - 1, 1].max}-"
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

  # スペース名
  # 前提条件
  #   なし
  # テストパターン
  #   ない, 最小文字数よりも少ない, 最小文字数と同じ, 最大文字数と同じ, 最大文字数よりも多い → データ作成
  describe 'validates :name' do
    let!(:customer) { FactoryBot.create(:customer) }
    shared_context 'データ作成' do |name|
      let!(:space) { FactoryBot.build(:space, customer_id: customer.id, name: name) }
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
    context 'ない' do
      include_context 'データ作成', ''
      it_behaves_like 'ToNG'
    end
    context '最小文字数よりも少ない' do
      include_context 'データ作成', 'a' * (Settings['space_name_minimum'] - 1)
      it_behaves_like 'ToNG'
    end
    context '最小文字数と同じ' do
      include_context 'データ作成', 'a' * Settings['space_name_minimum']
      it_behaves_like 'ToOK'
    end
    context '最大文字数と同じ' do
      include_context 'データ作成', 'a' * Settings['space_name_maximum']
      it_behaves_like 'ToOK'
    end
    context '最大文字数よりも多い' do
      include_context 'データ作成', 'a' * (Settings['space_name_maximum'] + 1)
      it_behaves_like 'ToNG'
    end
  end

  # 目的
  # 前提条件
  #   なし
  # テストパターン
  #   最小文字数よりも少ない, 最小文字数と同じ, 最大文字数と同じ, 最大文字数よりも多い → データ作成
  describe 'validates :purpose' do
    let!(:customer) { FactoryBot.create(:customer) }
    shared_context 'データ作成' do |purpose|
      let!(:space) { FactoryBot.build(:space, customer_id: customer.id, purpose: purpose) }
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
    context '最小文字数よりも少ない' do
      include_context 'データ作成', 'a' * (Settings['space_purpose_minimum'] - 1)
      it_behaves_like 'ToNG'
    end
    context '最小文字数と同じ' do
      include_context 'データ作成', 'a' * Settings['space_purpose_minimum']
      it_behaves_like 'ToOK'
    end
    context '最大文字数と同じ' do
      include_context 'データ作成', 'a' * Settings['space_purpose_maximum']
      it_behaves_like 'ToOK'
    end
    context '最大文字数よりも多い' do
      include_context 'データ作成', 'a' * (Settings['space_purpose_maximum'] + 1)
      it_behaves_like 'ToNG'
    end
  end

  # 画像URLを返却
  # 前提条件
  #   なし
  # テストパターン
  #   画像: ない, ある
  #   mini, small, medium, large, xlarge, 未定義
  describe 'image_url' do
    let!(:customer) { FactoryBot.create(:customer) }
    let!(:space) { FactoryBot.create(:space, customer_id: customer.id) }

    # テスト内容
    shared_examples_for 'ToOK' do |version|
      it 'URLが返却される' do
        expect(space.image_url(version)).not_to be_nil
      end
    end
    shared_examples_for 'ToNG' do |version|
      it 'URLが返却されない' do
        expect(space.image_url(version)).to eq('')
      end
    end

    # テストケース
    context '画像がない' do
      it_behaves_like 'ToOK', :mini
      it_behaves_like 'ToOK', :small
      it_behaves_like 'ToOK', :medium
      it_behaves_like 'ToOK', :large
      it_behaves_like 'ToOK', :xlarge
      it_behaves_like 'ToNG', nil
    end
    context '画像がある' do
      include_context '画像登録処理（スペース）'
      it_behaves_like 'ToOK', :mini
      it_behaves_like 'ToOK', :small
      it_behaves_like 'ToOK', :medium
      it_behaves_like 'ToOK', :large
      it_behaves_like 'ToOK', :xlarge
      it_behaves_like 'ToNG', nil
      include_context '画像削除処理（スペース）'
    end
  end
end
