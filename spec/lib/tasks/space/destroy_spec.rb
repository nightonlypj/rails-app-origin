require 'rake_helper'

RSpec.describe :space, type: :task do
  # スペース削除（削除予定日時以降）
  # テストパターン
  #   削除対象: ない, ある
  #     削除予定日時: ない, 過去, 未来
  #     ＋ユーザー: いる
  #     ＋メンバー: いない, いる
  #     ＋ダウンロード: ない, ある（ファイル: ない, ある）
  #     ＋招待: ない, ある
  #   ドライラン: true, false
  describe 'space:destroy' do
    let(:task) { Rake.application['space:destroy'] }
    before_all do
      user = FactoryBot.create(:user)
      FactoryBot.create(:space, created_user: user, destroy_schedule_at: nil)
      space = FactoryBot.create(:space, created_user: user, destroy_schedule_at: Time.current + 1.minute)
      FactoryBot.create(:member, space: space, user: user)
      download = FactoryBot.create(:download, user: user, space: space)
      FactoryBot.create(:download_file, download: download)
      FactoryBot.create(:invitation, space: space, created_user: user)
    end
    shared_context '削除対象作成' do
      let_it_be(:user) { FactoryBot.create(:user) }
      let_it_be(:spaces) do
        [
          FactoryBot.create(:space, created_user: user, destroy_schedule_at: Time.current - 2.minute),
          FactoryBot.create(:space, created_user: user, destroy_schedule_at: Time.current - 1.minute)
        ]
      end
      let_it_be(:members) { FactoryBot.create_list(:member, 1, space: spaces[1], user: user) }
      let_it_be(:downloads) { FactoryBot.create_list(:download, 2, user: user, space: spaces[1]) }
      let_it_be(:download_files) { FactoryBot.create_list(:download_file, 1, download: downloads[0]) }
      let_it_be(:invitations) { FactoryBot.create_list(:invitation, 1, space: spaces[1], created_user: user) }
    end

    # テスト内容
    shared_examples_for 'OK' do
      let!(:before_space_count)         { Space.count }
      let!(:before_member_count)        { Member.count }
      let!(:before_download_count)      { Download.count }
      let!(:before_download_file_count) { DownloadFile.count }
      let!(:before_invitation_count)    { Invitation.count }
      let!(:before_user_count)          { User.count }
      it '削除される（ユーザー除く）' do
        task.invoke(dry_run)
        expect(Space.count).to eq(before_space_count - spaces.count)
        expect(Space.exists?(id: spaces)).to eq(false)
        expect(Member.count).to eq(before_member_count - members.count)
        expect(Member.exists?(id: members)).to eq(false)
        expect(Download.count).to eq(before_download_count - downloads.count)
        expect(Download.exists?(id: downloads)).to eq(false)
        expect(DownloadFile.count).to eq(before_download_file_count - download_files.count)
        expect(DownloadFile.exists?(id: download_files)).to eq(false)
        expect(Invitation.count).to eq(before_invitation_count - invitations.count)
        expect(Invitation.exists?(id: invitations)).to eq(false)
        expect(User.count).to eq(before_user_count)
      end
    end
    shared_examples_for 'NG' do
      let!(:before_space_count)         { Space.count }
      let!(:before_member_count)        { Member.count }
      let!(:before_download_count)      { Download.count }
      let!(:before_download_file_count) { DownloadFile.count }
      let!(:before_invitation_count)    { Invitation.count }
      let!(:before_user_count)          { User.count }
      it '削除されない' do
        task.invoke(dry_run)
        expect(Space.count).to eq(before_space_count)
        expect(Member.count).to eq(before_member_count)
        expect(Download.count).to eq(before_download_count)
        expect(DownloadFile.count).to eq(before_download_file_count)
        expect(Invitation.count).to eq(before_invitation_count)
        expect(User.count).to eq(before_user_count)
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
