require 'rake_helper'

RSpec.describe :user, type: :task do
  # ユーザーアカウント削除（削除予定日時以降）
  # 前提条件
  #   削除予定日時なし・未来のユーザーが存在する
  # テストパターン
  #   削除対象: ない, ある
  #   ドライラン: true, false
  describe 'user:destroy' do
    subject { Rake.application['user:destroy'].execute('dry_run' => dry_run) }

    before_all do
      FactoryBot.create(:user, destroy_schedule_at: nil)
      FactoryBot.create(:infomation, :user, user: FactoryBot.create(:user, destroy_schedule_at: 1.minute.from_now))
    end

    shared_examples '削除' do
      it '削除される' do
        expect do
          subject
        end.to change(User, :count).by(- users.count)
          .and change(Infomation, :count).by(- infomations.count)
      end
    end
    shared_examples '未削除' do
      it '削除されない' do
        expect do
          subject
        end.to not_change(User, :count)
          .and not_change(Infomation, :count)
      end
    end

    context '削除対象がない' do
      context 'ドライランがtrue' do
        let(:dry_run) { 'true' }

        it_behaves_like '未削除'
      end
      context 'ドライランがfalse' do
        let(:dry_run) { 'false' }

        it_behaves_like '未削除'
      end
    end
    context '削除対象がある' do
      let_it_be(:users) do
        [
          FactoryBot.create(:user, destroy_schedule_at: 2.minutes.ago),
          FactoryBot.create(:user, destroy_schedule_at: 1.minute.ago)
        ]
      end
      let_it_be(:infomations) { [FactoryBot.create(:infomation, :user, user: users[1])] }

      context 'ドライランがtrue' do
        let(:dry_run) { 'true' }

        it_behaves_like '未削除'
      end
      context 'ドライランがfalse' do
        let(:dry_run) { 'false' }

        it_behaves_like '削除'
      end
    end
  end
end
