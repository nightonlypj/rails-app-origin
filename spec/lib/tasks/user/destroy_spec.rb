require 'rake_helper'

RSpec.describe :user, type: :task do
  # ユーザーアカウント削除（削除予定日時以降）
  # テストパターン
  #   削除対象: ない, ある
  #     削除予定日時: ない, 未来, 過去
  #     ＋お知らせ: ない, ある
  #   ドライラン: true, false
  describe 'user:destroy' do
    let(:task) { Rake.application['user:destroy'] }
    before_all do
      FactoryBot.create(:user, destroy_schedule_at: nil)
      user = FactoryBot.create(:user, destroy_schedule_at: Time.current + 1.minute)
      FactoryBot.create(:infomation, :user, user: user)
    end
    shared_context '削除対象作成' do
      let_it_be(:users) do
        [
          FactoryBot.create(:user, destroy_schedule_at: Time.current - 2.minutes),
          FactoryBot.create(:user, destroy_schedule_at: Time.current - 1.minute)
        ]
      end
      let_it_be(:infomations) { FactoryBot.create_list(:infomation, 1, :user, user: users[1]) }
    end

    # テスト内容
    shared_examples_for 'OK' do
      let!(:before_user_count)       { User.count }
      let!(:before_infomation_count) { Infomation.count }
      it '削除される' do
        task.invoke(dry_run)
        expect(User.count).to eq(before_user_count - users.count)
        expect(User.exists?(id: users)).to eq(false)
        expect(Infomation.count).to eq(before_infomation_count - infomations.count)
        expect(Infomation.exists?(id: infomations)).to eq(false)
      end
    end
    shared_examples_for 'NG' do
      let!(:before_user_count)       { User.count }
      let!(:before_infomation_count) { Infomation.count }
      it '削除されない' do
        task.invoke(dry_run)
        expect(User.count).to eq(before_user_count)
        expect(Infomation.count).to eq(before_infomation_count)
      end
    end

    # テストケース
    shared_examples_for '[ない]ドライランtrue' do
      let(:dry_run) { 'true' }
      it_behaves_like 'NG'
    end
    shared_examples_for '[ある]ドライランtrue' do
      let(:dry_run) { 'true' }
      it_behaves_like 'NG'
    end
    shared_examples_for '[ない]ドライランfalse' do
      let(:dry_run) { 'false' }
      it_behaves_like 'NG'
    end
    shared_examples_for '[ある]ドライランfalse' do
      let(:dry_run) { 'false' }
      it_behaves_like 'OK'
    end

    context '削除対象がない' do
      it_behaves_like '[ない]ドライランtrue'
      it_behaves_like '[ない]ドライランfalse'
    end
    context '削除対象がある' do
      include_context '削除対象作成'
      it_behaves_like '[ある]ドライランtrue'
      it_behaves_like '[ある]ドライランfalse'
    end
  end
end
