require 'rails_helper'

RSpec.describe 'Invitations', type: :request do
  let(:response_json) { response.body.present? ? JSON.parse(response.body) : {} }

  # GET /invitations/:space_code/update/:code 招待URL設定変更
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）, APIログイン中, APIログイン中（削除予約済み）
  #   スペース: 存在しない, 公開, 非公開
  #   権限: ある（管理者）, ない（投稿者, 閲覧者, なし）
  #   招待コード: 有効, 期限切れ, 削除済み, 参加済み, 存在しない
  #   ＋URLの拡張子: ない, .json
  #   ＋Acceptヘッダ: HTMLが含まれる, JSONが含まれる
  describe 'GET #edit' do
    subject { get edit_invitation_path(space_code: space.code, code: invitation.code, format: subject_format), headers: auth_headers.merge(accept_headers) }

    shared_context 'valid_condition' do
      let_it_be(:space)      { FactoryBot.create(:space) }
      let_it_be(:invitation) { FactoryBot.create(:invitation, :active, space: space) }
      include_context 'set_power', :admin
    end
    shared_context 'set_power' do |power|
      before_all { FactoryBot.create(:member, power, space: space, user: user) if power.present? && user.present? }
    end

    # テスト内容
    shared_examples_for 'ToOK(html/*)' do
      it_behaves_like 'ToOK[status]'
    end

    # テストケース
    shared_examples_for '[APIログイン中/削除予約済み][*][ある][存在]' do |status|
      let_it_be(:invitation) { FactoryBot.create(:invitation, status, space: space) }
      it_behaves_like 'ToOK(html)'
      it_behaves_like 'ToNG(json)', 406
    end

    shared_examples_for '[APIログイン中/削除予約済み][*][ある]招待コードが有効' do
      it_behaves_like '[APIログイン中/削除予約済み][*][ある][存在]', :active
    end
    shared_examples_for '[APIログイン中/削除予約済み][*][ある]招待コードが期限切れ' do
      it_behaves_like '[APIログイン中/削除予約済み][*][ある][存在]', :expired
    end
    shared_examples_for '[APIログイン中/削除予約済み][*][ある]招待コードが削除済み' do
      it_behaves_like '[APIログイン中/削除予約済み][*][ある][存在]', :deleted
    end
    shared_examples_for '[APIログイン中/削除予約済み][*][ある]招待コードが参加済み' do
      let_it_be(:invitation) { FactoryBot.create(:invitation, :email_joined, space: space) }
      it_behaves_like 'ToInvitations(html)', 'alert.invitation.email_joined'
      it_behaves_like 'ToNG(json)', 406
    end
    shared_examples_for '[APIログイン中/削除予約済み][*][ある]招待コードが存在しない' do
      let_it_be(:invitation) { FactoryBot.build_stubbed(:invitation) }
      it_behaves_like 'ToNG(html)', 404
      it_behaves_like 'ToNG(json)', 406
    end

    shared_examples_for '[ログイン中][*]権限がある' do |power|
      include_context 'set_power', power
      it_behaves_like '[APIログイン中/削除予約済み][*][ある]招待コードが有効'
      it_behaves_like '[APIログイン中/削除予約済み][*][ある]招待コードが期限切れ'
      it_behaves_like '[APIログイン中/削除予約済み][*][ある]招待コードが削除済み'
      it_behaves_like '[APIログイン中/削除予約済み][*][ある]招待コードが参加済み'
      it_behaves_like '[APIログイン中/削除予約済み][*][ある]招待コードが存在しない'
    end
    shared_examples_for '[ログイン中][*]権限がない' do |power|
      include_context 'set_power', power
      let_it_be(:invitation) { FactoryBot.create(:invitation, :active, space: space) }
      it_behaves_like 'ToNG(html)', 403
      it_behaves_like 'ToNG(json)', 406
    end

    shared_examples_for '[ログイン中]スペースが存在しない' do
      let_it_be(:space)      { FactoryBot.build_stubbed(:space) }
      let_it_be(:invitation) { FactoryBot.build_stubbed(:invitation) }
      it_behaves_like 'ToNG(html)', 404
      it_behaves_like 'ToNG(json)', 406
    end
    shared_examples_for '[ログイン中]スペースが公開' do
      let_it_be(:space) { FactoryBot.create(:space, :public) }
      it_behaves_like '[ログイン中][*]権限がある', :admin
      it_behaves_like '[ログイン中][*]権限がない', :writer
      it_behaves_like '[ログイン中][*]権限がない', :reader
      it_behaves_like '[ログイン中][*]権限がない', nil
    end
    shared_examples_for '[ログイン中]スペースが非公開' do
      let_it_be(:space) { FactoryBot.create(:space, :private) }
      it_behaves_like '[ログイン中][*]権限がある', :admin
      it_behaves_like '[ログイン中][*]権限がない', :writer
      it_behaves_like '[ログイン中][*]権限がない', :reader
      it_behaves_like '[ログイン中][*]権限がない', nil
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
      it_behaves_like 'ToInvitations(html)', 'alert.user.destroy_reserved'
      it_behaves_like 'ToNG(json)', 406
    end
    context 'APIログイン中' do
      include_context 'APIログイン処理'
      it_behaves_like '[ログイン中]スペースが存在しない' # NOTE: HTMLもログイン状態になる
      it_behaves_like '[ログイン中]スペースが公開'
      it_behaves_like '[ログイン中]スペースが非公開'
    end
    context 'APIログイン中（削除予約済み）' do
      include_context 'APIログイン処理', :destroy_reserved
      include_context 'valid_condition'
      it_behaves_like 'ToInvitations(html)', 'alert.user.destroy_reserved' # NOTE: HTMLもログイン状態になる
      it_behaves_like 'ToNG(json)', 406
    end
  end
end
