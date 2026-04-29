require 'rake_helper'

RSpec.describe :all, type: :task do
  # 全ての削除Taskを実行
  # テストパターン
  #   ドライラン: true, false
  describe 'all:destroy' do
    subject { Rake.application['all:destroy'].execute('dry_run' => dry_run) }

    shared_examples '正常終了' do
      it 'エラーが発生しない' do
        expect { subject }.not_to raise_error
      end
    end

    context 'ドライランがtrue' do
      let(:dry_run) { 'true' }

      it_behaves_like '正常終了'
    end
    context 'ドライランがfalse' do
      let(:dry_run) { 'false' }

      it_behaves_like '正常終了'
    end
  end
end
