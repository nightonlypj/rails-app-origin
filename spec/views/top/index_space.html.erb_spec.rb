require 'rails_helper'

# 前提条件
#   存在するサブドメイン # Tips: 存在しないサブドメインで使う事はない（viewだけではベースドメインと区別が付かない）
# テストパターン
#   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
RSpec.describe 'top/index_space', type: :view do
  include_context 'リクエストスペース作成'

  # テスト内容
  shared_examples_for 'スペース情報表示' do
    it 'スペース名が含まれる' do
      render
      expect(rendered).to include(@request_space.name)
    end
    it 'スペーストップのパスが含まれる' do
      render
      expect(rendered).to include("\"#{root_path}\"")
    end
  end

  # テストケース

  context '未ログイン' do
    it_behaves_like 'スペース情報表示'
  end
  context 'ログイン中' do
    include_context 'ログイン処理'
    it_behaves_like 'スペース情報表示'
  end
  context 'ログイン中（削除予約済み）' do
    include_context 'ログイン処理', true
    it_behaves_like 'スペース情報表示'
  end
end
