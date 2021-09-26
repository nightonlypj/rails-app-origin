require 'rake_helper'

RSpec.describe :user, type: :task do
  # 削除予定日時を過ぎたユーザーのアカウントを削除
  # 前提条件
  #   なし
  # テストパターン
  #   2件（削除予約1件、削除対象0件）, 3件（削除予約1件、削除対象1件）, 4件（削除予約1件、削除対象2件）
  #   ドライラン: true, false
  describe 'user:destroy' do
    let(:task) { Rake.application['user:destroy'] }
    let!(:user1) { FactoryBot.create(:user) }
    let!(:user2) { FactoryBot.create(:user_destroy_reserved) }
    before do
      FactoryBot.create(:infomation) # :All
      FactoryBot.create(:infomation, target: :User, user_id: user1.id)
      FactoryBot.create(:infomation, target: :User, user_id: user2.id)
    end

    shared_context 'ユーザー作成3' do
      let!(:user3) { FactoryBot.create(:user_destroy_targeted) }
    end
    shared_context 'ユーザー作成4' do
      let!(:user4) { FactoryBot.create(:user_destroy_targeted) }
      before do
        FactoryBot.create(:infomation, target: :User, user_id: user4.id)
      end
    end

    # テスト内容
    shared_examples_for '削除件数' do |user_count, infomation_count|
      it "ユーザーが#{user_count}件・お知らせが#{infomation_count}件削除される" do
        expect do
          task.invoke(dry_run)
        end.to change(User, :count).by(user_count * -1) && change(Infomation, :count).by(infomation_count * -1)
      end
    end

    shared_examples_for 'ユーザー1・2未削除' do
      it 'ユーザー1・2、ユーザー1・2向けのお知らせが削除されない' do
        task.invoke(dry_run)
        expect(User.find_by(id: user1.id)).not_to be_nil
        expect(User.find_by(id: user2.id)).not_to be_nil
        expect(Infomation.find_by(user_id: user1.id)).not_to be_nil
        expect(Infomation.find_by(user_id: user2.id)).not_to be_nil
      end
    end
    shared_examples_for 'ユーザー3削除' do
      it 'ユーザー3が削除される' do
        task.invoke(dry_run)
        expect(User.find_by(id: user3.id)).to be_nil
      end
    end
    shared_examples_for 'ユーザー3・4削除' do
      it 'ユーザー3・4、ユーザー4向けのお知らせが削除される' do
        task.invoke(dry_run)
        expect(User.find_by(id: user3.id)).to be_nil
        expect(User.find_by(id: user4.id)).to be_nil
        expect(Infomation.find_by(user_id: user4.id)).to be_nil
      end
    end

    # テストケース
    shared_examples_for '[2件]ドライランtrue' do
      let(:dry_run) { 'true' }
      it_behaves_like '削除件数', 0, 0
    end
    shared_examples_for '[3件]ドライランtrue' do
      let(:dry_run) { 'true' }
      it_behaves_like '削除件数', 0, 0
    end
    shared_examples_for '[4件]ドライランtrue' do
      let(:dry_run) { 'true' }
      it_behaves_like '削除件数', 0, 0
    end
    shared_examples_for '[2件]ドライランfalse' do
      let(:dry_run) { 'false' }
      it_behaves_like '削除件数', 0, 0
      it_behaves_like 'ユーザー1・2未削除'
    end
    shared_examples_for '[3件]ドライランfalse' do
      let(:dry_run) { 'false' }
      it_behaves_like '削除件数', 1, 0
      it_behaves_like 'ユーザー1・2未削除'
      it_behaves_like 'ユーザー3削除'
    end
    shared_examples_for '[4件]ドライランfalse' do
      let(:dry_run) { 'false' }
      it_behaves_like '削除件数', 2, 1
      it_behaves_like 'ユーザー1・2未削除'
      it_behaves_like 'ユーザー3・4削除'
    end

    context '2件（削除予約1件、削除対象0件）' do
      it_behaves_like '[2件]ドライランtrue'
      it_behaves_like '[2件]ドライランfalse'
    end
    context '3件（削除予約1件、削除対象1件）' do
      include_context 'ユーザー作成3'
      it_behaves_like '[3件]ドライランtrue'
      it_behaves_like '[3件]ドライランfalse'
    end
    context '4件（削除予約1件、削除対象2件）' do
      include_context 'ユーザー作成3'
      include_context 'ユーザー作成4'
      it_behaves_like '[4件]ドライランtrue'
      it_behaves_like '[4件]ドライランfalse'
    end
  end
end
