require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  # テスト内容（共通）
  shared_examples_for 'true' do
    it 'true' do
      is_expected.to eq(true)
    end
  end
  shared_examples_for 'false' do
    it 'false' do
      is_expected.to eq(false)
    end
  end
  shared_examples_for 'value' do |value|
    it 'value' do
      is_expected.to eq(value)
    end
  end

  # 検索用のjsを使用するかを返却
  # 前提条件
  #   なし
  # テストパターン
  #   true: スペース一覧
  #   false: スペース詳細
  describe 'enable_javascript_search?' do
    subject { helper.enable_javascript_search? }
    before do
      allow(helper).to receive(:controller_name).and_return controller_name
      allow(helper).to receive(:action_name).and_return action_name
    end

    # テストケース
    context 'スペース一覧' do
      let(:controller_name) { 'spaces' }
      let(:action_name)     { 'index' }
      it_behaves_like 'true'
    end
    context 'スペース詳細' do
      let(:controller_name) { 'spaces' }
      let(:action_name)     { 'show' }
      it_behaves_like 'false'
    end
  end

  # 左メニューを開くかを返却
  describe 'user_accordion_show?' do
    subject { helper.user_accordion_show? }
    before do
      allow(helper).to receive(:controller_name).and_return controller_name
      allow(helper).to receive(:action_name).and_return action_name
    end

    # テストケース
    context 'トップページ' do
      let(:controller_name) { 'top' }
      let(:action_name)     { 'index' }
      it_behaves_like 'false'
    end
    context '登録情報変更' do
      let(:controller_name) { 'registrations' }
      let(:action_name)     { 'edit' }
      it_behaves_like 'true'
    end
    context 'ログアウト' do
      let(:controller_name) { 'sessions' }
      let(:action_name)     { 'delete' }
      it_behaves_like 'true'
    end
  end

  # 削除予約メッセージを表示するかを返却
  describe 'destroy_reserved_message?' do
    subject do
      if user.nil?
        helper.destroy_reserved_message?
      else
        helper.destroy_reserved_message?(user)
      end
    end
    before do
      allow(helper).to receive(:current_user).and_return current_user
      allow(helper).to receive(:controller_name).and_return controller_name
      allow(helper).to receive(:action_name).and_return action_name
    end
    let_it_be(:user_active)   { FactoryBot.create(:user) }
    let_it_be(:user_reserved) { FactoryBot.create(:user, :destroy_reserved) }

    # テストケース
    shared_examples_for '[なし]トップページ' do
      let(:controller_name) { 'top' }
      let(:action_name)     { 'index' }
      it_behaves_like 'false'
    end
    shared_examples_for '[あり]トップページ' do
      let(:controller_name) { 'top' }
      let(:action_name)     { 'index' }
      it_behaves_like 'true'
    end
    shared_examples_for '[*]アカウント削除取り消し' do
      let(:controller_name) { 'registrations' }
      let(:action_name)     { 'undo_delete' }
      it_behaves_like 'false'
    end

    context '削除予約なし（パラメータあり）' do
      let(:user)         { user_active }
      let(:current_user) { nil }
      it_behaves_like '[なし]トップページ'
      it_behaves_like '[*]アカウント削除取り消し'
    end
    context '削除予約なし（パラメータなし）' do
      let(:user)         { nil }
      let(:current_user) { user_active }
      it_behaves_like '[なし]トップページ'
      it_behaves_like '[*]アカウント削除取り消し'
    end
    context '削除予約あり（パラメータあり）' do
      let(:user)         { user_reserved }
      let(:current_user) { nil }
      it_behaves_like '[あり]トップページ'
      it_behaves_like '[*]アカウント削除取り消し'
    end
    context '削除予約あり（パラメータなし）' do
      let(:user)         { nil }
      let(:current_user) { user_reserved }
      it_behaves_like '[あり]トップページ'
      it_behaves_like '[*]アカウント削除取り消し'
    end
  end

  # 有効なメールアドレス確認トークンかを返却
  describe 'user_valid_confirmation_token?' do
    subject { helper.user_valid_confirmation_token? }
    before do
      allow(helper).to receive(:devise_mapping).and_return Devise.mappings[:user]
      allow(helper).to receive(:current_user).and_return current_user
    end

    # テストケース
    context 'メールアドレス変更なし' do
      let_it_be(:current_user) { FactoryBot.create(:user) }
      it_behaves_like 'false'
    end
    context 'メールアドレス変更中' do
      let_it_be(:current_user) { FactoryBot.create(:user, :email_changed) }
      it_behaves_like 'true'
    end
    context 'メールアドレス変更期限切れ' do
      let_it_be(:current_user) { FactoryBot.create(:user, :expired_email_change) }
      it_behaves_like 'false'
    end
  end

  # バリデーション表示のクラス名を返却
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
      it_behaves_like 'value', ''
    end
    context 'enabledがtrue' do
      let(:enabled) { true }
      context 'keyが存在しない' do
        let(:key) { :not }
        context 'subkeyがnil' do
          let(:subkey) { nil }
          it_behaves_like 'value', ' is-valid'
        end
        context 'subkeyが存在しない' do
          let(:subkey) { :not }
          it_behaves_like 'value', ' is-valid'
        end
        context 'subkeyが存在する' do
          let(:subkey) { :email }
          it_behaves_like 'value', ' is-invalid'
        end
      end
      context 'keyが存在する' do
        let(:key) { :email }
        context 'subkeyがnil' do
          let(:subkey) { nil }
          it_behaves_like 'value', ' is-invalid'
        end
        context 'subkeyが存在しない' do
          let(:subkey) { :not }
          it_behaves_like 'value', ' is-invalid'
        end
        context 'subkeyが存在する' do
          let(:subkey) { :email }
          it_behaves_like 'value', ' is-invalid'
        end
      end
    end
  end

  # パスワードのバリデーション表示のクラス名を返却 # Tips: パスワードは再入力で復元しない為
  describe 'validate_password_class_name' do
    subject { helper.validate_password_class_name(enabled) }

    # テストケース
    context 'enabledがfalse' do
      let(:enabled) { false }
      it_behaves_like 'value', ''
    end
    context 'enabledがtrue' do
      let(:enabled) { true }
      it_behaves_like 'value', ' is-invalid'
    end
  end

  # 入力項目のサイズクラス名を返却
  describe 'input_size_class_name' do
    subject { helper.input_size_class_name(user, key) }
    let_it_be(:user) { FactoryBot.create(:user) }

    # テストケース
    context 'errorsなし' do
      let(:key) { :not }
      it_behaves_like 'value', ' mb-3'
    end
    context 'errorsあり' do
      before_all { user.errors.add(:email, 'メッセージ') }
      context 'keyが存在しない' do
        let(:key) { :not }
        it_behaves_like 'value', ' mb-3'
      end
      context 'keyが存在する' do
        let(:key) { :email }
        it_behaves_like 'value', ' mb-5'
      end
    end
  end

  # 文字列を省略して返却
  describe 'text_truncate' do
    subject { helper.text_truncate(text, length) }

    # テストケース
    context 'lengthが0' do
      let(:length) { 0 }
      let(:text)   { 'a' }
      it_behaves_like 'value', nil
    end
    context 'lengthが1' do
      let(:length) { 1 }
      context 'nil' do
        let(:text) { nil }
        it_behaves_like 'value', nil
      end
      context '空' do
        let(:text) { '' }
        it_behaves_like 'value', ''
      end
      context 'lengthと同じ文字数' do
        let(:text) { 'a' }
        it_behaves_like 'value', 'a'
      end
      context 'lengthより長い' do
        let(:text) { 'aa' }
        it_behaves_like 'value', 'a...'
      end
    end
  end
end
