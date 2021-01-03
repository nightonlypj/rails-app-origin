require 'rails_helper'

RSpec.describe User, type: :model do
  # ユーザーコード
  # 前提条件
  #   なし
  # テストパターン
  #   空, 正常値 → データ作成
  describe 'validates :code' do
    shared_context 'データ作成' do |code|
      let!(:user) { FactoryBot.build(:user, code: code) }
    end

    # テスト内容
    shared_examples_for 'ToOK' do
      it 'OK' do
        expect(user).to be_valid
      end
    end
    shared_examples_for 'ToNG' do
      it 'NG' do
        expect(user).not_to be_valid
      end
    end

    # テストケース
    context '空' do
      include_context 'データ作成', ''
      it_behaves_like 'ToNG'
    end
    context '正常値' do
      include_context 'データ作成', Digest::MD5.hexdigest(SecureRandom.uuid)
      it_behaves_like 'ToOK'
    end
  end

  # 表示名
  # 前提条件
  #   なし
  # テストパターン
  #   最小文字数よりも少ない, 最小文字数, 最大文字数, 最大文字数よりも多い → データ作成
  describe 'validates :name' do
    shared_context 'データ作成' do |name|
      let!(:user) { FactoryBot.build(:user, name: name) }
    end

    # テスト内容
    shared_examples_for 'ToOK' do
      it 'OK' do
        expect(user).to be_valid
      end
    end
    shared_examples_for 'ToNG' do
      it 'NG' do
        expect(user).not_to be_valid
      end
    end

    # テストケース
    context '最小文字数よりも少ない' do
      include_context 'データ作成', 'a' * (Settings['user_name_minimum'] - 1)
      it_behaves_like 'ToNG'
    end
    context '最小文字数' do
      include_context 'データ作成', 'a' * Settings['user_name_minimum']
      it_behaves_like 'ToOK'
    end
    context '最大文字数' do
      include_context 'データ作成', 'a' * Settings['user_name_maximum']
      it_behaves_like 'ToOK'
    end
    context '最大文字数よりも多い' do
      include_context 'データ作成', 'a' * (Settings['user_name_maximum'] + 1)
      it_behaves_like 'ToNG'
    end
  end

  # 削除予約済みか返却
  # 前提条件
  #   なし
  # テストパターン
  #   削除予定日時: なし, あり → データ作成
  describe 'def destroy_reserved?' do
    shared_context 'データ作成' do |destroy_schedule_at|
      let!(:user) { FactoryBot.create(:user, destroy_schedule_at: destroy_schedule_at) }
    end

    # テストケース・内容
    context '削除予定日時なし' do
      include_context 'データ作成', nil
      it 'false' do
        expect(user.destroy_reserved?).to eq(false)
      end
    end
    context '削除予定日時あり' do
      include_context 'データ作成', Time.current
      it 'true' do
        expect(user.destroy_reserved?).to eq(true)
      end
    end
  end

  # 削除予約
  # 前提条件
  #   削除予定日時: なし
  # テストパターン
  #   なし
  describe 'def set_destroy_reserve' do
    let!(:user) { FactoryBot.create(:user) }

    # テストケース・内容
    context '削除依頼日時' do
      let!(:start_time) { Time.current }
      it '現在日時' do
        user.set_destroy_reserve
        expect(user.destroy_requested_at).to be_between(start_time, Time.current)
      end
    end
    context '削除予定日時' do
      let!(:start_time) { Time.current + Settings['destroy_schedule_days'].days }
      it '現在日時＋設定日数' do
        user.set_destroy_reserve
        expect(user.destroy_schedule_at).to be_between(start_time, Time.current + Settings['destroy_schedule_days'].days)
      end
    end
  end

  # 削除予約取り消し
  # 前提条件
  #   削除予定日時: あり
  # テストパターン
  #   なし
  describe 'def set_undo_destroy_reserve' do
    let!(:user) { FactoryBot.create(:user, destroy_requested_at: Time.current, destroy_schedule_at: Time.current + Settings['destroy_schedule_days'].days) }

    # テストケース・内容
    context '削除依頼日時' do
      it '空' do
        user.set_undo_destroy_reserve
        expect(user.destroy_requested_at).to be_nil
      end
    end
    context '削除予定日時' do
      it '空' do
        user.set_undo_destroy_reserve
        expect(user.destroy_schedule_at).to be_nil
      end
    end
  end

  # ユーザーの画像URLを返却
  # 前提条件
  #   なし
  # テストパターン
  #   画像: なし, あり
  #   mini, small, medium, large, 未定義
  describe 'def image_url' do
    let!(:user) { FactoryBot.create(:user) }

    # テスト内容
    shared_examples_for 'ToOK' do |version|
      it 'URLあり' do
        expect(user.image_url(version)).not_to be_nil
      end
    end
    shared_examples_for 'ToNG' do |version|
      it 'URLなし' do
        expect(user.image_url(version)).to eq('')
      end
    end

    # テストケース
    context '画像なし' do
      it_behaves_like 'ToOK', :mini
      it_behaves_like 'ToOK', :small
      it_behaves_like 'ToOK', :medium
      it_behaves_like 'ToOK', :large
      it_behaves_like 'ToNG', nil
    end
    context '画像あり' do
      include_context '画像登録処理'
      it_behaves_like 'ToOK', :mini
      it_behaves_like 'ToOK', :small
      it_behaves_like 'ToOK', :medium
      it_behaves_like 'ToOK', :large
      it_behaves_like 'ToNG', nil
      include_context '画像削除処理'
    end
  end
end
