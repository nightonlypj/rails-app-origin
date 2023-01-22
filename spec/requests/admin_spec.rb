require 'rails_helper'

RSpec.describe 'Admin', type: :request do
  # GET / RailsAdmin
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）, ログイン中（管理者）
  describe 'GET rails_admin' do
    subject { get rails_admin_path }

    # テストケース
    shared_examples_for '[未ログイン/ログイン中/削除予約済み]' do
      it_behaves_like 'ToAdminLogin', 'devise.failure.unauthenticated', nil
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン/ログイン中/削除予約済み]'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[未ログイン/ログイン中/削除予約済み]'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', :destroy_reserved
      it_behaves_like '[未ログイン/ログイン中/削除予約済み]'
    end
    context 'ログイン中（管理者）' do
      include_context 'ログイン処理（管理者）'
      it_behaves_like 'ToOK[status]'
    end
  end
end
