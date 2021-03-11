require 'rails_helper'

RSpec.describe Infomation, type: :model do
  # 対象かを返却
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ作成
  #   対象: 全員, 自分, 他人 → データ作成
  describe 'target_user?' do
    let!(:outside_user) { FactoryBot.create(:user) }
    shared_context 'データ作成' do |target|
      let!(:infomation) { FactoryBot.create(:infomation, target: target, user_id: user_id) }
    end

    # テスト内容
    shared_examples_for 'ToOK' do
      it 'trueが返却される' do
        expect(infomation.target_user?(user)).to eq(true)
      end
    end
    shared_examples_for 'ToNG' do
      it 'falseが返却される' do
        expect(infomation.target_user?(user)).to eq(false)
      end
    end

    # テストケース
    shared_examples_for '[*]対象が全員' do
      let!(:user_id) { nil }
      include_context 'データ作成', :All
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[ログイン中/削除予約済み]対象が自分' do
      let!(:user_id) { user.id }
      include_context 'データ作成', :User
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[*]対象が他人' do
      let!(:user_id) { outside_user.id }
      include_context 'データ作成', :User
      it_behaves_like 'ToNG'
    end

    context '未ログイン' do
      let!(:user) { nil }
      it_behaves_like '[*]対象が全員'
      # it_behaves_like '[未ログイン]対象が自分' # Tips: 未ログインの為、他人
      it_behaves_like '[*]対象が他人' # Tips: NG
    end
    context 'ログイン中' do
      let!(:user) { FactoryBot.create(:user) }
      it_behaves_like '[*]対象が全員'
      it_behaves_like '[ログイン中/削除予約済み]対象が自分'
      it_behaves_like '[*]対象が他人' # Tips: NG
    end
    context 'ログイン中（削除予約済み）' do
      let!(:user) { FactoryBot.create(:user, destroy_requested_at: Time.current, destroy_schedule_at: Time.current + Settings['destroy_schedule_days'].days) }
      it_behaves_like '[*]対象が全員'
      it_behaves_like '[ログイン中/削除予約済み]対象が自分'
      it_behaves_like '[*]対象が他人' # Tips: NG
    end
  end

  # アクションに応じたタイトルを返却
  # 前提条件
  #   対象: 自分, ログイン中/削除予約済み
  # テストパターン
  #   ログイン中, ログイン中（削除予約済み） → データ作成
  #   アクションユーザー: いる, いない（削除済み） → 事前にデータ作成
  #   アクション: ある(MemberCreate, MemberUpdate, MemberDestroy, RegistrationCreate), ない, 未定義 → データ作成
  describe 'action_title' do
    let!(:action_user) { FactoryBot.create(:user) }
    let!(:customer) { FactoryBot.create(:customer) }
    shared_context 'データ作成' do |action|
      let!(:infomation) do
        FactoryBot.create(:infomation, target: :User, user_id: user.id, action: action, action_user_id: action_user_id, customer_id: customer.id)
      end
    end

    # テスト内容
    shared_examples_for 'ToOK' do |key|
      it 'アクションのメッセージが返却される' do
        action_user_name = action_user_id.present? ? action_user.name : I18n.t('infomation.action_user.blank.name')
        action_user_email = action_user_id.present? ? action_user.email : I18n.t('infomation.action_user.blank.email')
        expect(infomation.action_title).to eq(I18n.t(key).gsub(/%{action_user_name}/, action_user_name)
                                                         .gsub(/%{action_user_email}/, action_user_email)
                                                         .gsub(/%{customer_name}/, customer.name)
                                                         .gsub(/%{customer_code}/, customer.code))
      end
    end
    shared_examples_for 'ToTitle' do
      it 'タイトルが返却される' do
        expect(infomation.action_title).to eq(infomation.title)
      end
    end
    shared_examples_for 'ToNG' do
      it 'ないが返却される' do
        expect(infomation.action_title).to eq(nil)
      end
    end

    # テストケース
    shared_examples_for '[*][*]アクションがある' do |action, key|
      include_context 'データ作成', action
      it_behaves_like 'ToOK', key
    end
    shared_examples_for '[*][*]アクションがない' do
      include_context 'データ作成', nil
      it_behaves_like 'ToTitle'
    end
    shared_examples_for '[*][*]アクションが未定義' do
      include_context 'データ作成', 'not'
      it_behaves_like 'ToNG'
    end

    shared_examples_for '[*]アクションユーザーがいる' do
      let!(:action_user_id) { action_user.id }
      it_behaves_like '[*][*]アクションがある', 'MemberCreate', 'infomation.action.member_create'
      it_behaves_like '[*][*]アクションがある', 'MemberUpdate', 'infomation.action.member_update'
      it_behaves_like '[*][*]アクションがある', 'MemberDestroy', 'infomation.action.member_destroy'
      it_behaves_like '[*][*]アクションがある', 'RegistrationCreate', 'infomation.action.registration_create'
      it_behaves_like '[*][*]アクションがない'
      it_behaves_like '[*][*]アクションが未定義'
    end
    shared_examples_for '[*]アクションユーザーがいない（削除済み）' do
      let!(:action_user_id) { nil }
      it_behaves_like '[*][*]アクションがある', 'MemberCreate', 'infomation.action.member_create'
      it_behaves_like '[*][*]アクションがある', 'MemberUpdate', 'infomation.action.member_update'
      it_behaves_like '[*][*]アクションがある', 'MemberDestroy', 'infomation.action.member_destroy'
      it_behaves_like '[*][*]アクションがある', 'RegistrationCreate', 'infomation.action.registration_create'
      it_behaves_like '[*][*]アクションがない'
      it_behaves_like '[*][*]アクションが未定義'
    end

    context 'ログイン中' do
      let!(:user) { FactoryBot.create(:user) }
      it_behaves_like '[*]アクションユーザーがいる'
      it_behaves_like '[*]アクションユーザーがいない（削除済み）'
    end
    context 'ログイン中（削除予約済み）' do
      let!(:user) { FactoryBot.create(:user, destroy_requested_at: Time.current, destroy_schedule_at: Time.current + Settings['destroy_schedule_days'].days) }
      it_behaves_like '[*]アクションユーザーがいる'
      it_behaves_like '[*]アクションユーザーがいない（削除済み）'
    end
  end
end
