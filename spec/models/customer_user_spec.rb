require 'rails_helper'

RSpec.describe CustomerUser, type: :model do
  let!(:customers) { FactoryBot.create_list(:customer, 2) }
  shared_context 'データ作成' do |invitationed_flag, customer_flag, requested_flag, completed_flag|
    let!(:invitationed_at) { invitationed_flag.nil? ? nil : Time.current - 3.days }
    let!(:customer_no) { customer_flag ? 0 : 1 }
    let!(:customer_id) { customer_flag.nil? ? nil : customers[customer_no].id }
    let!(:requested_at) { requested_flag.nil? ? nil : Time.current - 2.days }
    let!(:completed_at) { completed_flag.nil? ? nil : Time.current - 1.day }
    let!(:user) { FactoryBot.create(:user, invitation_customer_id: customer_id, invitation_requested_at: requested_at, invitation_completed_at: completed_at) }
    let!(:customer_user) { FactoryBot.create(:customer_user, customer_id: customers[0].id, user_id: user.id, invitationed_at: invitationed_at, power: :Member) }
  end

  describe 'registrationed_at' do
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
end
