require 'rails_helper'

RSpec.describe DownloadsHelper, type: :helper do
  # ダウンロード結果一覧のクラス名を返却
  # テストパターン
  #   パラメータのID: 一致する, 一致しない, ない
  #   ステータス: 処理待ち, 処理中, 成功, 失敗, ダウンロード済み
  describe 'download_lists_class_name' do
    subject { helper.download_lists_class_name(download, target_id) }
    let_it_be(:old_download) { FactoryBot.create(:download) }
    let(:download) { FactoryBot.create(:download, status, user: old_download.user) }

    # テストケース
    context 'パラメータのIDが一致する' do
      let(:target_id) { download.id }
      context 'ステータスが成功' do
        let(:status)    { :success }
        it_behaves_like 'Value', ' row_active'
      end
      context 'ステータスがダウンロード済み' do
        let(:status) { :downloaded }
        it_behaves_like 'Value', ' row_inactive'
      end
    end
    context 'パラメータのIDが一致しない' do
      let(:target_id) { old_download.id }
      let(:status)    { :success }
      it_behaves_like 'Value', nil, 'nil'
    end
    context 'パラメータのIDがない' do
      let(:target_id) { nil }
      context 'ステータスが処理待ち' do
        let(:status) { :waiting }
        it_behaves_like 'Value', nil, 'nil'
      end
      context 'ステータスが処理中' do
        let(:status) { :processing }
        it_behaves_like 'Value', nil, 'nil'
      end
      context 'ステータスが成功' do
        let(:status) { :success }
        it_behaves_like 'Value', ' row_active'
      end
      context 'ステータスが失敗' do
        let(:status) { :failure }
        it_behaves_like 'Value', ' row_inactive'
      end
      context 'ステータスがダウンロード済み' do
        let(:status) { :downloaded }
        it_behaves_like 'Value', ' row_inactive'
      end
    end
  end
end
