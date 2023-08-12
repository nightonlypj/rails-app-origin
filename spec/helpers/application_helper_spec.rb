require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  # 検索用のjsを使用するかを返却
  # テストパターン
  #   true: スペース一覧, メンバー一覧
  #   false: スペース詳細
  describe 'enable_javascript_search?' do
    subject { helper.enable_javascript_search? }
    before do
      allow(helper).to receive(:controller_name).and_return(controller_name)
      allow(helper).to receive(:action_name).and_return(action_name)
    end

    # テストケース
    context 'スペース一覧' do
      let(:controller_name) { 'spaces' }
      let(:action_name)     { 'index' }
      it_behaves_like 'Value', true
    end
    context 'スペース詳細' do
      let(:controller_name) { 'spaces' }
      let(:action_name)     { 'show' }
      it_behaves_like 'Value', false
    end
    context 'メンバー一覧' do
      let(:controller_name) { 'members' }
      let(:action_name)     { 'index' }
      it_behaves_like 'Value', true
    end
  end

  # 左メニューを開くかを返却
  # テストパターン
  #   true: ユーザー情報変更, ログアウト
  #   false: アカウント削除, ログイン
  describe 'show_user_accordion?' do
    subject { helper.show_user_accordion? }
    before do
      allow(helper).to receive(:controller_name).and_return(controller_name)
      allow(helper).to receive(:action_name).and_return(action_name)
    end

    # テストケース
    context 'ユーザー情報変更' do
      let(:controller_name) { 'registrations' }
      let(:action_name)     { 'edit' }
      it_behaves_like 'Value', true
    end
    context 'アカウント削除' do
      let(:controller_name) { 'registrations' }
      let(:action_name)     { 'delete' }
      it_behaves_like 'Value', false
    end
    context 'ログアウト' do
      let(:controller_name) { 'sessions' }
      let(:action_name)     { 'delete' }
      it_behaves_like 'Value', true
    end
    context 'ログイン' do
      let(:controller_name) { 'sessions' }
      let(:action_name)     { 'new' }
      it_behaves_like 'Value', false
    end
  end

  # アカウント削除予約メッセージを表示するかを返却
  # テストパターン
  #   未ログイン, ログイン中（削除予約なし, あり）
  #   トップページ, アカウント削除取り消し
  describe 'user_destroy_reserved_message?' do
    subject { helper.user_destroy_reserved_message? }
    before do
      allow(helper).to receive(:current_user).and_return(current_user)
      allow(helper).to receive(:controller_name).and_return(controller_name)
      allow(helper).to receive(:action_name).and_return(action_name)
    end

    # テストケース
    shared_examples_for '[なし]トップページ' do
      let(:controller_name) { 'top' }
      let(:action_name)     { 'index' }
      it_behaves_like 'Value', false
    end
    shared_examples_for '[あり]トップページ' do
      let(:controller_name) { 'top' }
      let(:action_name)     { 'index' }
      it_behaves_like 'Value', true
    end
    shared_examples_for '[*]アカウント削除取り消し' do
      let(:controller_name) { 'registrations' }
      let(:action_name)     { 'undo_delete' }
      it_behaves_like 'Value', false
    end

    context '未ログイン' do
      let_it_be(:current_user) { nil }
      it_behaves_like '[なし]トップページ'
      it_behaves_like '[*]アカウント削除取り消し'
    end
    context 'ログイン中（削除予約なし）' do
      let_it_be(:current_user) { FactoryBot.create(:user) }
      it_behaves_like '[なし]トップページ'
      it_behaves_like '[*]アカウント削除取り消し'
    end
    context 'ログイン中（削除予約あり）' do
      let_it_be(:current_user) { FactoryBot.create(:user, :destroy_reserved) }
      it_behaves_like '[あり]トップページ'
      it_behaves_like '[*]アカウント削除取り消し'
    end
  end

  # スペース削除予約メッセージを表示するかを返却
  # テストパターン
  #   削除予約: ない, ある
  #   トップページ, スペース一覧, スペーストップ, スペース削除取り消し, メンバー一覧
  describe 'space_destroy_reserved_message?' do
    subject { helper.space_destroy_reserved_message? }
    before do
      @space = space
      allow(helper).to receive(:controller_name).and_return(controller_name)
      allow(helper).to receive(:action_name).and_return(action_name)
    end

    # テストケース
    shared_examples_for '[*]トップページ' do
      let(:controller_name) { 'top' }
      let(:action_name)     { 'index' }
      it_behaves_like 'Value', false
    end
    shared_examples_for '[*]スペース一覧' do
      let(:controller_name) { 'spaces' }
      let(:action_name)     { 'index' }
      it_behaves_like 'Value', false
    end
    shared_examples_for '[ない]スペーストップ' do
      let(:controller_name) { 'spaces' }
      let(:action_name)     { 'show' }
      it_behaves_like 'Value', false
    end
    shared_examples_for '[ある]スペーストップ' do
      let(:controller_name) { 'spaces' }
      let(:action_name)     { 'show' }
      it_behaves_like 'Value', true
    end
    shared_examples_for '[*]スペース削除取り消し' do
      let(:controller_name) { 'spaces' }
      let(:action_name)     { 'undo_delete' }
      it_behaves_like 'Value', false
    end
    shared_examples_for '[ない]メンバー一覧' do
      let(:controller_name) { 'members' }
      let(:action_name)     { 'show' }
      it_behaves_like 'Value', false
    end
    shared_examples_for '[ある]メンバー一覧' do
      let(:controller_name) { 'members' }
      let(:action_name)     { 'show' }
      it_behaves_like 'Value', true
    end

    context '削除予約がない' do
      let_it_be(:space) { FactoryBot.create(:space) }
      it_behaves_like '[*]トップページ'
      it_behaves_like '[*]スペース一覧'
      it_behaves_like '[ない]スペーストップ'
      it_behaves_like '[*]スペース削除取り消し'
      it_behaves_like '[ない]メンバー一覧'
    end
    context '削除予約がある' do
      let_it_be(:space) { FactoryBot.create(:space, :destroy_reserved) }
      it_behaves_like '[*]トップページ'
      it_behaves_like '[*]スペース一覧'
      it_behaves_like '[ある]スペーストップ'
      it_behaves_like '[*]スペース削除取り消し'
      it_behaves_like '[ある]メンバー一覧'
    end
  end

  # 有効なメールアドレス確認トークンかを返却
  # テストパターン
  #   メールアドレス変更: なし, あり, 期限切れ
  describe 'user_valid_confirmation_token?' do
    subject { helper.user_valid_confirmation_token? }
    before do
      allow(helper).to receive(:devise_mapping).and_return(Devise.mappings[:user])
      allow(helper).to receive(:current_user).and_return(current_user)
    end

    # テストケース
    context 'メールアドレス変更なし' do
      let_it_be(:current_user) { FactoryBot.create(:user) }
      it_behaves_like 'Value', false
    end
    context 'メールアドレス変更あり' do
      let_it_be(:current_user) { FactoryBot.create(:user, :email_changed) }
      it_behaves_like 'Value', true
    end
    context 'メールアドレス変更期限切れ' do
      let_it_be(:current_user) { FactoryBot.create(:user, :expired_email_change) }
      it_behaves_like 'Value', false
    end
  end

  # バリデーション表示のクラス名を返却
  # テストパターン
  #   enabled: false, true
  #   key: 存在しない, 存在する
  #   subkey: nil, 存在しない, 存在する
  describe 'validate_class_name' do
    subject do
      if subkey.nil?
        helper.validate_class_name(enabled, user, key)
      else
        helper.validate_class_name(enabled, user, key, subkey)
      end
    end
    let_it_be(:user) { FactoryBot.create(:user) }
    before_all { user.errors.add(:email, 'メッセージ') }

    # テストケース
    context 'enabledがfalse' do
      let(:enabled)  { false }
      let(:key)      { nil }
      let(:subkey)   { nil }
      it_behaves_like 'Value', '', '空'
    end
    context 'enabledがtrue' do
      let(:enabled) { true }
      context 'keyが存在しない' do
        let(:key) { :not }
        context 'subkeyがnil' do
          let(:subkey) { nil }
          it_behaves_like 'Value', ' is-valid'
        end
        context 'subkeyが存在しない' do
          let(:subkey) { :not }
          it_behaves_like 'Value', ' is-valid'
        end
        context 'subkeyが存在する' do
          let(:subkey) { :email }
          it_behaves_like 'Value', ' is-invalid'
        end
      end
      context 'keyが存在する' do
        let(:key) { :email }
        context 'subkeyがnil' do
          let(:subkey) { nil }
          it_behaves_like 'Value', ' is-invalid'
        end
        context 'subkeyが存在しない' do
          let(:subkey) { :not }
          it_behaves_like 'Value', ' is-invalid'
        end
        context 'subkeyが存在する' do
          let(:subkey) { :email }
          it_behaves_like 'Value', ' is-invalid'
        end
      end
    end
  end

  # パスワードのバリデーション表示のクラス名を返却 # NOTE: パスワードは再入力で復元しない為
  # テストパターン
  #   enabled: false, true
  describe 'validate_password_class_name' do
    subject { helper.validate_password_class_name(enabled) }

    # テストケース
    context 'enabledがfalse' do
      let(:enabled) { false }
      it_behaves_like 'Value', '', '空'
    end
    context 'enabledがtrue' do
      let(:enabled) { true }
      it_behaves_like 'Value', ' is-invalid'
    end
  end

  # 入力項目のサイズクラス名を返却
  # テストパターン
  #   errors: なし, あり
  #   key: 存在しない, 存在する
  describe 'input_size_class_name' do
    subject { helper.input_size_class_name(user, key) }
    let_it_be(:user) { FactoryBot.create(:user) }

    # テストケース
    context 'errorsなし' do
      let(:key) { :not } # NOTE: errorsなしの為、keyが存在する事はない
      it_behaves_like 'Value', ' mb-3'
    end
    context 'errorsあり' do
      before_all { user.errors.add(:email, 'メッセージ') }
      context 'keyが存在しない' do
        let(:key) { :not }
        it_behaves_like 'Value', ' mb-3'
      end
      context 'keyが存在する' do
        let(:key) { :email }
        it_behaves_like 'Value', ' mb-5'
      end
    end
  end

  # 縦並びの入力項目のサイズクラス名を返却
  # テストパターン
  #   enabled: true, false
  #   errors: なし, あり
  #   key: 存在しない, 存在する
  describe 'input_size_class_name_vertical' do
    subject { helper.input_size_class_name_vertical(enabled, user, key) }
    let_it_be(:user) { FactoryBot.create(:user) }

    # テストケース
    context 'enabledがfalse' do
      let(:enabled) { false }
      let(:key)     { :not }
      it_behaves_like 'Value', ' mb-3'
    end
    context 'enabledがtrue' do
      let(:enabled) { true }
      context 'errorsなし' do
        let(:key) { :not } # NOTE: errorsなしの為、keyが存在する事はない
        it_behaves_like 'Value', ' mb-0'
      end
      context 'errorsあり' do
        before_all { user.errors.add(:email, 'メッセージ') }
        context 'keyが存在しない' do
          let(:key) { :not }
          it_behaves_like 'Value', ' mb-0'
        end
        context 'keyが存在する' do
          let(:key) { :email }
          it_behaves_like 'Value', ' mb-4'
        end
      end
    end
  end

  # 文字列を省略して返却
  # テストパターン
  #   length: 0, 1
  #   text: nil, 空, lengthと同じ文字数, lengthより長い
  describe 'text_truncate' do
    subject { helper.text_truncate(text, length) }

    # テストケース
    context 'lengthが0' do
      let(:length) { 0 }
      let(:text)   { 'a' }
      it_behaves_like 'Value', nil, 'nil'
    end
    context 'lengthが1' do
      let(:length) { 1 }
      context 'nil' do
        let(:text) { nil }
        it_behaves_like 'Value', nil, 'nil'
      end
      context '空' do
        let(:text) { '' }
        it_behaves_like 'Value', '', '空'
      end
      context 'lengthと同じ文字数' do
        let(:text) { 'a' }
        it_behaves_like 'Value', 'a'
      end
      context 'lengthより長い' do
        let(:text) { 'aa' }
        it_behaves_like 'Value', 'a...'
      end
    end
  end

  # ページの最初の番号を返却
  # 前提条件
  #   ページ最大2件
  # テストパターン
  #   0件, 2件, 3件2頁
  describe 'first_page_number' do
    subject do
      FactoryBot.create_list(:user, count)
      models = User.page(page).per(2)
      helper.first_page_number(models)
    end

    # テストケース
    context '0件' do
      let(:count) { 0 }
      let(:page)  { 1 }
      it_behaves_like 'Value', '1'
    end
    context '2件' do
      let(:count) { 2 }
      let(:page)  { 1 }
      it_behaves_like 'Value', '1'
    end
    context '3件2頁' do
      let(:count) { 3 }
      let(:page)  { 2 }
      it_behaves_like 'Value', '3'
    end
  end

  # ページの最後の番号を返却
  # 前提条件
  #   ページ最大2件
  # テストパターン
  #   0件, 2件, 3件2頁
  describe 'last_page_number' do
    subject do
      FactoryBot.create_list(:user, count)
      models = User.page(page).per(2)
      helper.last_page_number(models)
    end

    # テストケース
    context '0件' do
      let(:count) { 0 }
      let(:page)  { 1 }
      it_behaves_like 'Value', '0'
    end
    context '2件' do
      let(:count) { 2 }
      let(:page)  { 1 }
      it_behaves_like 'Value', '2'
    end
    context '3件、2頁' do
      let(:count) { 3 }
      let(:page)  { 2 }
      it_behaves_like 'Value', '3'
    end
  end
end
