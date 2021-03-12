require 'rake_helper'

RSpec.describe User do
  # 削除予定日時を過ぎたユーザーのアカウントを削除
  # 前提条件
  #   なし
  # テストパターン
  #   2件（削除予約1件、削除対象0件）, 3件（削除予約1件、削除対象1件）, 4件（削除予約1件、削除対象2件） → データ作成
  describe 'user:destroy' do
    let!(:task) { Rake.application['user:destroy'] }
    let!(:dry_run) { 'false' }
    let!(:customers) { FactoryBot.create_list(:customer, 3) }
    let!(:user1) { FactoryBot.create(:user) }
    let!(:user2) { FactoryBot.create(:user, destroy_schedule_at: Time.current + Settings['destroy_schedule_days'].days - 1.hour) }
    before do
      FactoryBot.create(:infomation)
      FactoryBot.create(:infomation, target: :User, user_id: user1.id)
      FactoryBot.create_list(:infomation, 2, target: :User, user_id: user2.id)
      FactoryBot.create(:member, customer_id: customers[0].id, user_id: user2.id, power: :Owner)
    end

    shared_context 'ユーザー作成3' do
      let!(:user3) { FactoryBot.create(:user, destroy_schedule_at: Time.current - Settings['destroy_schedule_days'].days - 1.second) }
      before do
        FactoryBot.create_list(:infomation, 3, target: :User, user_id: user3.id)
        FactoryBot.create(:member, customer_id: customers[0].id, user_id: user3.id, power: :Owner)
        FactoryBot.create(:member, customer_id: customers[1].id, user_id: user3.id, power: :Member)
      end
    end
    shared_context 'ユーザー作成4' do
      let!(:user4) { FactoryBot.create(:user, destroy_schedule_at: Time.current - Settings['destroy_schedule_days'].days - 1.hour) }
      before do
        FactoryBot.create_list(:infomation, 4, target: :User, user_id: user4.id)
        FactoryBot.create(:member, customer_id: customers[0].id, user_id: user4.id, power: :Owner)
        FactoryBot.create(:member, customer_id: customers[1].id, user_id: user4.id, power: :Admin)
        FactoryBot.create(:member, customer_id: customers[2].id, user_id: user4.id, power: :Member)
      end
    end

    # テスト内容
    shared_examples_for '削除件数' do |user_count, infomation_count, member_count|
      it "ユーザーが#{user_count}件・お知らせが#{infomation_count}件・メンバーが#{member_count}件削除される" do
        expect do
          expect(task.invoke(dry_run)).to be_truthy
        end.to change(User, :count).by(user_count * -1) && change(Infomation, :count).by(infomation_count * -1) && change(Member, :count).by(member_count * -1)
      end
    end

    shared_examples_for 'ユーザー1・2未削除' do
      it 'ユーザー1・2が削除されない' do
        expect(task.invoke(dry_run)).to be_truthy
        expect(User.find_by(id: user1.id)).not_to eq(nil)
        expect(User.find_by(id: user2.id)).not_to eq(nil)
      end
      it 'ユーザー1・2向けのお知らせが削除されない' do
        expect(task.invoke(dry_run)).to be_truthy
        expect(Infomation.find_by(user_id: user1.id)).not_to eq(nil)
        expect(Infomation.find_by(user_id: user2.id)).not_to eq(nil)
      end
      it 'ユーザー1・2のメンバーが削除されない' do
        expect(task.invoke(dry_run)).to be_truthy
        # expect(Member.find_by(user_id: user1.id)).not_to eq(nil) # Tips: 未所属の為
        expect(Member.find_by(user_id: user2.id)).not_to eq(nil)
      end
    end
    shared_examples_for 'ユーザー3削除' do
      it 'ユーザー3が削除される' do
        expect(task.invoke(dry_run)).to be_truthy
        expect(User.find_by(id: user3.id)).to eq(nil)
      end
      it 'ユーザー3向けのお知らせが削除される' do
        expect(task.invoke(dry_run)).to be_truthy
        expect(Infomation.find_by(user_id: user3.id)).to eq(nil)
      end
      it 'ユーザー3のメンバーが削除される' do
        expect(task.invoke(dry_run)).to be_truthy
        expect(Member.find_by(user_id: user3.id)).to eq(nil)
      end
    end
    shared_examples_for 'ユーザー3・4削除' do
      it 'ユーザー3・4が削除される' do
        expect(task.invoke(dry_run)).to be_truthy
        expect(User.find_by(id: user3.id)).to eq(nil)
        expect(User.find_by(id: user4.id)).to eq(nil)
      end
      it 'ユーザー3・4向けのお知らせが削除される' do
        expect(task.invoke(dry_run)).to be_truthy
        expect(Infomation.find_by(user_id: user3.id)).to eq(nil)
        expect(Infomation.find_by(user_id: user4.id)).to eq(nil)
      end
      it 'ユーザー3・4のメンバーが削除される' do
        expect(task.invoke(dry_run)).to be_truthy
        expect(Member.find_by(user_id: user3.id)).to eq(nil)
        expect(Member.find_by(user_id: user4.id)).to eq(nil)
      end
    end

    # テストケース
    context '2件（削除予約1件、削除対象0件）' do
      it_behaves_like '削除件数', 0, 0, 0
      it_behaves_like 'ユーザー1・2未削除'
    end

    context '3件（削除予約1件、削除対象1件）' do
      include_context 'ユーザー作成3'
      it_behaves_like '削除件数', 1, 3, 2
      it_behaves_like 'ユーザー1・2未削除'
      it_behaves_like 'ユーザー3削除'
    end

    context '4件（削除予約1件、削除対象2件）' do
      include_context 'ユーザー作成3'
      include_context 'ユーザー作成4'
      it_behaves_like '削除件数', 2, 3 + 4, 2 + 3
      it_behaves_like 'ユーザー1・2未削除'
      it_behaves_like 'ユーザー3・4削除'
    end
  end
end
