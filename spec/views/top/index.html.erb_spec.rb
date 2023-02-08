require 'rails_helper'

RSpec.describe 'top/index', type: :view do
  # テスト内容
  shared_examples_for '未ログイン表示' do
    it '対象のパスが含まれない' do
      render
      expect(rendered).not_to include("\"#{spaces_path}\"") # スペース一覧
      expect(rendered).not_to include("\"#{create_space_path}\"") # スペース作成
    end
  end
  shared_examples_for 'ログイン中表示' do
    it '対象のパスが含まれる' do
      render
      if Settings.enable_public_space
        expect(rendered).to include("\"#{spaces_path}\"") # スペース一覧
      else
        expect(rendered).not_to include("\"#{spaces_path}\"")
      end
      expect(rendered).to include("\"#{create_space_path}\"") # スペース作成
    end
  end

  # テストケース
  context '未ログイン' do
    it_behaves_like '未ログイン表示'
  end
  context 'ログイン中' do
    include_context 'ログイン処理'
    it_behaves_like 'ログイン中表示'
  end
  context 'ログイン中（削除予約済み）' do
    include_context 'ログイン処理', :destroy_reserved
    it_behaves_like 'ログイン中表示'
  end
end
