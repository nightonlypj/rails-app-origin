require 'rails_helper'

RSpec.describe Member, type: :model do
  # 登録日時を返却
  # 前提条件
  #   なし
  # テストパターン
  #   招待日時: ない, ある → データ作成
  #   招待顧客ID・依頼日時・完了日時: ない・ない・ない, 一致・ある・ない, 不一致・ある・ない, 一致・ある・ある, 不一致・ある・ある → データ作成
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
      let!(:member) do
        FactoryBot.create(:member, customer_id: customers[0].id, user_id: user.id, invitationed_at: invitationed_at, power: :Member)
      end
    end

    # テスト内容
    shared_examples_for '自分で顧客作成' do
      it '登録日時が返却される' do
        expect(member.registrationed_at).to eq(member.created_at)
      end
    end
    shared_examples_for '招待前にアカウント作成' do
      it '登録日時が返却される' do
        expect(member.registrationed_at).to eq(member.created_at)
      end
    end
    shared_examples_for 'この顧客で招待・登録未完了' do
      it 'なしが返却される' do
        expect(member.registrationed_at).to be_nil
      end
    end
    shared_examples_for '他の顧客で招待・登録未完了' do
      it 'なしが返却される' do
        expect(member.registrationed_at).to be_nil
      end
    end
    shared_examples_for 'この顧客で招待・登録完了' do
      it '招待完了日時が返却される' do
        expect(member.registrationed_at).to eq(user.invitation_completed_at)
      end
    end
    shared_examples_for '他の顧客で招待・登録完了' do
      it '登録日時が返却される' do
        expect(member.registrationed_at).to eq(member.created_at)
      end
    end

    # テストケース
    context '招待日時：ない、招待顧客ID・依頼日時・完了日時：ない・ない・ない' do
      include_context 'データ作成', nil, nil, nil, nil
      it_behaves_like '自分で顧客作成'
    end
    context '招待日時：ない、招待顧客ID・依頼日時・完了日時：一致・ある・ない' do # Tips: 不整合（招待したのに招待日時がない）
      include_context 'データ作成', nil, true, true, nil
      it_behaves_like 'この顧客で招待・登録未完了'
    end
    context '招待日時：ない、招待顧客ID・依頼日時・完了日時：不一致・ある・ない' do # Tips: 不整合（未登録で顧客作成できない）
      include_context 'データ作成', nil, false, true, nil
      it_behaves_like '他の顧客で招待・登録未完了'
    end
    context '招待日時：ない、招待顧客ID・依頼日時・完了日時：一致・ある・ある' do # Tips: 不整合（招待したのに招待日時がない）
      include_context 'データ作成', nil, true, true, true
      it_behaves_like 'この顧客で招待・登録完了'
    end
    context '招待日時：ない、招待顧客ID・依頼日時・完了日時：不一致・ある・ある' do # Tips: 他で招待された後に自分で顧客作成
      include_context 'データ作成', nil, false, true, true
      it_behaves_like '他の顧客で招待・登録完了'
    end

    context '招待日時：ある、招待顧客ID・依頼日時・完了日時：ない・ない・ない' do
      include_context 'データ作成', true, nil, nil, nil
      it_behaves_like '招待前にアカウント作成'
    end
    context '招待日時：ある、招待顧客ID・依頼日時・完了日時：一致・ある・ない' do
      include_context 'データ作成', true, true, true, nil
      it_behaves_like 'この顧客で招待・登録未完了'
    end
    context '招待日時：ある、招待顧客ID・依頼日時・完了日時：不一致・ある・ない' do
      include_context 'データ作成', true, false, true, nil
      it_behaves_like '他の顧客で招待・登録未完了'
    end
    context '招待日時：ある、招待顧客ID・依頼日時・完了日時：一致・ある・ある' do
      include_context 'データ作成', true, true, true, true
      it_behaves_like 'この顧客で招待・登録完了'
    end
    context '招待日時：ある、招待顧客ID・依頼日時・完了日時：不一致・ある・ある' do
      include_context 'データ作成', true, false, true, true
      it_behaves_like '他の顧客で招待・登録完了'
    end
  end

  # 変更権限があるかを返却
  # 前提条件
  #   引数なし
  # テストパターン
  #   権限: Owner, Admin, Member → データ作成
  describe 'update_power?' do
    let!(:customer) { FactoryBot.create(:customer) }
    shared_context 'データ作成' do |power|
      let!(:user) { FactoryBot.create(:user) }
      let!(:member) { FactoryBot.create(:member, customer_id: customer.id, user_id: user.id, power: power) }
    end

    # テスト内容
    shared_examples_for 'ToOK' do
      it 'trueが返却される' do
        expect(member.update_power?).to eq(true)
      end
    end
    shared_examples_for 'ToNG' do
      it 'falseが返却される' do
        expect(member.update_power?).to eq(false)
      end
    end

    # テストケース
    context '権限がOwner' do
      include_context 'データ作成', :Owner
      it_behaves_like 'ToOK'
    end
    context '権限がAdmin' do
      include_context 'データ作成', :Admin
      it_behaves_like 'ToOK'
    end
    context '権限がMember' do
      include_context 'データ作成', :Member
      it_behaves_like 'ToNG'
    end
  end

  # 変更権限があるかを返却
  # 前提条件
  #   引数あり
  # テストパターン
  #   権限: Owner, Admin, Member → データ作成
  #   対象: Owner, Admin, Member
  describe 'update_power?(taget_user_power)' do
    let!(:customer) { FactoryBot.create(:customer) }
    shared_context 'データ作成' do |power|
      let!(:user) { FactoryBot.create(:user) }
      let!(:member) { FactoryBot.create(:member, customer_id: customer.id, user_id: user.id, power: power) }
    end

    # テスト内容
    shared_examples_for 'ToOK' do
      it 'trueが返却される' do
        expect(member.update_power?(taget_user_power)).to eq(true)
      end
    end
    shared_examples_for 'ToNG' do
      it 'falseが返却される' do
        expect(member.update_power?(taget_user_power)).to eq(false)
      end
    end

    # テストケース
    shared_examples_for '[Owner]対象がOwner' do
      let!(:taget_user_power) { 'Owner' }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[Admin/Member]対象がOwner' do
      let!(:taget_user_power) { 'Owner' }
      it_behaves_like 'ToNG'
    end
    shared_examples_for '[Owner/Admin]対象がAdmin' do
      let!(:taget_user_power) { 'Admin' }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[Member]対象がAdmin' do
      let!(:taget_user_power) { 'Admin' }
      it_behaves_like 'ToNG'
    end
    shared_examples_for '[Owner/Admin]対象がMember' do
      let!(:taget_user_power) { 'Member' }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[Member]対象がMember' do
      let!(:taget_user_power) { 'Member' }
      it_behaves_like 'ToNG'
    end

    context '権限がOwner' do
      include_context 'データ作成', :Owner
      it_behaves_like '[Owner]対象がOwner'
      it_behaves_like '[Owner/Admin]対象がAdmin'
      it_behaves_like '[Owner/Admin]対象がMember'
    end
    context '権限がAdmin' do
      include_context 'データ作成', :Admin
      it_behaves_like '[Admin/Member]対象がOwner'
      it_behaves_like '[Owner/Admin]対象がAdmin'
      it_behaves_like '[Owner/Admin]対象がMember'
    end
    context '権限がMember' do
      include_context 'データ作成', :Member
      it_behaves_like '[Admin/Member]対象がOwner'
      it_behaves_like '[Member]対象がAdmin'
      it_behaves_like '[Member]対象がMember'
    end
  end

  # 解除権限があるかを返却
  # 前提条件
  #   引数なし
  # テストパターン
  #   権限: Owner, Admin, Member → データ作成
  describe 'destroy_power?' do
    let!(:customer) { FactoryBot.create(:customer) }
    shared_context 'データ作成' do |power|
      let!(:user) { FactoryBot.create(:user) }
      let!(:member) { FactoryBot.create(:member, customer_id: customer.id, user_id: user.id, power: power) }
    end

    # テスト内容
    shared_examples_for 'ToOK' do
      it 'trueが返却される' do
        expect(member.destroy_power?).to eq(true)
      end
    end
    shared_examples_for 'ToNG' do
      it 'falseが返却される' do
        expect(member.destroy_power?).to eq(false)
      end
    end

    # テストケース
    context '権限がOwner' do
      include_context 'データ作成', :Owner
      it_behaves_like 'ToOK'
    end
    context '権限がAdmin' do
      include_context 'データ作成', :Admin
      it_behaves_like 'ToOK'
    end
    context '権限がMember' do
      include_context 'データ作成', :Member
      it_behaves_like 'ToNG'
    end
  end

  # 解除権限があるかを返却
  # 前提条件
  #   引数あり
  # テストパターン
  #   権限: Owner, Admin, Member → データ作成
  #   対象: Owner, Admin, Member
  describe 'destroy_power?(taget_user_power)' do
    let!(:customer) { FactoryBot.create(:customer) }
    shared_context 'データ作成' do |power|
      let!(:user) { FactoryBot.create(:user) }
      let!(:member) { FactoryBot.create(:member, customer_id: customer.id, user_id: user.id, power: power) }
    end

    # テスト内容
    shared_examples_for 'ToOK' do
      it 'trueが返却される' do
        expect(member.destroy_power?(taget_user_power)).to eq(true)
      end
    end
    shared_examples_for 'ToNG' do
      it 'falseが返却される' do
        expect(member.destroy_power?(taget_user_power)).to eq(false)
      end
    end

    # テストケース
    shared_examples_for '[Owner]対象がOwner' do
      let!(:taget_user_power) { 'Owner' }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[Admin/Member]対象がOwner' do
      let!(:taget_user_power) { 'Owner' }
      it_behaves_like 'ToNG'
    end
    shared_examples_for '[Owner/Admin]対象がAdmin' do
      let!(:taget_user_power) { 'Admin' }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[Member]対象がAdmin' do
      let!(:taget_user_power) { 'Admin' }
      it_behaves_like 'ToNG'
    end
    shared_examples_for '[Owner/Admin]対象がMember' do
      let!(:taget_user_power) { 'Member' }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[Member]対象がMember' do
      let!(:taget_user_power) { 'Member' }
      it_behaves_like 'ToNG'
    end

    context '権限がOwner' do
      include_context 'データ作成', :Owner
      it_behaves_like '[Owner]対象がOwner'
      it_behaves_like '[Owner/Admin]対象がAdmin'
      it_behaves_like '[Owner/Admin]対象がMember'
    end
    context '権限がAdmin' do
      include_context 'データ作成', :Admin
      it_behaves_like '[Admin/Member]対象がOwner'
      it_behaves_like '[Owner/Admin]対象がAdmin'
      it_behaves_like '[Owner/Admin]対象がMember'
    end
    context '権限がMember' do
      include_context 'データ作成', :Member
      it_behaves_like '[Admin/Member]対象がOwner'
      it_behaves_like '[Member]対象がAdmin'
      it_behaves_like '[Member]対象がMember'
    end
  end
end
