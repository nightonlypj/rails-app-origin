require 'rails_helper'

RSpec.describe 'spaces/index', type: :view do
  before_all { @spaces = Space.page(1) }

  # テスト内容
  shared_examples_for '入力項目' do |signed_in|
    it '対象の送信先と項目が含まれる' do
      render
      assert_select 'form[action=?][method=?]', spaces_path, 'get' do
        assert_select 'input[name=?]', 'text'
        assert_select 'button[type=?]', 'submit'
        if signed_in
          assert_select 'input[name=?]', 'option'
          assert_select 'input[name=?]', 'exclude_member_space'
        end
      end
    end
  end

  # テストケース
  context '未ログイン' do
    it_behaves_like '入力項目', false
  end
  context 'ログイン中' do
    include_context 'ログイン処理'
    it_behaves_like '入力項目', true
  end
end
