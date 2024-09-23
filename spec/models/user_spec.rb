require 'rails_helper'

RSpec.describe User, type: :model do
  # テスト内容（共通）
  shared_examples_for 'Count' do |count|
    it "#{count}が返却され、キャッシュされる" do
      is_expected.to eq(count)
      expect(cache).to eq(count)
    end
  end

  # コード
  # テストパターン
  #   ない, 正常値, 重複
  describe 'validates :code' do
    subject(:model) { FactoryBot.build_stubbed(:user, code:) }
    let(:valid_code) { Digest::MD5.hexdigest(SecureRandom.uuid) }

    # テストケース
    context 'ない' do
      let(:code) { nil }
      let(:messages) { { code: [get_locale('activerecord.errors.models.user.attributes.code.blank')] } }
      it_behaves_like 'InValid'
    end
    context '正常値' do
      let(:code) { valid_code }
      it_behaves_like 'Valid'
    end
    context '重複' do
      before { FactoryBot.create(:user, code:) }
      let(:code) { valid_code }
      let(:messages) { { code: [get_locale('activerecord.errors.models.user.attributes.code.taken')] } }
      it_behaves_like 'InValid'
    end
  end

  # 氏名
  # テストパターン
  #   ない, 最小文字数より少ない, 最小文字数と同じ, 最大文字数と同じ, 最大文字数より多い
  describe 'validates :name' do
    subject(:model) { FactoryBot.build_stubbed(:user, name:) }

    # テストケース
    context 'ない' do
      let(:name) { nil }
      let(:messages) { { name: [get_locale('activerecord.errors.models.user.attributes.name.blank')] } }
      it_behaves_like 'InValid'
    end
    context '最小文字数より少ない' do
      let(:name) { 'a' * (Settings.user_name_minimum - 1) }
      let(:messages) { { name: [get_locale('activerecord.errors.models.user.attributes.name.too_short', count: Settings.user_name_minimum)] } }
      it_behaves_like 'InValid'
    end
    context '最小文字数と同じ' do
      let(:name) { 'a' * Settings.user_name_minimum }
      it_behaves_like 'Valid'
    end
    context '最大文字数と同じ' do
      let(:name) { 'a' * Settings.user_name_maximum }
      it_behaves_like 'Valid'
    end
    context '最大文字数より多い' do
      let(:name) { 'a' * (Settings.user_name_maximum + 1) }
      let(:messages) { { name: [get_locale('activerecord.errors.models.user.attributes.name.too_long', count: Settings.user_name_maximum)] } }
      it_behaves_like 'InValid'
    end
  end

  # 削除予約済みか返却
  # テストパターン
  #   削除予定日時: ない（予約なし）, ある（予約済み）
  describe '#destroy_reserved?' do
    subject { user.destroy_reserved? }
    let(:user) { FactoryBot.build_stubbed(:user, destroy_schedule_at:) }

    # テストケース
    context '削除予定日時がない（予約なし）' do
      let(:destroy_schedule_at) { nil }
      it_behaves_like 'Value', false
    end
    context '削除予定日時がある（予約済み）' do
      let(:destroy_schedule_at) { Time.current }
      it_behaves_like 'Value', true
    end
  end

  # 削除予約
  # 前提条件
  #   削除予約なし
  describe '#set_destroy_reserve!' do
    subject { user.set_destroy_reserve! }
    let(:user) { FactoryBot.create(:user) }

    let(:current_user) { described_class.find(user.id) }
    let!(:start_time) { Time.current.floor }
    let!(:start_time_schedule) { Time.current.floor + Settings.user_destroy_schedule_days.days }
    it '削除依頼日時が現在日時、削除予定日時が現在日時＋設定日数に変更され、保存される' do
      is_expected.to be(true)
      expect(current_user.destroy_requested_at).to be_between(start_time, Time.current)
      expect(current_user.destroy_schedule_at).to be_between(start_time_schedule, Time.current + Settings.user_destroy_schedule_days.days)
    end
  end

  # 削除予約取り消し
  # 前提条件
  #   削除予約済み
  describe '#set_undo_destroy_reserve!' do
    subject { user.set_undo_destroy_reserve! }
    let(:user) { FactoryBot.create(:user, :destroy_reserved) }

    let(:current_user) { described_class.find(user.id) }
    it '削除依頼日時・削除予定日時がなしに変更される' do
      is_expected.to be(true)
      expect(user.destroy_requested_at).to be_nil
      expect(user.destroy_schedule_at).to be_nil
    end
  end

  # 画像URLを返却
  # テストパターン
  #   画像: ない, ある
  #   mini, small, medium, large, xlarge, 未定義
  describe '#image_url' do
    subject { user.image_url(version) }

    # テスト内容
    shared_examples_for 'OK' do |version|
      let(:version) { version }
      it 'デフォルトではないURL' do
        is_expected.not_to be_blank
        is_expected.not_to include('_noimage.jpg')
      end
    end
    shared_examples_for 'Def' do |version|
      let(:version) { version }
      it 'デフォルトのURL' do
        is_expected.to include('_noimage.jpg')
      end
    end
    shared_examples_for 'Not' do |version|
      let(:version) { version }
      it 'URLが返却されない' do
        is_expected.to be_blank
      end
    end

    # テストケース
    context '画像がない' do
      let_it_be(:user) { FactoryBot.create(:user) }
      it_behaves_like 'Def', :mini, true
      it_behaves_like 'Def', :small, true
      it_behaves_like 'Def', :medium, true
      it_behaves_like 'Def', :large, true
      it_behaves_like 'Def', :xlarge, true
      it_behaves_like 'Not', nil
    end
    context '画像がある' do
      let_it_be(:image) { fixture_file_upload(TEST_IMAGE_FILE, TEST_IMAGE_TYPE) }
      let_it_be(:user)  { FactoryBot.create(:user, image:) }
      it_behaves_like 'OK', :mini, false
      it_behaves_like 'OK', :small, false
      it_behaves_like 'OK', :medium, false
      it_behaves_like 'OK', :large, false
      it_behaves_like 'OK', :xlarge, false
      it_behaves_like 'Not', nil
    end
  end

  # お知らせの未読数を返却
  # テストパターン
  #   お知らせ確認最終開始日時: ない, 過去, 現在
  #   お知らせ対象: 0件, 1件（全員）, 1件（自分）, 2件（全員＋自分）
  describe '#infomation_unread_count' do
    subject do
      user.cache_infomation_unread_count = nil
      user.infomation_unread_count
    end

    # テストケース
    let(:cache) { user.cache_infomation_unread_count }
    shared_examples_for '[*]0件' do
      include_context 'お知らせ一覧作成', 0, 0, 0, 0
      it_behaves_like 'Count', 0
    end
    shared_examples_for '[ない/過去]1件（全員）' do
      include_context 'お知らせ一覧作成', 1, 0, 0, 0
      it_behaves_like 'Count', 1
    end
    shared_examples_for '[現在]1件（全員）' do
      include_context 'お知らせ一覧作成', 1, 0, 0, 0
      it_behaves_like 'Count', 0
    end
    shared_examples_for '[ない/過去]1件（自分）' do
      include_context 'お知らせ一覧作成', 0, 0, 1, 0
      it_behaves_like 'Count', 1
    end
    shared_examples_for '[現在]1件（自分）' do
      include_context 'お知らせ一覧作成', 0, 0, 1, 0
      it_behaves_like 'Count', 0
    end
    shared_examples_for '[ない/過去]2件（全員＋自分）' do
      include_context 'お知らせ一覧作成', 0, 1, 0, 1
      it_behaves_like 'Count', 2
    end
    shared_examples_for '[現在]2件（全員＋自分）' do
      include_context 'お知らせ一覧作成', 0, 1, 0, 1
      it_behaves_like 'Count', 0
    end

    context 'お知らせ確認最終開始日時がない' do
      let_it_be(:user) { FactoryBot.create(:user) }
      it_behaves_like '[*]0件'
      it_behaves_like '[ない/過去]1件（全員）'
      it_behaves_like '[ない/過去]1件（自分）'
      it_behaves_like '[ない/過去]2件（全員＋自分）'
    end
    context 'お知らせ確認最終開始日時が過去' do
      let_it_be(:user) { FactoryBot.create(:user, infomation_check_last_started_at: Time.current - 1.month) }
      it_behaves_like '[*]0件'
      it_behaves_like '[ない/過去]1件（全員）'
      it_behaves_like '[ない/過去]1件（自分）'
      it_behaves_like '[ない/過去]2件（全員＋自分）'
    end
    context 'お知らせ確認最終開始日時が現在' do
      let_it_be(:user) { FactoryBot.create(:user, infomation_check_last_started_at: Time.current) }
      it_behaves_like '[*]0件'
      it_behaves_like '[現在]1件（全員）'
      it_behaves_like '[現在]1件（自分）'
      it_behaves_like '[現在]2件（全員＋自分）'
    end
  end

  # 未ダウンロード数を返却
  # テストパターン
  #   ダウンロード対象: 0件, 1件, 2件
  describe '#undownloaded_count' do
    subject do
      current_user.cache_undownloaded_count = nil
      current_user.undownloaded_count
    end
    let_it_be(:current_user) { FactoryBot.create(:user) }
    before_all do
      FactoryBot.create(:download, :success) # 他人
      FactoryBot.create(:download, :downloaded, user: current_user) # ダウンロード済み
    end

    # テストケース
    let(:cache) { current_user.cache_undownloaded_count }
    context '0件' do
      it_behaves_like 'Count', 0
    end
    context '1件' do
      before_all { FactoryBot.create(:download, :success, user: current_user) }
      it_behaves_like 'Count', 1
    end
    context '2件' do
      before_all { FactoryBot.create_list(:download, 2, :success, user: current_user) }
      it_behaves_like 'Count', 2
    end
  end
end
