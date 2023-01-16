require 'rake_helper'

RSpec.describe :download, type: :task do
  # ダウンロード削除（完了日時か依頼日時の#{Settings['download_destroy_schedule_days']}日後以降）
  # テストパターン
  #   削除対象: ない, ある
  #     完了日時: ない, 現在日時＋設定日数以前, 現在日時＋設定日数以降
  #     依頼日時: 現在日時＋設定日数以前, 現在日時＋設定日数以降
  #     ＋ユーザー: いる
  #     ＋スペース: ある
  #     ＋ダウンロードファイル: ない, ある
  #   ドライラン: true, false
  describe 'download:destroy' do
    let(:task) { Rake.application['download:destroy'] }
    let_it_be(:before_date) { Time.current - Settings['download_destroy_schedule_days'].days - 1.minute }
    let_it_be(:after_date)  { Time.current - Settings['download_destroy_schedule_days'].days + 1.minute }
    before_all do
      user = FactoryBot.create(:user)
      space = FactoryBot.create(:space, created_user: user)
      FactoryBot.create(:download, user: user, space: space, completed_at: nil, requested_at: after_date)
      FactoryBot.create(:download, user: user, space: space, completed_at: after_date, requested_at: before_date)
      download = FactoryBot.create(:download, user: user, space: space, completed_at: after_date, requested_at: after_date)
      FactoryBot.create_list(:download_file, 1, download: download)
    end
    shared_context '削除対象作成' do
      let_it_be(:user) { FactoryBot.create(:user) }
      let_it_be(:space) { FactoryBot.create(:space) }
      let_it_be(:downloads) do
        [
          FactoryBot.create(:download, user: user, space: space, completed_at: nil, requested_at: before_date),
          FactoryBot.create(:download, user: user, space: space, completed_at: before_date, requested_at: before_date),
          FactoryBot.create(:download, user: user, space: space, completed_at: before_date, requested_at: after_date)
        ]
      end
      let_it_be(:download_files) { FactoryBot.create_list(:download_file, 1, download: downloads[2]) }
    end

    # テスト内容
    shared_examples_for 'OK' do
      let!(:before_download_count)      { Download.count }
      let!(:before_download_file_count) { DownloadFile.count }
      let!(:before_user_count)          { User.count }
      let!(:before_space_count)         { Space.count }
      it '削除される（ユーザー・スペース除く）' do
        task.invoke(dry_run)
        expect(Download.count).to eq(before_download_count - downloads.count)
        expect(Download.where(id: downloads).exists?).to eq(false)
        expect(DownloadFile.count).to eq(before_download_file_count - download_files.count)
        expect(DownloadFile.where(id: download_files).exists?).to eq(false)
        expect(User.count).to eq(before_user_count)
        expect(Space.count).to eq(before_space_count)
      end
    end
    shared_examples_for 'NG' do
      let!(:before_download_count)      { Download.count }
      let!(:before_download_file_count) { DownloadFile.count }
      let!(:before_user_count)          { User.count }
      let!(:before_space_count)         { Space.count }
      it '削除されない' do
        task.invoke(dry_run)
        expect(Download.count).to eq(before_download_count)
        expect(DownloadFile.count).to eq(before_download_file_count)
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
