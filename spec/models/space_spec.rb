require 'rails_helper'

RSpec.describe Space, type: :model do
  let_it_be(:user) { FactoryBot.create(:user) }

  # コード
  # テストパターン
  #   ない, 正常値, 重複
  describe 'validates :code' do
    let(:model) { FactoryBot.build_stubbed(:space, code:) }
    let(:valid_code) { Digest::MD5.hexdigest(SecureRandom.uuid) }

    # テストケース
    context 'ない' do
      let(:code) { nil }
      let(:messages) { { code: [get_locale('activerecord.errors.models.space.attributes.code.blank')] } }
      it_behaves_like 'InValid'
    end
    context '正常値' do
      let(:code) { valid_code }
      it_behaves_like 'Valid'
    end
    context '重複' do
      before { FactoryBot.create(:space, code:, created_user: user) }
      let(:code) { valid_code }
      let(:messages) { { code: [get_locale('activerecord.errors.models.space.attributes.code.taken')] } }
      it_behaves_like 'InValid'
    end
  end

  # 名称
  # テストパターン
  #   ない, 最小文字数より少ない, 最小文字数と同じ, 最大文字数と同じ, 最大文字数より多い
  describe 'validates :name' do
    let(:model) { FactoryBot.build_stubbed(:space, name:) }

    # テストケース
    context 'ない' do
      let(:name) { nil }
      let(:messages) { { name: [get_locale('activerecord.errors.models.space.attributes.name.blank')] } }
      it_behaves_like 'InValid'
    end
    context '最小文字数より少ない' do
      let(:name) { 'a' * (Settings.space_name_minimum - 1) }
      let(:messages) { { name: [get_locale('activerecord.errors.models.space.attributes.name.too_short', count: Settings.space_name_minimum)] } }
      it_behaves_like 'InValid'
    end
    context '最小文字数と同じ' do
      let(:name) { 'a' * Settings.space_name_minimum }
      it_behaves_like 'Valid'
    end
    context '最大文字数と同じ' do
      let(:name) { 'a' * Settings.space_name_maximum }
      it_behaves_like 'Valid'
    end
    context '最大文字数より多い' do
      let(:name) { 'a' * (Settings.space_name_maximum + 1) }
      let(:messages) { { name: [get_locale('activerecord.errors.models.space.attributes.name.too_long', count: Settings.space_name_maximum)] } }
      it_behaves_like 'InValid'
    end
  end

  # 説明
  # テストパターン
  #   ない, 最大文字数と同じ, 最大文字数より多い
  describe 'validates :description' do
    let(:model) { FactoryBot.build_stubbed(:space, description:) }

    # テストケース
    context 'ない' do
      let(:description) { nil }
      it_behaves_like 'Valid'
    end
    context '最大文字数と同じ' do
      let(:description) { 'a' * Settings.space_description_maximum }
      it_behaves_like 'Valid'
    end
    context '最大文字数より多い' do
      let(:description) { 'a' * (Settings.space_description_maximum + 1) }
      let(:messages) { { description: [get_locale('activerecord.errors.models.space.attributes.description.too_long', count: Settings.space_description_maximum)] } }
      it_behaves_like 'InValid'
    end
  end

  # 非公開
  # テストパターン
  #   ない, true, false
  describe 'validates :private' do
    let(:model) { FactoryBot.build_stubbed(:space, private:) }

    # テストケース
    context 'ない' do
      let(:private) { nil }
      let(:messages) { { private: [get_locale('activerecord.errors.models.space.attributes.private.inclusion')] } }
      it_behaves_like 'InValid'
    end
    context 'true' do
      let(:private) { true }
      it_behaves_like 'Valid'
    end
    context 'false' do
      let(:private) { false }
      it_behaves_like 'Valid'
    end
  end

  # 削除予約済みか返却
  # テストパターン
  #   削除予定日時: ない（予約なし）, ある（予約済み）
  describe '#destroy_reserved?' do
    subject { space.destroy_reserved? }
    let(:space) { FactoryBot.build_stubbed(:space, destroy_schedule_at:) }

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
    subject { space.set_destroy_reserve! }
    let(:space) { FactoryBot.create(:space, created_user: user) }
    let(:current_space) { Space.find(space.id) }

    let!(:start_time) { Time.current.floor }
    let!(:start_time_schedule) { Time.current.floor + Settings.space_destroy_schedule_days.days }
    it '削除依頼日時が現在日時、削除予定日時が現在日時＋設定日数に変更され、保存される' do
      is_expected.to eq(true)
      expect(current_space.destroy_requested_at).to be_between(start_time, Time.current)
      expect(current_space.destroy_schedule_at).to be_between(start_time_schedule, Time.current + Settings.space_destroy_schedule_days.days)
    end
  end

  # 削除予約取り消し
  # 前提条件
  #   削除予約済み
  describe '#set_undo_destroy_reserve!' do
    subject { space.set_undo_destroy_reserve! }
    let(:space) { FactoryBot.create(:space, :destroy_reserved, created_user: user) }
    let(:current_space) { Space.find(space.id) }

    it '削除依頼日時・削除予定日時がなしに変更される' do
      is_expected.to eq(true)
      expect(space.destroy_requested_at).to be_nil
      expect(space.destroy_schedule_at).to be_nil
    end
  end

  # 画像URLを返却
  # テストパターン
  #   画像: ない, ある
  #   mini, small, medium, large, xlarge, 未定義
  describe '#image_url' do
    subject { space.image_url(version) }

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
      let_it_be(:space) { FactoryBot.create(:space, created_user: user) }
      it_behaves_like 'Def', :mini, true
      it_behaves_like 'Def', :small, true
      it_behaves_like 'Def', :medium, true
      it_behaves_like 'Def', :large, true
      it_behaves_like 'Def', :xlarge, true
      it_behaves_like 'Not', nil
    end
    context '画像がある' do
      let_it_be(:image) { fixture_file_upload(TEST_IMAGE_FILE, TEST_IMAGE_TYPE) }
      let_it_be(:space) { FactoryBot.create(:space, image:, created_user: user) }
      it_behaves_like 'OK', :mini, false
      it_behaves_like 'OK', :small, false
      it_behaves_like 'OK', :medium, false
      it_behaves_like 'OK', :large, false
      it_behaves_like 'OK', :xlarge, false
      it_behaves_like 'Not', nil
    end
  end

  # 最終更新日時
  # テストパターン
  #   更新日時: 作成日時と同じ, 作成日時以降
  describe '#last_updated_at' do
    subject { space.last_updated_at }

    # テストケース
    context '更新日時が作成日時と同じ' do
      let(:space) { FactoryBot.create(:space, created_user: user) }
      it_behaves_like 'Value', nil, 'nil'
    end
    context '更新日時が作成日時以降' do
      let(:space) { FactoryBot.create(:space, created_user: user, created_at: Time.current - 1.hour, updated_at: Time.current) }
      it '更新日時' do
        is_expected.to eq(space.updated_at)
      end
    end
  end
end
