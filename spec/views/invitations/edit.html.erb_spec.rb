require 'rails_helper'

RSpec.describe 'invitations/edit', type: :view do
  let_it_be(:user) { FactoryBot.create(:user) }
  before_all do
    @space = FactoryBot.create(:space, created_user: user)
    @current_member = FactoryBot.create(:member, :admin, space: @space, user:)
  end

  # テスト内容
  shared_examples_for '表示' do |delete, undo_delete|
    it '対象の送信先と項目が含まれる' do
      render
      assert_select 'form[action=?][method=?]', update_invitation_path(space_code: @space.code, code: @invitation.code), 'post' do
        assert_select 'input[name=?]', 'invitation[ended_date]'
        assert_select 'input[name=?]', 'invitation[ended_time]'
        assert_select 'input[name=?]', 'invitation[memo]'
        assert_select 'input[name=?]', 'invitation[delete]', count: delete * 2 # NOTE: hiddenでvalue=0が入る為
        assert_select 'input[name=?]', 'invitation[undo_delete]', count: undo_delete * 2
        assert_select 'input[type=?]', 'button'
      end
    end
  end

  # テストケース
  context '有効' do
    before_all { @invitation = FactoryBot.create(:invitation, :active, space: @space, created_user: user) }
    it_behaves_like '表示', 1, 0
  end
  context '期限切れ' do
    before_all { @invitation = FactoryBot.create(:invitation, :expired, :domains, space: @space, created_user: user) }
    it_behaves_like '表示', 0, 0
  end
  context '削除済み' do
    before_all { @invitation = FactoryBot.create(:invitation, :deleted, :email, space: @space, created_user: user) }
    it_behaves_like '表示', 0, 1
  end
end
