require 'rails_helper'

RSpec.describe Infomation, type: :model do
  # 表示対象かを返却
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）
  #   対象: 全員, 自分, 他人
  describe '#display_target?' do
    subject { infomation.display_target?(user) }
    let_it_be(:other_user) { FactoryBot.create(:user) }

    # テストケース
    shared_examples_for '[*]対象が全員' do
      let_it_be(:infomation) { FactoryBot.create(:infomation, :all) }
      it_behaves_like 'Value', true
    end
    shared_examples_for '[ログイン中/削除予約済み]対象が自分' do
      let_it_be(:infomation) { FactoryBot.create(:infomation, :user, user: user) }
      it_behaves_like 'Value', true
    end
    shared_examples_for '[*]対象が他人' do
      let_it_be(:infomation) { FactoryBot.create(:infomation, :user, user: other_user) }
      it_behaves_like 'Value', false
    end

    shared_examples_for '[ログイン中/削除予約済み]' do
      it_behaves_like '[*]対象が全員'
      it_behaves_like '[ログイン中/削除予約済み]対象が自分'
      it_behaves_like '[*]対象が他人'
    end

    context '未ログイン' do
      let(:user) { nil }
      it_behaves_like '[*]対象が全員'
      # it_behaves_like '[未ログイン]対象が自分' # NOTE: 未ログインの為、他人
      it_behaves_like '[*]対象が他人'
    end
    context 'ログイン中' do
      include_context 'ユーザー作成'
      it_behaves_like '[ログイン中/削除予約済み]'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ユーザー作成', :destroy_reserved
      it_behaves_like '[ログイン中/削除予約済み]'
    end
  end
end
