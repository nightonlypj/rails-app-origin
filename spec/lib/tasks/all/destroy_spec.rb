require 'rake_helper'

RSpec.describe :all, type: :task do
  # すべての削除Taskを実行
  # テストパターン
  #   ドライラン: true, false
  describe 'all:destroy' do
    subject { Rake.application['all:destroy'].invoke(dry_run) }

    # テスト内容
    shared_examples_for 'OK' do
      it '正常終了' do
        subject
      end
    end

    # テストケース
    context 'ドライランtrue' do
      let(:dry_run) { 'true' }
      it_behaves_like 'OK'
    end
    context 'ドライランfalse' do
      let(:dry_run) { 'false' }
      it_behaves_like 'OK'
    end
  end
end
