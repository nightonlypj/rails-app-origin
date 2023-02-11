require 'rails_helper'

RSpec.describe 'layouts/application', type: :view do
  next if Settings.api_only_mode

  # テスト内容
  shared_examples_for '未ログイン表示' do
    it '対象のパスが含まれる' do
      render
      expect(rendered).to include("\"#{new_user_session_path}\"") # ログイン
      expect(rendered).to include("\"#{new_user_registration_path}\"") # アカウント登録
      expect(rendered).to include("\"#{infomations_path}\"") # お知らせ
    end
    it '対象のパスが含まれない' do
      render
      expect(rendered).not_to include("\"#{edit_user_registration_path}\"") # ユーザー情報変更
      expect(rendered).not_to include("\"#{destroy_user_session_path}\"") # ログアウト
      expect(rendered).not_to include("\"#{downloads_path}\"") # ダウンロード結果
    end
  end
  shared_examples_for 'ログイン中表示' do
    include_context 'スペース一覧作成', 1, 1, 1, 1
    let(:inside_spaces)  { [@public_spaces[0], @private_spaces[0], @private_spaces[1]] }
    let(:outside_spaces) { [@public_nojoin_spaces[0]] + @public_nojoin_destroy_spaces + @private_nojoin_spaces }
    it '対象のパスが含まれない' do
      render
      expect(rendered).not_to include("\"#{new_user_session_path}\"") # ログイン
      expect(rendered).not_to include("\"#{new_user_registration_path}\"") # アカウント登録
    end
    it '対象のパスが含まれ、未参加スペースは含まれない' do
      render
      expect(rendered).to include("\"#{edit_user_registration_path}\"") # ユーザー情報変更
      expect(rendered).to include("\"#{destroy_user_session_path}\"") # ログアウト
      expect(rendered).to include("\"#{infomations_path}\"") # お知らせ
      expect(rendered).to include("\"#{downloads_path}\"") # ダウンロード結果

      inside_spaces.each do |space| # 参加スペース
        expect(rendered).to include(space.name)
        expect(rendered).to include("\"#{space_path(space.code)}\"")
      end
      outside_spaces.each do |space| # 未参加スペース
        expect(rendered).not_to include(space.name)
        expect(rendered).not_to include("\"#{space_path(space.code)}\"")
      end
    end
  end

  shared_examples_for '削除予約表示' do
    it 'アカウント削除取り消しのパスが含まれる' do
      render
      expect(rendered).to include("\"#{delete_undo_user_registration_path}\"")
    end
  end
  shared_examples_for '削除予約非表示' do
    it 'アカウント削除取り消しのパスが含まれない' do
      render
      expect(rendered).not_to include("\"#{delete_undo_user_registration_path}\"")
    end
  end

  # テストケース
  context '未ログイン' do
    it_behaves_like '未ログイン表示'
    it_behaves_like '削除予約非表示'
  end
  context 'ログイン中' do
    include_context 'ログイン処理'
    it_behaves_like 'ログイン中表示'
    it_behaves_like '削除予約非表示'
  end
  context 'ログイン中（削除予約済み）' do
    include_context 'ログイン処理', :destroy_reserved
    it_behaves_like 'ログイン中表示'
    it_behaves_like '削除予約表示'
  end
end
