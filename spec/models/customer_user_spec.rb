require 'rails_helper'

RSpec.describe CustomerUser, type: :model do
  # 登録日時を返却
  # 前提条件
  #   なし
  # テストパターン
  #   招待日時：なし, あり → データ作成
  #   招待顧客ID・依頼日時・完了日時：なし・なし・なし, 一致・あり・なし, 不一致・あり・なし, 一致・あり・あり, 不一致・あり・あり → データ作成
  describe 'registrationed_at' do
    let!(:customers) { FactoryBot.create_list(:customer, 2) }
    shared_context 'データ作成' do |invitationed_flag, customer_flag, requested_flag, completed_flag|
      let!(:invitationed_at) { invitationed_flag.nil? ? nil : Time.current - 3.days }
      let!(:customer_no) { customer_flag ? 0 : 1 }
      let!(:customer_id) { customer_flag.nil? ? nil : customers[customer_no].id }
      let!(:requested_at) { requested_flag.nil? ? nil : Time.current - 2.days }
      let!(:completed_at) { completed_flag.nil? ? nil : Time.current - 1.day }
      let!(:user) do
        FactoryBot.create(:user, invitation_customer_id: customer_id, invitation_requested_at: requested_at, invitation_completed_at: completed_at)
      end
      let!(:customer_user) do
        FactoryBot.create(:customer_user, customer_id: customers[0].id, user_id: user.id, invitationed_at: invitationed_at, power: :Member)
      end
    end

    # テスト内容
    shared_examples_for '自分で顧客作成' do
      it '登録日時' do
        expect(customer_user.registrationed_at).to eq(customer_user.created_at)
      end
    end
    shared_examples_for '招待前にアカウント作成' do
      it '登録日時' do
        expect(customer_user.registrationed_at).to eq(customer_user.created_at)
      end
    end
    shared_examples_for 'この顧客で招待・登録未完了' do
      it 'なし' do
        expect(customer_user.registrationed_at).to be_nil
      end
    end
    shared_examples_for '他の顧客で招待・登録未完了' do
      it 'なし' do
        expect(customer_user.registrationed_at).to be_nil
      end
    end
    shared_examples_for 'この顧客で招待・登録完了' do
      it '招待完了日時' do
        expect(customer_user.registrationed_at).to eq(user.invitation_completed_at)
      end
    end
    shared_examples_for '他の顧客で招待・登録完了' do
      it '登録日時' do
        expect(customer_user.registrationed_at).to eq(customer_user.created_at)
      end
    end

    # テストケース
    context '招待日時：なし、招待顧客ID・依頼日時・完了日時：なし・なし・なし' do
      include_context 'データ作成', nil, nil, nil, nil
      it_behaves_like '自分で顧客作成'
    end
    context '招待日時：なし、招待顧客ID・依頼日時・完了日時：一致・あり・なし' do # Tips: 不整合（招待したのに招待日時がない）
      include_context 'データ作成', nil, true, true, nil
      it_behaves_like 'この顧客で招待・登録未完了'
    end
    context '招待日時：なし、招待顧客ID・依頼日時・完了日時：不一致・あり・なし' do # Tips: 不整合（未登録で顧客作成できない）
      include_context 'データ作成', nil, false, true, nil
      it_behaves_like '他の顧客で招待・登録未完了'
    end
    context '招待日時：なし、招待顧客ID・依頼日時・完了日時：一致・あり・あり' do # Tips: 不整合（招待したのに招待日時がない）
      include_context 'データ作成', nil, true, true, true
      it_behaves_like 'この顧客で招待・登録完了'
    end
    context '招待日時：なし、招待顧客ID・依頼日時・完了日時：不一致・あり・あり' do # Tips: 他で招待された後に自分で顧客作成
      include_context 'データ作成', nil, false, true, true
      it_behaves_like '他の顧客で招待・登録完了'
    end

    context '招待日時：あり、招待顧客ID・依頼日時・完了日時：なし・なし・なし' do
      include_context 'データ作成', true, nil, nil, nil
      it_behaves_like '招待前にアカウント作成'
    end
    context '招待日時：あり、招待顧客ID・依頼日時・完了日時：一致・あり・なし' do
      include_context 'データ作成', true, true, true, nil
      it_behaves_like 'この顧客で招待・登録未完了'
    end
    context '招待日時：あり、招待顧客ID・依頼日時・完了日時：不一致・あり・なし' do
      include_context 'データ作成', true, false, true, nil
      it_behaves_like '他の顧客で招待・登録未完了'
    end
    context '招待日時：あり、招待顧客ID・依頼日時・完了日時：一致・あり・あり' do
      include_context 'データ作成', true, true, true, true
      it_behaves_like 'この顧客で招待・登録完了'
    end
    context '招待日時：あり、招待顧客ID・依頼日時・完了日時：不一致・あり・あり' do
      include_context 'データ作成', true, false, true, true
      it_behaves_like '他の顧客で招待・登録完了'
    end
  end

  # 変更権限があるかを返却
  # 前提条件
  #   引数なし
  # テストパターン
  #   Owner権限, Admin権限, Member権限 → データ作成
  describe 'update_power?' do
    let!(:customer) { FactoryBot.create(:customer) }
    shared_context 'データ作成' do |power|
      let!(:user) { FactoryBot.create(:user) }
      let!(:customer_user) { FactoryBot.create(:customer_user, customer_id: customer.id, user_id: user.id, power: power) }
    end

    # テスト内容
    shared_examples_for 'ToOK' do
      it 'OK' do
        expect(customer_user.update_power?).to eq(true)
      end
    end
    shared_examples_for 'ToNG' do
      it 'NG' do
        expect(customer_user.update_power?).to eq(false)
      end
    end

    # テストケース
    context 'Owner権限' do
      include_context 'データ作成', :Owner
      it_behaves_like 'ToOK'
    end
    context 'Admin権限' do
      include_context 'データ作成', :Admin
      it_behaves_like 'ToOK'
    end
    context 'Member権限' do
      include_context 'データ作成', :Member
      it_behaves_like 'ToNG'
    end
  end

  # 変更権限があるかを返却
  # 前提条件
  #   引数あり
  # テストパターン
  #   Owner権限, Admin権限, Member権限 → データ作成
  #   対象Owner, 対象Admin, 対象Member
  describe 'update_power?(taget_user_power)' do
    let!(:customer) { FactoryBot.create(:customer) }
    shared_context 'データ作成' do |power|
      let!(:user) { FactoryBot.create(:user) }
      let!(:customer_user) { FactoryBot.create(:customer_user, customer_id: customer.id, user_id: user.id, power: power) }
    end

    # テスト内容
    shared_examples_for 'ToOK' do
      it 'OK' do
        expect(customer_user.update_power?(taget_user_power)).to eq(true)
      end
    end
    shared_examples_for 'ToNG' do
      it 'NG' do
        expect(customer_user.update_power?(taget_user_power)).to eq(false)
      end
    end

    # テストケース
    shared_examples_for '[Owner権限]対象Owner' do
      let!(:taget_user_power) { 'Owner' }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[Admin/Member権限]対象Owner' do
      let!(:taget_user_power) { 'Owner' }
      it_behaves_like 'ToNG'
    end
    shared_examples_for '[Owner/Admin権限]対象Admin' do
      let!(:taget_user_power) { 'Admin' }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[Member権限]対象Admin' do
      let!(:taget_user_power) { 'Admin' }
      it_behaves_like 'ToNG'
    end
    shared_examples_for '[Owner/Admin権限]対象Member' do
      let!(:taget_user_power) { 'Member' }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[Member権限]対象Member' do
      let!(:taget_user_power) { 'Member' }
      it_behaves_like 'ToNG'
    end

    context 'Owner権限' do
      include_context 'データ作成', :Owner
      it_behaves_like '[Owner権限]対象Owner'
      it_behaves_like '[Owner/Admin権限]対象Admin'
      it_behaves_like '[Owner/Admin権限]対象Member'
    end
    context 'Admin権限' do
      include_context 'データ作成', :Admin
      it_behaves_like '[Admin/Member権限]対象Owner'
      it_behaves_like '[Owner/Admin権限]対象Admin'
      it_behaves_like '[Owner/Admin権限]対象Member'
    end
    context 'Member権限' do
      include_context 'データ作成', :Member
      it_behaves_like '[Admin/Member権限]対象Owner'
      it_behaves_like '[Member権限]対象Admin'
      it_behaves_like '[Member権限]対象Member'
    end
  end
end
