require 'rails_helper'

RSpec.describe Infomation, type: :model do
  # ラベル
  # テストパターン
  #   ない, 正常値
  describe 'validates :label' do
    subject(:model) { FactoryBot.build_stubbed(:infomation, label:) }

    context 'ない' do
      let(:label) { nil }
      let(:messages) { { label: [get_locale('activerecord.errors.models.infomation.attributes.label.blank')] } }

      it_behaves_like 'InValid'
    end
    context '正常値' do
      let(:label) { :not }

      it_behaves_like 'Valid'
    end
  end

  # タイトル
  # テストパターン
  #   ない, ある
  describe 'validates :title' do
    subject(:model) { FactoryBot.build_stubbed(:infomation, title:) }

    context 'ない' do
      let(:title) { nil }
      let(:messages) { { title: [get_locale('activerecord.errors.models.infomation.attributes.title.blank')] } }

      it_behaves_like 'InValid'
    end
    context 'ある' do
      let(:title) { 'a' }

      it_behaves_like 'Valid'
    end
  end

  # 開始日時
  # テストパターン
  #   ない, 正常値
  describe 'validates :started_at' do
    subject(:model) { FactoryBot.build_stubbed(:infomation, started_at:) }

    context 'ない' do
      let(:started_at) { nil }
      let(:messages) { { started_at: [get_locale('activerecord.errors.models.infomation.attributes.started_at.blank')] } }

      it_behaves_like 'InValid'
    end
    context '正常値' do
      let(:started_at) { Time.current }

      it_behaves_like 'Valid'
    end
  end

  # 対象
  # テストパターン
  #   ない, 正常値
  describe 'validates :target' do
    subject(:model) { FactoryBot.build_stubbed(:infomation, target:) }

    context 'ない' do
      let(:target) { nil }
      let(:messages) { { target: [get_locale('activerecord.errors.models.infomation.attributes.target.blank')] } }

      it_behaves_like 'InValid'
    end
    context '正常値' do
      let(:target) { :all }

      it_behaves_like 'Valid'
    end
  end

  # ユーザー
  # テストパターン
  #   対象: 全員, 対象ユーザーのみ
  #   ユーザー: いない, いる
  describe 'validates :user' do
    subject(:model) { FactoryBot.build_stubbed(:infomation, target:, user:) }
    let_it_be(:valid_user) { FactoryBot.create(:user) }

    context '対象が全員' do
      let(:target) { :all }

      context 'ユーザーがいない' do
        let(:user) { nil }

        it_behaves_like 'Valid'
      end
      context 'ユーザーがいる' do
        let(:user) { valid_user }

        it_behaves_like 'Valid'
      end
    end
    context '対象が対象ユーザーのみ' do
      let(:target) { :user }

      context 'ユーザーがいない' do
        let(:user) { nil }
        let(:messages) { { user: [get_locale('activerecord.errors.models.infomation.attributes.user.blank')] } }

        it_behaves_like 'InValid'
      end
      context 'ユーザーがいる' do
        let(:user) { valid_user }

        it_behaves_like 'Valid'
      end
    end
  end

  # ロケールでフィルタ
  # テストパターン
  #   locale: ない, ja, en
  describe '.by_locale' do
    subject { described_class.by_locale(locale) }

    let_it_be(:infomation_nil) { FactoryBot.create(:infomation, locale: nil) }
    let_it_be(:infomation_ja)  { FactoryBot.create(:infomation, locale: 'ja') }
    let_it_be(:infomation_en)  { FactoryBot.create(:infomation, locale: 'en') }

    context 'localeがない' do
      let(:locale) { nil }
      let(:included_values) { [infomation_nil] }

      it_behaves_like 'Array', 'localeなしのお知らせ'
    end
    context 'localeがja' do
      let(:locale) { 'ja' }
      let(:included_values) { [infomation_nil, infomation_ja] }

      it_behaves_like 'Array', 'localeなしとjaのお知らせ'
    end
    context 'localeがen' do
      let(:locale) { 'en' }
      let(:included_values) { [infomation_nil, infomation_en] }

      it_behaves_like 'Array', 'localeなしとenのお知らせ'
    end
  end

  # 対象と期間でフィルタ
  # テストパターン
  #   対象: 全員, 対象ユーザーのみ（自分, 他人）
  #   開始日時: ない, 過去, 現在, 未来
  #   終了日時: ない, 過去, 現在, 未来
  #   current_user: ない, 存在する, 存在しない
  describe '.by_target' do
    subject { described_class.by_target(current_user) }

    let_it_be(:start_time) { Time.current.floor }
    before { allow(Time).to receive(:current).and_return(start_time) }

    let_it_be(:user)       { FactoryBot.create(:user) }
    let_it_be(:other_user) { FactoryBot.create(:user) }

    let_it_be(:inside_user_infomations) { [FactoryBot.create(:infomation, :user, user:, title: '自分')] }
    before_all do
      FactoryBot.create(:infomation, :user, user: other_user, title: '他人')
      FactoryBot.create(:infomation, :all, title: '過去 → 過去', started_at: start_time - 1.second, ended_at: start_time - 1.second)
    end
    let_it_be(:inside_all_infomations) do
      [
        FactoryBot.create(:infomation, :all, title: '過去 → なし', started_at: start_time - 1.second, ended_at: nil),
        FactoryBot.create(:infomation, :all, title: '過去 → 現在', started_at: start_time - 1.second, ended_at: start_time),
        FactoryBot.create(:infomation, :all, title: '過去 → 未来', started_at: start_time - 1.second, ended_at: start_time + 1.second),
        FactoryBot.create(:infomation, :all, title: '現在 → なし', started_at: start_time, ended_at: nil),
        FactoryBot.create(:infomation, :all, title: '現在 → 現在', started_at: start_time, ended_at: start_time),
        FactoryBot.create(:infomation, :all, title: '現在 → 未来', started_at: start_time, ended_at: start_time + 1.second)
      ]
    end
    before_all do
      FactoryBot.create(:infomation, :all, title: '現在 → 過去', started_at: start_time, ended_at: start_time - 1.second)
      FactoryBot.create(:infomation, :all, title: '未来 → なし', started_at: start_time + 1.second, ended_at: nil)
      FactoryBot.create(:infomation, :all, title: '未来 → 過去', started_at: start_time + 1.second, ended_at: start_time - 1.second)
      FactoryBot.create(:infomation, :all, title: '未来 → 現在', started_at: start_time + 1.second, ended_at: start_time)
      FactoryBot.create(:infomation, :all, title: '未来 → 未来', started_at: start_time + 1.second, ended_at: start_time + 1.second)
    end

    context 'current_userがない' do
      let(:current_user) { nil }
      let(:included_values) { inside_all_infomations }

      it_behaves_like 'Array', '対象のお知らせ'
    end
    context 'current_userが存在する' do
      let(:current_user) { user }
      let(:included_values) { inside_user_infomations + inside_all_infomations }

      it_behaves_like 'Array', '対象のお知らせ'
    end
    context 'current_userが存在しない' do
      let(:current_user) { FactoryBot.build_stubbed(:user) }

      let(:included_values) { inside_all_infomations }

      it_behaves_like 'Array', '対象のお知らせ'
    end
  end

  # 強制表示期間でフィルタ
  # テストパターン
  #   強制表示開始日時: ない, 過去, 現在, 未来
  #   強制表示終了日時: ない, 過去, 現在, 未来
  describe '.by_force' do
    subject { described_class.by_force }

    let_it_be(:start_time) { Time.current.floor }
    before { allow(Time).to receive(:current).and_return(start_time) }

    before_all do
      FactoryBot.create(:infomation, title: 'なし → なし', force_started_at: nil, force_ended_at: nil)
      FactoryBot.create(:infomation, title: 'なし → 過去', force_started_at: nil, force_ended_at: start_time - 1.second)
      FactoryBot.create(:infomation, title: 'なし → 現在', force_started_at: nil, force_ended_at: start_time)
      FactoryBot.create(:infomation, title: 'なし → 未来', force_started_at: nil, force_ended_at: start_time + 1.second)
      FactoryBot.create(:infomation, title: '過去 → 過去', force_started_at: start_time - 1.second, force_ended_at: start_time - 1.second)
    end
    let_it_be(:included_values) do
      [
        FactoryBot.create(:infomation, title: '過去 → なし', force_started_at: start_time - 1.second, force_ended_at: nil),
        FactoryBot.create(:infomation, title: '過去 → 現在', force_started_at: start_time - 1.second, force_ended_at: start_time),
        FactoryBot.create(:infomation, title: '過去 → 未来', force_started_at: start_time - 1.second, force_ended_at: start_time + 1.second),
        FactoryBot.create(:infomation, title: '現在 → なし', force_started_at: start_time, force_ended_at: nil),
        FactoryBot.create(:infomation, title: '現在 → 現在', force_started_at: start_time, force_ended_at: start_time),
        FactoryBot.create(:infomation, title: '現在 → 未来', force_started_at: start_time, force_ended_at: start_time + 1.second)
      ]
    end
    before_all do
      FactoryBot.create(:infomation, title: '現在 → 過去', force_started_at: start_time, force_ended_at: start_time - 1.second)
      FactoryBot.create(:infomation, title: '未来 → なし', force_started_at: start_time + 1.second, force_ended_at: nil)
      FactoryBot.create(:infomation, title: '未来 → 過去', force_started_at: start_time + 1.second, force_ended_at: start_time - 1.second)
      FactoryBot.create(:infomation, title: '未来 → 現在', force_started_at: start_time + 1.second, force_ended_at: start_time)
      FactoryBot.create(:infomation, title: '未来 → 未来', force_started_at: start_time + 1.second, force_ended_at: start_time + 1.second)
    end

    it_behaves_like 'Array', '対象のお知らせ'
  end

  # 未読でフィルタ
  # テストパターン
  #   開始日時: 過去, 現在, 未来
  #   check_last_started_at: ない, ある
  describe '.by_unread' do
    subject { described_class.by_unread(check_last_started_at) }

    let_it_be(:start_time) { Time.current }
    let_it_be(:outside_infomations) do
      [
        FactoryBot.create(:infomation, title: '過去', started_at: start_time - 1.second),
        FactoryBot.create(:infomation, title: '現在', started_at: start_time)
      ]
    end
    let_it_be(:inside_infomations) do
      [
        FactoryBot.create(:infomation, title: '未来', started_at: start_time + 1.second)
      ]
    end

    context 'check_last_started_atがない' do
      let(:check_last_started_at) { nil }
      let(:included_values) { outside_infomations + inside_infomations }

      it_behaves_like 'Array', '対象のお知らせ'
    end
    context 'check_last_started_atがある' do
      let(:check_last_started_at) { start_time }
      let(:included_values) { inside_infomations }

      it_behaves_like 'Array', '対象のお知らせ'
    end
  end

  # 表示対象かを返却
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）
  #   対象: 全員, 自分, 他人
  describe '#display_target?' do
    subject { infomation.display_target?(user) }
    let_it_be(:other_user) { FactoryBot.create(:user) }

    shared_examples '対象が全員' do
      let_it_be(:infomation) { FactoryBot.create(:infomation, :all) }

      it_behaves_like 'Value', true
    end
    shared_examples '対象が自分' do
      let_it_be(:infomation) { FactoryBot.create(:infomation, :user, user:) }

      it_behaves_like 'Value', true
    end
    shared_examples '対象が他人' do
      let_it_be(:infomation) { FactoryBot.create(:infomation, :user, user: other_user) }

      it_behaves_like 'Value', false
    end

    context '未ログイン' do
      let(:user) { nil }

      it_behaves_like '対象が全員'
      # it_behaves_like '対象が自分' # NOTE: 未ログインの為、他人
      it_behaves_like '対象が他人'
    end
    context 'ログイン中' do
      include_context 'ユーザー作成'

      it_behaves_like '対象が全員'
      it_behaves_like '対象が自分'
      it_behaves_like '対象が他人'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ユーザー作成', :destroy_reserved

      it_behaves_like '対象が全員'
      it_behaves_like '対象が自分'
      it_behaves_like '対象が他人'
    end
  end
end
