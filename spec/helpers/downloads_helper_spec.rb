require 'rails_helper'

RSpec.describe DownloadsHelper, type: :helper do
  # ダウンロード結果一覧のクラス名を返却
  # テストパターン
  #   ステータス: 処理待ち, 処理中, 成功, 失敗
  #   最終ダウンロード日時: ない, ある
  #   パラメータのID: 一致する, 一致しない
  describe 'download_lists_class_name' do
    subject { helper.download_lists_class_name(download, params_id) }
    let_it_be(:old_download) { FactoryBot.create(:download) }
    let(:download) { FactoryBot.create(:download, status: status, last_downloaded_at: last_downloaded_at) }

    # テスト内容
    shared_examples_for 'value' do |value|
      it 'value' do
        is_expected.to eq(value)
      end
    end

    # テストケース
    shared_examples_for '[*][ない]パラメータのIDが一致する' do
      let(:params_id) { download.id.to_s }
      it_behaves_like 'value', ' row_active'
    end
    shared_examples_for '[成功][ある]パラメータのIDが一致する' do
      let(:params_id) { download.id.to_s }
      it_behaves_like 'value', ' row_inactive'
    end
    shared_examples_for '[処理待ち/処理中][ない]パラメータのIDが一致しない' do
      let(:params_id) { old_download.id.to_s }
      it_behaves_like 'value', nil
    end
    shared_examples_for '[成功][ない]パラメータのIDが一致しない' do
      let(:params_id) { old_download.id.to_s }
      it_behaves_like 'value', ' row_active'
    end
    shared_examples_for '[失敗][ない]パラメータのIDが一致しない' do
      let(:params_id) { old_download.id.to_s }
      it_behaves_like 'value', ' row_inactive'
    end
    shared_examples_for '[成功][ある]パラメータのIDが一致しない' do
      let(:params_id) { old_download.id.to_s }
      it_behaves_like 'value', ' row_inactive'
    end

    shared_examples_for '[処理待ち]最終ダウンロード日時がない' do
      let(:last_downloaded_at) { nil }
      it_behaves_like '[*][ない]パラメータのIDが一致する'
      it_behaves_like '[処理待ち/処理中][ない]パラメータのIDが一致しない'
    end
    shared_examples_for '[処理中]最終ダウンロード日時がない' do
      let(:last_downloaded_at) { nil }
      it_behaves_like '[*][ない]パラメータのIDが一致する'
      it_behaves_like '[処理待ち/処理中][ない]パラメータのIDが一致しない'
    end
    shared_examples_for '[成功]最終ダウンロード日時がない' do
      let(:last_downloaded_at) { nil }
      it_behaves_like '[*][ない]パラメータのIDが一致する'
      it_behaves_like '[成功][ない]パラメータのIDが一致しない'
    end
    shared_examples_for '[失敗]最終ダウンロード日時がない' do
      let(:last_downloaded_at) { nil }
      it_behaves_like '[*][ない]パラメータのIDが一致する'
      it_behaves_like '[失敗][ない]パラメータのIDが一致しない'
    end
    shared_examples_for '[成功]最終ダウンロード日時がある' do
      let(:last_downloaded_at) { Time.current }
      it_behaves_like '[成功][ある]パラメータのIDが一致する'
      it_behaves_like '[成功][ある]パラメータのIDが一致しない'
    end

    context 'ステータスが処理待ち' do
      let(:status) { :waiting }
      it_behaves_like '[処理待ち]最終ダウンロード日時がない'
      # it_behaves_like '[処理待ち]最終ダウンロード日時がある' # NOTE: 存在しないケース
    end
    context 'ステータスが処理中' do
      let(:status) { :processing }
      it_behaves_like '[処理中]最終ダウンロード日時がない'
      # it_behaves_like '[処理中]最終ダウンロード日時がある' # NOTE: 存在しないケース
    end
    context 'ステータスが成功' do
      let(:status) { :success }
      it_behaves_like '[成功]最終ダウンロード日時がない'
      it_behaves_like '[成功]最終ダウンロード日時がある'
    end
    context 'ステータスが失敗' do
      let(:status) { :failure }
      it_behaves_like '[失敗]最終ダウンロード日時がない'
      # it_behaves_like '[失敗]最終ダウンロード日時がある' # NOTE: 存在しないケース
    end
  end
end
