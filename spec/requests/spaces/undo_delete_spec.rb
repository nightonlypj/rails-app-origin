require 'rails_helper'

RSpec.describe 'Spaces', type: :request do
  let(:response_json) { response.body.present? ? JSON.parse(response.body) : {} }

  # GET /spaces/undo_delete/:code スペース削除取り消し
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）, APIログイン中, APIログイン中（削除予約済み）
  #   スペース: 存在しない, 公開, 非公開
  #   削除予約: ある, ない
  #   権限: ある（管理者）, ない（投稿者, 閲覧者, なし）
  #   ＋URLの拡張子: ない, .json
  #   ＋Acceptヘッダ: HTMLが含まれる, JSONが含まれる
  describe 'GET #undo_delete' do
    subject { get delete_undo_space_path(code: space.code, format: subject_format), headers: auth_headers.merge(accept_headers) }

    shared_context 'valid_condition' do
      let_it_be(:space) { FactoryBot.create(:space, :destroy_reserved) }
      include_context 'set_member_power', :admin
    end

    # テスト内容
    shared_examples_for 'ToOK(html/*)' do
      it_behaves_like 'ToOK[status]'
    end

    # テストケース
    shared_examples_for '[ログイン中][*][ある]権限がある' do |power|
      include_context 'set_member_power', power
      it_behaves_like 'ToOK(html)'
      it_behaves_like 'ToNG(json)', 406
    end
    shared_examples_for '[ログイン中][*][ない]権限がある' do |power|
      include_context 'set_member_power', power
      it_behaves_like 'ToSpace(html)', 'alert.space.not_destroy_reserved'
      it_behaves_like 'ToNG(json)', 406
    end
    shared_examples_for '[ログイン中][*][ある]権限がない' do |power|
      include_context 'set_member_power', power
      it_behaves_like 'ToNG(html)', 403
      it_behaves_like 'ToNG(json)', 406
    end
    shared_examples_for '[ログイン中][*][ない]権限がない' do |power|
      include_context 'set_member_power', power
      it_behaves_like 'ToSpace(html)', 'alert.space.not_destroy_reserved'
      it_behaves_like 'ToNG(json)', 406
    end
    shared_examples_for '[ログイン中][*][ない]権限がない（なし）' do
      it_behaves_like 'ToNG(html)', 403
      it_behaves_like 'ToNG(json)', 406
    end

    shared_examples_for '[ログイン中][*]削除予約がある' do |private|
      let_it_be(:space) { FactoryBot.create(:space, :destroy_reserved, private: private) }
      it_behaves_like '[ログイン中][*][ある]権限がある', :admin
      it_behaves_like '[ログイン中][*][ある]権限がない', :writer
      it_behaves_like '[ログイン中][*][ある]権限がない', :reader
      it_behaves_like '[ログイン中][*][ある]権限がない', nil
    end
    shared_examples_for '[ログイン中][公開]削除予約がない' do |private|
      let_it_be(:space) { FactoryBot.create(:space, private: private) }
      it_behaves_like '[ログイン中][*][ない]権限がある', :admin
      it_behaves_like '[ログイン中][*][ない]権限がない', :writer
      it_behaves_like '[ログイン中][*][ない]権限がない', :reader
      it_behaves_like '[ログイン中][*][ない]権限がない', nil
    end
    shared_examples_for '[ログイン中][非公開]削除予約がない' do |private|
      let_it_be(:space) { FactoryBot.create(:space, private: private) }
      it_behaves_like '[ログイン中][*][ない]権限がある', :admin
      it_behaves_like '[ログイン中][*][ない]権限がない', :writer
      it_behaves_like '[ログイン中][*][ない]権限がない', :reader
      it_behaves_like '[ログイン中][*][ない]権限がない（なし）', nil
    end

    shared_examples_for '[ログイン中]スペースが存在しない' do
      let_it_be(:space) { FactoryBot.build_stubbed(:space) }
      it_behaves_like 'ToNG(html)', 404
      it_behaves_like 'ToNG(json)', 406
    end
    shared_examples_for '[ログイン中]スペースが公開' do
      it_behaves_like '[ログイン中][*]削除予約がある', false
      it_behaves_like '[ログイン中][公開]削除予約がない', false
    end
    shared_examples_for '[ログイン中]スペースが非公開' do
      it_behaves_like '[ログイン中][*]削除予約がある', true
      it_behaves_like '[ログイン中][非公開]削除予約がない', true
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
      it_behaves_like '[ログイン中]スペースが非公開'
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
