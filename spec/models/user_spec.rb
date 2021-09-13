require 'rails_helper'

RSpec.describe User, type: :model do
  # ユーザーコード
  # 前提条件
  #   なし
  # テストパターン
  #   ない, 正常値, 重複
  describe 'validates :code' do
    let(:user)       { FactoryBot.build_stubbed(:user, code: code) }
    let(:valid_code) { Digest::MD5.hexdigest(SecureRandom.uuid) }

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
    context 'ない' do
      let(:code) { nil }
      it_behaves_like 'ToNG'
    end
    context '正常値' do
      let(:code) { valid_code }
      it_behaves_like 'ToOK'
    end
    context '重複' do
      before { FactoryBot.create(:user, code: code) }
      let(:code) { valid_code }
      it_behaves_like 'ToNG'
    end
  end

  # 氏名
  # 前提条件
  #   なし
  # テストパターン
  #   ない, 最小文字数よりも少ない, 最小文字数と同じ, 最大文字数と同じ, 最大文字数よりも多い
  describe 'validates :name' do
    let(:user) { FactoryBot.build_stubbed(:user, name: name) }

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
    context 'ない' do
      let(:name) { nil }
      it_behaves_like 'ToNG'
    end
    context '最小文字数よりも少ない' do
      let(:name) { 'a' * (Settings['user_name_minimum'] - 1) }
      it_behaves_like 'ToNG'
    end
    context '最小文字数と同じ' do
      let(:name) { 'a' * Settings['user_name_minimum'] }
      it_behaves_like 'ToOK'
    end
    context '最大文字数と同じ' do
      let(:name) { 'a' * Settings['user_name_maximum'] }
      it_behaves_like 'ToOK'
    end
    context '最大文字数よりも多い' do
      let(:name) { 'a' * (Settings['user_name_maximum'] + 1) }
      it_behaves_like 'ToNG'
    end
  end

  # 削除予約済みか返却
  # 前提条件
  #   なし
  # テストパターン
  #   削除予定日時: ない（予約なし）, ある（予約済み）
  describe 'destroy_reserved?' do
    let(:user) { FactoryBot.build_stubbed(:user, destroy_schedule_at: destroy_schedule_at) }

    context '削除予定日時がない（予約なし）' do
      let(:destroy_schedule_at) { nil }
      it 'false' do
        expect(user.destroy_reserved?).to eq(false)
      end
    end
    context '削除予定日時がある（予約済み）' do
      let(:destroy_schedule_at) { Time.current }
      it 'true' do
        expect(user.destroy_reserved?).to eq(true)
      end
    end
  end

  # 削除予約
  # 前提条件
  #   削除予約なし
  # テストパターン
  #   なし
  describe 'set_destroy_reserve' do
    let(:user) { FactoryBot.create(:user) }

    context '削除依頼日時' do
      let!(:start_time) { Time.current.floor }
      it '現在日時に変更される' do
        user.set_destroy_reserve
        expect(user.destroy_requested_at).to be_between(start_time, Time.current)
      end
    end
    context '削除予定日時' do
      let!(:start_time) { Time.current.floor + Settings['destroy_schedule_days'].days }
      it '現在日時＋設定日数に変更される' do
        user.set_destroy_reserve
        expect(user.destroy_schedule_at).to be_between(start_time, Time.current + Settings['destroy_schedule_days'].days)
      end
    end
  end

  # 削除予約取り消し
  # 前提条件
  #   削除予約済み
  # テストパターン
  #   なし
  describe 'set_undo_destroy_reserve' do
    let(:user) { FactoryBot.create(:user_destroy_reserved) }

    context '削除依頼日時' do
      it 'なしに変更される' do
        user.set_undo_destroy_reserve
        expect(user.destroy_requested_at).to be_nil
      end
    end
    context '削除予定日時' do
      it 'なしに変更される' do
        user.set_undo_destroy_reserve
        expect(user.destroy_schedule_at).to be_nil
      end
    end
  end

  # 画像URLを返却
  # 前提条件
  #   なし
  # テストパターン
  #   画像: ない, ある
  #   mini, small, medium, large, xlarge, 未定義
  describe 'image_url' do
    let(:user) { FactoryBot.create(:user, image: image) }

    # テスト内容
    shared_examples_for 'ToOK' do |version|
      it 'デフォルトではないURL' do
        expect(user.image_url(version)).not_to be_nil
        expect(user.image_url(version)).not_to include('_noimage.jpg')
      end
    end
    shared_examples_for 'ToNot' do |version|
      it 'デフォルトのURL' do
        expect(user.image_url(version)).to include('_noimage.jpg')
      end
    end
    shared_examples_for 'ToNG' do |version|
      it 'URLが返却されない' do
        expect(user.image_url(version)).to be_blank
      end
    end

    # テストケース
    context '画像がない' do
      let(:image) { nil }
      it_behaves_like 'ToNot', :mini, true
      it_behaves_like 'ToNot', :small, true
      it_behaves_like 'ToNot', :medium, true
      it_behaves_like 'ToNot', :large, true
      it_behaves_like 'ToNot', :xlarge, true
      it_behaves_like 'ToNG', nil
    end
    context '画像がある' do
      let(:image) { fixture_file_upload(TEST_IMAGE_FILE, TEST_IMAGE_TYPE) }
      include_context '画像削除処理'
      it_behaves_like 'ToOK', :mini, false
      it_behaves_like 'ToOK', :small, false
      it_behaves_like 'ToOK', :medium, false
      it_behaves_like 'ToOK', :large, false
      it_behaves_like 'ToOK', :xlarge, false
      it_behaves_like 'ToNG', nil
    end
  end
end
