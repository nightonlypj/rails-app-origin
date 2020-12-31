require 'rails_helper'

# 前提条件
#   ベースドメイン/存在するサブドメイン # Tips: 存在しないサブドメインで使う事はない（viewだけではベースドメインと区別が付かない）
# テストパターン
#   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
#   ベースドメイン, 存在するサブドメイン → 事前にデータ作成
RSpec.describe 'layouts/application', type: :view do
  # テスト内容
  shared_examples_for '未ログイン表示' do
    it 'ログインのパスが含まれる' do
      render
      expect(rendered).to include("\"#{domain}#{new_user_session_path}\"")
    end
    it 'アカウント登録のパスが含まれる' do
      render
      expect(rendered).to include("\"#{domain}#{new_user_registration_path}\"")
    end
    # it 'ログインユーザーの表示名が含まれない' do # Tips: 未ログインの為、対象なし
    # end
    it '登録情報変更のパスが含まれない' do
      render
      expect(rendered).not_to include("\"#{domain}#{edit_user_registration_path}\"")
    end
    it '所属一覧のパスが含まれない' do
      render
      expect(rendered).not_to include("\"#{domain}#{customers_path}\"")
    end
    it 'ログアウトのパスが含まれない' do
      render
      expect(rendered).not_to include("\"#{domain}#{destroy_user_session_path}\"")
    end
  end
  shared_examples_for 'ログイン中表示' do
    it 'ログインのパスが含まれない' do
      render
      expect(rendered).not_to include("\"#{domain}#{new_user_session_path}\"")
    end
    it 'アカウント登録のパスが含まれない' do
      render
      expect(rendered).not_to include("\"#{domain}#{new_user_registration_path}\"")
    end
    it 'ログインユーザーの表示名が含まれる' do
      render
      expect(rendered).to include(user.name)
    end
    it '登録情報変更のパスが含まれる' do
      render
      expect(rendered).to include("\"#{domain}#{edit_user_registration_path}\"")
    end
    it '所属一覧のパスが含まれる' do
      render
      expect(rendered).to include("\"#{domain}#{customers_path}\"")
    end
    it 'ログアウトのパスが含まれる' do
      render
      expect(rendered).to include("\"#{domain}#{destroy_user_session_path}\"")
    end
  end

  shared_examples_for '削除予約表示' do
    it 'アカウント削除取り消しのパスが含まれる' do
      render
      expect(rendered).to include("\"#{domain}#{users_undo_delete_path}\"")
    end
  end
  shared_examples_for '削除予約非表示' do
    it 'アカウント削除取り消しのパスが含まれない' do
      render
      expect(rendered).not_to include("\"#{domain}#{users_undo_delete_path}\"")
    end
  end

  shared_examples_for 'スペース情報表示' do
    it 'スペース名が含まれる' do
      render
      expect(rendered).to include(@request_space.name)
    end
    it 'スペース編集のパスが含まれる' do
      render
      expect(rendered).to include("\"#{edit_space_path}\"")
    end
  end

  # テストケース
  shared_examples_for '[未ログイン]ベースドメイン' do
    let!(:domain) { '' }
    it_behaves_like '未ログイン表示'
    it_behaves_like '削除予約非表示'
    # it_behaves_like 'スペース情報非表示' # Tips: ベースドメインの為、対象なし
  end
  shared_examples_for '[ログイン中]ベースドメイン' do
    let!(:domain) { '' }
    it_behaves_like 'ログイン中表示'
    it_behaves_like '削除予約非表示'
    # it_behaves_like 'スペース情報非表示' # Tips: ベースドメインの為、対象なし
  end
  shared_examples_for '[削除予約済み]ベースドメイン' do
    let!(:domain) { '' }
    it_behaves_like 'ログイン中表示'
    it_behaves_like '削除予約表示'
    # it_behaves_like 'スペース情報非表示' # Tips: ベースドメインの為、対象なし
  end
  shared_examples_for '[未ログイン]存在するサブドメイン' do
    let!(:domain) { "//#{Settings['base_domain']}" }
    include_context 'リクエストスペース作成'
    it_behaves_like '未ログイン表示'
    it_behaves_like '削除予約非表示'
    it_behaves_like 'スペース情報表示'
  end
  shared_examples_for '[ログイン中]存在するサブドメイン' do
    let!(:domain) { "//#{Settings['base_domain']}" }
    include_context 'リクエストスペース作成'
    it_behaves_like 'ログイン中表示'
    it_behaves_like '削除予約非表示'
    it_behaves_like 'スペース情報表示'
  end
  shared_examples_for '[削除予約済み]存在するサブドメイン' do
    let!(:domain) { "//#{Settings['base_domain']}" }
    include_context 'リクエストスペース作成'
    it_behaves_like 'ログイン中表示'
    it_behaves_like '削除予約表示'
    it_behaves_like 'スペース情報表示'
  end

  context '未ログイン' do
    it_behaves_like '[未ログイン]ベースドメイン'
    it_behaves_like '[未ログイン]存在するサブドメイン'
  end
  context 'ログイン中' do
    include_context 'ログイン処理'
    it_behaves_like '[ログイン中]ベースドメイン'
    it_behaves_like '[ログイン中]存在するサブドメイン'
  end
  context 'ログイン中（削除予約済み）' do
    include_context 'ログイン処理', true
    it_behaves_like '[削除予約済み]ベースドメイン'
    it_behaves_like '[削除予約済み]存在するサブドメイン'
  end
end
