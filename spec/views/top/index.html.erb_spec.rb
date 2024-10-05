require 'rails_helper'

RSpec.describe 'top/index', type: :view do
  # テスト内容
  shared_examples_for '未ログイン表示' do
    it '対象のパスが含まれない' do
      render
      expect(rendered).not_to include("\"#{create_space_path}\"") # スペース作成
    end
  end
  shared_examples_for 'ログイン中表示' do
    it '対象のパスが含まれる' do
      render
      expect(rendered).to include("\"#{create_space_path}\"") # スペース作成
    end
  end

  shared_examples_for '公開スペースあり' do
    before_all do
      @public_spaces = FactoryBot.create_list(:space, 2, :public)
    end
    it "対象のパスが#{Settings.enable_public_space ? '含まれる' : '含まれない'}" do
      render
      if Settings.enable_public_space
        expect(rendered).to include("\"#{spaces_path}\"") # スペース一覧
      else
        expect(rendered).not_to include("\"#{spaces_path}\"") # スペース一覧
      end
      @public_spaces.each do |space| # 公開スペース
        expect(rendered).to include(space.name)
        expect(rendered).to include("\"#{space_path(code: space.code)}\"")
      end
    end
  end
  shared_examples_for '公開スペースなし' do
    it '対象のパスが含まれない' do
      render
      expect(rendered).not_to include("\"#{spaces_path}\"") # スペース一覧
    end
  end

  # テストケース
  context '未ログイン' do
    it_behaves_like '未ログイン表示'
    it_behaves_like '公開スペースあり'
    it_behaves_like '公開スペースなし'
  end
  context 'ログイン中' do
    include_context 'ログイン処理'
    it_behaves_like 'ログイン中表示'
    it_behaves_like '公開スペースあり'
    it_behaves_like '公開スペースなし'
  end
  context 'ログイン中（削除予約済み）' do
    include_context 'ログイン処理', :destroy_reserved
    it_behaves_like 'ログイン中表示'
    it_behaves_like '公開スペースあり'
    it_behaves_like '公開スペースなし'
  end
end
