require 'rails_helper'

RSpec.describe User, type: :model do
  # コード
  # テストパターン
  #   ない, 正常値, 重複
  describe 'validates :code' do
    subject(:model) { FactoryBot.build_stubbed(:user, code:) }
    let(:valid_code) { Utils::UniqueCodeGenerator.base36_uuid }

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

  # 削除対象でフィルタ
  # テストパターン
  #   削除予定日時: ない, 過去, 現在, 未来
  describe '.destroy_target' do
    subject { described_class.destroy_target }

    let_it_be(:start_time) { Time.current }
    before { allow(Time).to receive(:current).and_return(start_time) }

    before_all { FactoryBot.create(:user, destroy_schedule_at: nil) }
    let_it_be(:included_values) do
      [
        FactoryBot.create(:user, name: '過去', destroy_schedule_at: start_time - 1.second),
        FactoryBot.create(:user, name: '現在', destroy_schedule_at: start_time)
      ]
    end
    before_all { FactoryBot.create(:user, name: '未来', destroy_schedule_at: start_time + 1.second) }

    it_behaves_like 'Array', '対象ユーザー'
  end

  # 削除予約済みか返却
  # テストパターン
  #   削除予定日時: ない（予約なし）, ある（予約済み）
  describe '#destroy_reserved?' do
    subject { user.destroy_reserved? }
    let(:user) { FactoryBot.build_stubbed(:user, destroy_schedule_at:) }

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

    let!(:start_time) { Time.current }
    let(:current_user) { described_class.find(user.id) }

    it '削除依頼日時が現在日時、削除予定日時が現在日時＋設定日数に変更され、保存される' do
      is_expected.to be(true)
      expect(current_user.destroy_requested_at).to be_between(start_time.floor, Time.current.ceil)
      expect(current_user.destroy_schedule_at).to be_between(start_time.floor + Settings.user_destroy_schedule_days.days,
                                                             Time.current.ceil + Settings.user_destroy_schedule_days.days)
    end
  end

  # 削除予約取り消し
  # 前提条件
  #   削除予約済み
  describe '#set_undo_destroy_reserve!' do
    subject { user.set_undo_destroy_reserve! }
    let(:user) { FactoryBot.create(:user, :destroy_reserved) }

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

    shared_examples '設定値' do |version|
      let(:version) { version }

      it 'デフォルトではないURL' do
        is_expected.not_to be_blank
        is_expected.not_to include('_noimage.jpg')
      end
    end
    shared_examples 'デフォルト' do |version|
      let(:version) { version }

      it 'デフォルトのURL' do
        is_expected.to include('_noimage.jpg')
      end
    end
    shared_examples '未定義' do
      let(:version) { nil }

      it 'URLが返却されない' do
        is_expected.to be_blank
      end
    end

    context '画像がない' do
      let_it_be(:user) { FactoryBot.create(:user) }

      it_behaves_like 'デフォルト', :mini
      it_behaves_like 'デフォルト', :small
      it_behaves_like 'デフォルト', :medium
      it_behaves_like 'デフォルト', :large
      it_behaves_like 'デフォルト', :xlarge
      it_behaves_like '未定義'
    end
    context '画像がある' do
      let_it_be(:image) { fixture_file_upload(TEST_IMAGE_FILE, TEST_IMAGE_TYPE) }
      let_it_be(:user)  { FactoryBot.create(:user, image:) }

      it_behaves_like '設定値', :mini
      it_behaves_like '設定値', :small
      it_behaves_like '設定値', :medium
      it_behaves_like '設定値', :large
      it_behaves_like '設定値', :xlarge
      it_behaves_like '未定義'
    end
  end

  # お知らせの未読数を返却
  # テストパターン
  #   お知らせ確認最終開始日時: ない, 現在
  #     地域: 全て, 一致, 不一致
  #     対象: 全員, 対象ユーザーのみ（自分, 他人）
  describe '#infomation_unread_count' do
    subject { user.infomation_unread_count }

    before { user.cache_infomation_unread_count = nil }
    let(:cache) { user.cache_infomation_unread_count }

    let_it_be(:start_time) { Time.current.floor }
    before { allow(Time).to receive(:current).and_return(start_time) }

    let_it_be(:other_user) { FactoryBot.create(:user) }
    let_it_be(:started_at) { start_time - 1.second }
    before_all do
      FactoryBot.create(:infomation, :other_locale, :all, started_at:)
      FactoryBot.create(:infomation, :all_locale, :user, user: other_user, started_at:)
    end
    shared_context '対象のお知らせ作成' do
      let_it_be(:inside_infomations) do
        [
          FactoryBot.create(:infomation, :all_locale, :all, started_at:),
          FactoryBot.create(:infomation, :my_locale, :user, user:, started_at:)
        ]
      end
    end

    shared_examples '件数' do
      it '件数が返却され、キャッシュされる' do
        is_expected.to eq(expect_count)
        expect(cache).to eq(expect_count)
      end
    end

    context 'お知らせ確認最終開始日時がない' do
      let_it_be(:user) { FactoryBot.create(:user, infomation_check_last_started_at: nil) }
      include_context '対象のお知らせ作成'

      let(:expect_count) { inside_infomations.count }

      it_behaves_like '件数'
    end
    context 'お知らせ確認最終開始日時が現在' do
      let_it_be(:user) { FactoryBot.create(:user, infomation_check_last_started_at: start_time) }
      include_context '対象のお知らせ作成'

      let(:expect_count) { 0 }

      it_behaves_like '件数'
    end
  end
end
