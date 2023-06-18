require 'rake_helper'

RSpec.describe :invitation, type: :task do
  # 招待削除（削除予定日時または終了日時か参加日時から#{Settings.invitation_destroy_schedule_days}日後以降）
  # テストパターン
  #   削除対象: ない, ある
  #     削除予定日時: ない, 過去, 未来
  #     終了日時: ない, 現在日時＋設定日数以前, 現在日時＋設定日数以降
  #     参加日時: ない, 現在日時＋設定日数以前, 現在日時＋設定日数以降
  #     ＋ユーザー: いる
  #     ＋スペース: ある
  #   ドライラン: true, false
  describe 'invitation:destroy' do
    subject { Rake.application['invitation:destroy'].invoke(dry_run) }

    let_it_be(:before_date) { Time.current - Settings.invitation_destroy_schedule_days.days - 1.minute }
    let_it_be(:after_date)  { Time.current - Settings.invitation_destroy_schedule_days.days + 1.minute }
    before_all do
      user = FactoryBot.create(:user)
      space = FactoryBot.create(:space, created_user: user)

      destroy_schedule_at = nil # 削除予定日時がない -> 一部、削除対象
      [nil, before_date, after_date].each do |ended_at|
        [nil, before_date, after_date].each do |email_joined_at|
          next if ended_at == before_date || email_joined_at == before_date # NOTE: 終了日時か参加日時が、現在日時＋設定日数以前だったら削除対象

          FactoryBot.create(:invitation, space: space, created_user: user,
                                         destroy_schedule_at: destroy_schedule_at, ended_at: ended_at, email_joined_at: email_joined_at)
        end
      end

      destroy_schedule_at = Time.current + 1.minute # 削除予定日時が未来 -> 全て削除対象外
      [nil, before_date, after_date].each do |ended_at|
        [nil, before_date, after_date].each do |email_joined_at|
          FactoryBot.create(:invitation, space: space, created_user: user,
                                         destroy_schedule_at: destroy_schedule_at, ended_at: ended_at, email_joined_at: email_joined_at)
        end
      end
    end
    shared_context '削除対象作成' do
      let_it_be(:user) { FactoryBot.create(:user) }
      let_it_be(:space) { FactoryBot.create(:space) }
      let_it_be(:invitations) do
        result = []

        destroy_schedule_at = nil # 削除予定日時がない -> 一部、削除対象
        [nil, before_date, after_date].each do |ended_at|
          [nil, before_date, after_date].each do |email_joined_at|
            next unless ended_at == before_date || email_joined_at == before_date # NOTE: 終了日時か参加日時が、現在日時＋設定日数以前だったら削除対象

            result.push(FactoryBot.create(:invitation, space: space, created_user: user,
                                                       destroy_schedule_at: destroy_schedule_at, ended_at: ended_at, email_joined_at: email_joined_at))
          end
        end

        destroy_schedule_at = Time.current - 1.minute # 削除予定日時が過去 -> 全て削除対象
        [nil, before_date, after_date].each do |ended_at|
          [nil, before_date, after_date].each do |email_joined_at|
            result.push(FactoryBot.create(:invitation, space: space, created_user: user,
                                                       destroy_schedule_at: destroy_schedule_at, ended_at: ended_at, email_joined_at: email_joined_at))
          end
        end

        result
      end
    end

    # テスト内容
    shared_examples_for 'OK' do
      let!(:before_invitation_count) { Invitation.count }
      let!(:before_user_count)       { User.count }
      let!(:before_space_count)      { Space.count }
      it '削除される（ユーザー・スペース除く）' do
        subject
        expect(Invitation.count).to eq(before_invitation_count - invitations.count)
        expect(Invitation.exists?(id: invitations)).to eq(false)
        expect(User.count).to eq(before_user_count)
        expect(Space.count).to eq(before_space_count)
      end
    end
    shared_examples_for 'NG' do
      let!(:before_invitation_count) { Invitation.count }
      let!(:before_user_count)       { User.count }
      let!(:before_space_count)      { Space.count }
      it '削除されない' do
        subject
        expect(Invitation.count).to eq(before_invitation_count)
        expect(User.count).to eq(before_user_count)
        expect(Space.count).to eq(before_space_count)
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
