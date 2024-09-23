require 'rake_helper'

RSpec.describe :user, type: :task do
  # ユーザーアカウント削除（削除予定日時以降）
  # テストパターン
  #   削除対象: ない, ある
  #     削除予定日時: ない, 未来, 過去
  #     ＋スペース: ある
  #     ＋お知らせ: ない, ある
  #     ＋メンバー: いない, いる
  #     ＋ダウンロード: ない, ある（ファイル: ない, ある）
  #   ドライラン: true, false
  describe 'user:destroy' do
    subject { Rake.application['user:destroy'].invoke(dry_run) }
    before_all do
      FactoryBot.create(:user, destroy_schedule_at: nil)
      user = FactoryBot.create(:user, destroy_schedule_at: Time.current + 1.minute)
      FactoryBot.create(:infomation, :user, user:)

      space = FactoryBot.create(:space, created_user: user)
      FactoryBot.create(:member, space:, user:)
      download = FactoryBot.create(:download, user:, space:)
      FactoryBot.create(:download_file, download:)
    end

    shared_context '削除対象作成' do
      let_it_be(:users) do
        [
          FactoryBot.create(:user, destroy_schedule_at: Time.current - 2.minutes),
          FactoryBot.create(:user, destroy_schedule_at: Time.current - 1.minute)
        ]
      end
      let_it_be(:infomations) { FactoryBot.create_list(:infomation, 1, :user, user: users[1]) }

      let_it_be(:space) { FactoryBot.create(:space, created_user: users[0]) }
      let_it_be(:members) { FactoryBot.create_list(:member, 1, space:, user: users[1]) }
      let_it_be(:downloads) { FactoryBot.create_list(:download, 2, user: users[1], space:) }
      let_it_be(:download_files) { FactoryBot.create_list(:download_file, 1, download: downloads[0]) }
    end

    # テスト内容
    shared_examples_for 'OK' do
      let!(:before_user_count)       { User.count }
      let!(:before_infomation_count) { Infomation.count }
      let!(:before_member_count)        { Member.count }
      let!(:before_download_count)      { Download.count }
      let!(:before_download_file_count) { DownloadFile.count }
      let!(:before_space_count)         { Space.count }
      it '削除される（スペース除く）' do
        subject
        expect(User.count).to eq(before_user_count - users.count)
        expect(User.exists?(id: users)).to be(false)
        expect(Infomation.count).to eq(before_infomation_count - infomations.count)
        expect(Infomation.exists?(id: infomations)).to be(false)

        expect(Member.count).to eq(before_member_count - members.count)
        expect(Member.exists?(id: members)).to eq(false)
        expect(Download.count).to eq(before_download_count - downloads.count)
        expect(Download.exists?(id: downloads)).to eq(false)
        expect(DownloadFile.count).to eq(before_download_file_count - download_files.count)
        expect(DownloadFile.exists?(id: download_files)).to eq(false)
        expect(Space.count).to eq(before_space_count)
      end
    end
    shared_examples_for 'NG' do
      let!(:before_user_count)       { User.count }
      let!(:before_infomation_count) { Infomation.count }
      let!(:before_member_count)        { Member.count }
      let!(:before_download_count)      { Download.count }
      let!(:before_download_file_count) { DownloadFile.count }
      let!(:before_space_count)         { Space.count }
      it '削除されない' do
        subject
        expect(User.count).to eq(before_user_count)
        expect(Infomation.count).to eq(before_infomation_count)

        expect(Member.count).to eq(before_member_count)
        expect(Download.count).to eq(before_download_count)
        expect(DownloadFile.count).to eq(before_download_file_count)
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
