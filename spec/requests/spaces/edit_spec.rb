require 'rails_helper'

RSpec.describe 'Spaces', type: :request do
  let(:response_json) { response.body.present? ? JSON.parse(response.body) : {} }

  # GET /spaces/update/:code スペース設定変更
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）, APIログイン中, APIログイン中（削除予約済み）
  #   スペース: 存在しない, 公開, 公開（削除予約済み）, 非公開, 非公開（削除予約済み）
  #   権限: ある（管理者）, ない（投稿者, 閲覧者, なし）
  #   ＋URLの拡張子: ない, .json
  #   ＋Acceptヘッダ: HTMLが含まれる, JSONが含まれる
  describe 'GET #edit' do
    subject { get edit_space_path(code: space.code, format: subject_format), headers: auth_headers.merge(accept_headers) }

    let_it_be(:created_user) { FactoryBot.create(:user) }
    shared_context 'valid_condition' do
      let_it_be(:space) { FactoryBot.create(:space, :public, created_user:) }
      before_all { FactoryBot.create(:member, :admin, space:, user:) if user.present? }
    end

    # テスト内容
    shared_examples_for 'ToOK(html/*)' do
      it 'HTTPステータスが200' do
        is_expected.to eq(200)
      end
    end

    # テストケース
    if Settings.api_only_mode
      include_context 'APIログイン処理'
      include_context 'valid_condition'
      it_behaves_like 'ToNG(html)', 406
      it_behaves_like 'ToNG(json)', 406
      next
    end

    shared_examples_for '[ログイン中][削除予約済み]権限がある' do |power|
      before_all { FactoryBot.create(:member, power, space:, user:) }
      it_behaves_like 'ToSpace(html)', 'alert.space.destroy_reserved'
      it_behaves_like 'ToNG(json)', 406
    end
    shared_examples_for '[ログイン中][削除予約なし]権限がある' do |power|
      before_all { FactoryBot.create(:member, power, space:, user:) }
      it_behaves_like 'ToOK(html)'
      it_behaves_like 'ToNG(json)', 406
    end
    shared_examples_for '[ログイン中][削除予約済み]権限がない' do |power|
      before_all { FactoryBot.create(:member, power, space:, user:) if power.present? }
      it_behaves_like 'ToSpace(html)', 'alert.space.destroy_reserved'
      it_behaves_like 'ToNG(json)', 406
    end
    shared_examples_for '[ログイン中][削除予約なし]権限がない' do |power|
      before_all { FactoryBot.create(:member, power, space:, user:) if power.present? }
      it_behaves_like 'ToNG(html)', 403
      it_behaves_like 'ToNG(json)', 406
    end
    shared_examples_for '[ログイン中][削除予約済み]権限がない（なし）' do
      it_behaves_like 'ToNG(html)', 403
      it_behaves_like 'ToNG(json)', 406
    end

    shared_examples_for '[ログイン中][削除予約なし]' do
      it_behaves_like '[ログイン中][削除予約なし]権限がある', :admin
      it_behaves_like '[ログイン中][削除予約なし]権限がない', :writer
      it_behaves_like '[ログイン中][削除予約なし]権限がない', :reader
      it_behaves_like '[ログイン中][削除予約なし]権限がない', nil
    end
    shared_examples_for '[ログイン中][削除予約済み]' do
      it_behaves_like '[ログイン中][削除予約済み]権限がある', :admin
      it_behaves_like '[ログイン中][削除予約済み]権限がない', :writer
      it_behaves_like '[ログイン中][削除予約済み]権限がない', :reader
    end

    shared_examples_for '[ログイン中]スペースが存在しない' do
      let_it_be(:space) { FactoryBot.build_stubbed(:space) }
      it_behaves_like 'ToNG(html)', 404
      it_behaves_like 'ToNG(json)', 406
    end
    shared_examples_for '[ログイン中]スペースが公開' do
      let_it_be(:space) { FactoryBot.create(:space, :public, created_user:) }
      it_behaves_like '[ログイン中][削除予約なし]'
    end
    shared_examples_for '[ログイン中]スペースが公開（削除予約済み）' do
      let_it_be(:space) { FactoryBot.create(:space, :public, :destroy_reserved, created_user:) }
      it_behaves_like '[ログイン中][削除予約済み]'
      it_behaves_like '[ログイン中][削除予約済み]権限がない', nil
    end
    shared_examples_for '[ログイン中]スペースが非公開' do
      let_it_be(:space) { FactoryBot.create(:space, :private, created_user:) }
      it_behaves_like '[ログイン中][削除予約なし]'
    end
    shared_examples_for '[ログイン中]スペースが非公開（削除予約済み）' do
      let_it_be(:space) { FactoryBot.create(:space, :private, :destroy_reserved, created_user:) }
      it_behaves_like '[ログイン中][削除予約済み]'
      it_behaves_like '[ログイン中][削除予約済み]権限がない（なし）'
    end

    context '未ログイン' do
      include_context '未ログイン処理'
      include_context 'valid_condition'
      it_behaves_like 'ToLogin(html)'
      it_behaves_like 'ToNG(json)', 406
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中]スペースが存在しない'
      it_behaves_like '[ログイン中]スペースが公開'
      it_behaves_like '[ログイン中]スペースが公開（削除予約済み）'
      it_behaves_like '[ログイン中]スペースが非公開'
      it_behaves_like '[ログイン中]スペースが非公開（削除予約済み）'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', :destroy_reserved
      include_context 'valid_condition'
      it_behaves_like 'ToSpace(html)', 'alert.user.destroy_reserved'
      it_behaves_like 'ToNG(json)', 406
    end
    context 'APIログイン中' do
      include_context 'APIログイン処理'
      include_context 'valid_condition'
      it_behaves_like 'ToOK(html)' # NOTE: HTMLもログイン状態になる
      it_behaves_like 'ToNG(json)', 406
    end
    context 'APIログイン中（削除予約済み）' do
      include_context 'APIログイン処理', :destroy_reserved
      include_context 'valid_condition'
      it_behaves_like 'ToSpace(html)', 'alert.user.destroy_reserved' # NOTE: HTMLもログイン状態になる
      it_behaves_like 'ToNG(json)', 406
    end
  end
end
