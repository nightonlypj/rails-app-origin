require 'rails_helper'

RSpec.describe Infomation, type: :model do
  # ラベル
  # テストパターン
  #   ない, 正常値
  describe 'validates :label' do
    let(:model) { FactoryBot.build_stubbed(:infomation, label: label) }

    # テストケース
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
    let(:model) { FactoryBot.build_stubbed(:infomation, title: title) }

    # テストケース
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
  #   ない, 正常値,
  describe 'validates :started_at' do
    let(:model) { FactoryBot.build_stubbed(:infomation, started_at: started_at) }

    # テストケース
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
    let(:model) { FactoryBot.build_stubbed(:infomation, target: target) }

    # テストケース
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
    let(:model) { FactoryBot.build_stubbed(:infomation, target: target, user: user) }
    let_it_be(:valid_user) { FactoryBot.create(:user) }

    # テストケース
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

  # 表示対象かを返却
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）
  #   対象: 全員, 自分, 他人
  describe '#display_target?' do
    subject { infomation.display_target?(user) }
    let_it_be(:other_user) { FactoryBot.create(:user) }

    # テストケース
    shared_examples_for '[*]対象が全員' do
      let_it_be(:infomation) { FactoryBot.create(:infomation, :all) }
      it_behaves_like 'Value', true
    end
    shared_examples_for '[ログイン中/削除予約済み]対象が自分' do
      let_it_be(:infomation) { FactoryBot.create(:infomation, :user, user: user) }
      it_behaves_like 'Value', true
    end
    shared_examples_for '[*]対象が他人' do
      let_it_be(:infomation) { FactoryBot.create(:infomation, :user, user: other_user) }
      it_behaves_like 'Value', false
    end

    shared_examples_for '[ログイン中/削除予約済み]' do
      it_behaves_like '[*]対象が全員'
      it_behaves_like '[ログイン中/削除予約済み]対象が自分'
      it_behaves_like '[*]対象が他人'
    end

    context '未ログイン' do
      let(:user) { nil }
      it_behaves_like '[*]対象が全員'
      # it_behaves_like '[未ログイン]対象が自分' # NOTE: 未ログインの為、他人
      it_behaves_like '[*]対象が他人'
    end
    context 'ログイン中' do
      include_context 'ユーザー作成'
      it_behaves_like '[ログイン中/削除予約済み]'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ユーザー作成', :destroy_reserved
      it_behaves_like '[ログイン中/削除予約済み]'
    end
  end
end
