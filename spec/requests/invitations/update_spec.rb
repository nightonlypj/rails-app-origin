require 'rails_helper'

RSpec.describe 'Invitations', type: :request do
  let(:response_json) { JSON.parse(response.body) }

  # POST /invitations/:space_code/update/:code 招待URL設定変更API(処理)
  # POST /invitations/:space_code/update/:code(.json) 招待URL設定変更API(処理)
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）, APIログイン中, APIログイン中（削除予約済み）
  #   スペース: 存在しない, 公開, 公開（削除予約済み）, 非公開, 非公開（削除予約済み）
  #   権限: ある（管理者）, ない（投稿者, 閲覧者, なし）
  #   招待コード: 存在する（有効, 期限切れ, 削除済み）, 参加済み, 存在しない
  #   パラメータなし, 有効なパラメータ（削除: なし, あり, 削除取り消し: なし, あり）, 無効なパラメータ
  #   ＋URLの拡張子: ない, .json
  #   ＋Acceptヘッダ: HTMLが含まれる, JSONが含まれる
  describe 'POST #update' do
    subject { post update_invitation_path(space_code: space.code, code: invitation.code, format: subject_format), params: { invitation: attributes }, headers: auth_headers.merge(accept_headers) }
    let_it_be(:valid_attributes)   { { memo: 'メモ', ended_date: '9999-12-31', ended_time: '23:59', ended_zone: '+09:00' } }
    let_it_be(:invalid_attributes) { valid_attributes.merge(ended_time: nil) }
    let(:current_invitation) { Invitation.last }

    let_it_be(:space_not)             { FactoryBot.build_stubbed(:space) }
    let_it_be(:space_public)          { FactoryBot.create(:space, :public) }
    let_it_be(:space_public_destroy)  { FactoryBot.create(:space, :public, :destroy_reserved) }
    let_it_be(:space_private)         { FactoryBot.create(:space, :private) }
    let_it_be(:space_private_destroy) { FactoryBot.create(:space, :private, :destroy_reserved) }
    shared_context 'valid_condition' do
      let(:attributes) { valid_attributes }
      let_it_be(:space) { space_public }
      include_context 'set_member_power', :admin
      let_it_be(:invitation) { FactoryBot.create(:invitation, :active) }
    end

    # テスト内容
    shared_examples_for 'OK' do
      let!(:start_time) { Time.current.floor }
      let(:schedule_days) { Settings['invitation_destroy_schedule_days'].days }
      it '対象項目が変更される' do
        subject
        expect(current_invitation.memo).to eq(attributes[:memo])
        expect(current_invitation.last_updated_user).to eq(user)
        expect(current_invitation.ended_at).to eq(Time.new(9999, 12, 31, 23, 59, 59, '+09:00'))

        if invitation.destroy_schedule_at.blank? && attributes[:delete].present? && attributes[:undo_delete].blank?
          expect(current_invitation.destroy_requested_at).to be_between(start_time, Time.current)
          expect(current_invitation.destroy_schedule_at).to be_between(start_time + schedule_days, Time.current + schedule_days)
        elsif invitation.destroy_schedule_at.present? && attributes[:undo_delete].present?
          expect(current_invitation.destroy_requested_at).to be_nil
          expect(current_invitation.destroy_schedule_at).to be_nil
        else
          expect(current_invitation.destroy_requested_at).to eq(invitation.destroy_requested_at)
          expect(current_invitation.destroy_schedule_at).to eq(invitation.destroy_schedule_at)
        end
      end
    end
    shared_examples_for 'NG' do
      it '変更されない' do
        subject
        expect(current_invitation).to eq(invitation)
      end
    end

    shared_examples_for 'ToOK(html/*)' do
      it_behaves_like 'ToInvitations(html)', nil, 'notice.invitation.update'
    end
    shared_examples_for 'ToOK(json/json)' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it 'HTTPステータスが200。対象項目が一致する' do
        is_expected.to eq(200)
        expect(response_json['success']).to eq(true)
        expect(response_json['alert']).to be_nil
        expect(response_json['notice']).to eq(get_locale('notice.invitation.update'))
        expect_invitation_json(response_json['invitation'], current_invitation)
      end
    end

    # テストケース
    shared_examples_for '[ログイン中][*][ある][存在する]パラメータなし' do
      let(:attributes) { nil }
      it_behaves_like 'NG(html)'
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToOK(html)' # NOTE: 必須項目がない為、変更なしで成功する
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中][*][ある][存在する]パラメータなし' do
      let(:attributes) { nil }
      it_behaves_like 'NG(html)'
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToOK(html)' # NOTE: 必須項目がない為、変更なしで成功する
      it_behaves_like 'ToOK(json)' # NOTE: 必須項目がない為、変更なしで成功する
    end
    shared_examples_for '[ログイン中][*][ある][存在する]有効なパラメータ' do |add_attributes|
      let(:attributes) { valid_attributes.merge(add_attributes) }
      it_behaves_like 'OK(html)'
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToOK(html)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中][*][ある][存在する]有効なパラメータ' do |add_attributes|
      let(:attributes) { valid_attributes.merge(add_attributes) }
      it_behaves_like 'OK(html)'
      it_behaves_like 'OK(json)'
      it_behaves_like 'ToOK(html)' # NOTE: HTMLもログイン状態になる
      it_behaves_like 'ToOK(json)'
    end
    shared_examples_for '[ログイン中][*][ある][存在する]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      message = get_locale('activerecord.errors.models.invitation.attributes.ended_time.blank')
      it_behaves_like 'NG(html)'
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(html)', 422, [message]
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中][*][ある][存在する]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      message = get_locale('activerecord.errors.models.invitation.attributes.ended_time.blank')
      it_behaves_like 'NG(html)'
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(html)', 422, [message] # NOTE: HTMLもログイン状態になる
      it_behaves_like 'ToNG(json)', 422, { ended_time: [message] }
    end

    shared_examples_for '[ログイン中][*][ある]招待コードが存在する' do |status|
      let_it_be(:invitation) { FactoryBot.create(:invitation, status, space: space) }
      it_behaves_like '[ログイン中][*][ある][存在する]パラメータなし'
      it_behaves_like '[ログイン中][*][ある][存在する]有効なパラメータ', {}
      it_behaves_like '[ログイン中][*][ある][存在する]有効なパラメータ', { delete: '1' }
      it_behaves_like '[ログイン中][*][ある][存在する]有効なパラメータ', { undo_delete: '1' }
      it_behaves_like '[ログイン中][*][ある][存在する]有効なパラメータ', { delete: '1', undo_delete: '1' }
      it_behaves_like '[ログイン中][*][ある][存在する]無効なパラメータ'
    end
    shared_examples_for '[APIログイン中][*][ある]招待コードが存在する' do |status|
      let_it_be(:invitation) { FactoryBot.create(:invitation, status, space: space) }
      it_behaves_like '[APIログイン中][*][ある][存在する]パラメータなし'
      it_behaves_like '[APIログイン中][*][ある][存在する]有効なパラメータ', {}
      it_behaves_like '[APIログイン中][*][ある][存在する]有効なパラメータ', { delete: true }
      it_behaves_like '[APIログイン中][*][ある][存在する]有効なパラメータ', { undo_delete: true }
      it_behaves_like '[APIログイン中][*][ある][存在する]有効なパラメータ', { delete: true, undo_delete: true }
      it_behaves_like '[APIログイン中][*][ある][存在する]無効なパラメータ'
    end
    shared_examples_for '[ログイン中][*][ある]招待コードが参加済み' do
      let_it_be(:invitation) { FactoryBot.create(:invitation, :email_joined, space: space) }
      let(:attributes) { valid_attributes }
      it_behaves_like 'ToInvitations(html)', 'alert.invitation.email_joined'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中][*][ある]招待コードが参加済み' do
      let_it_be(:invitation) { FactoryBot.create(:invitation, :email_joined, space: space) }
      let(:attributes) { valid_attributes }
      it_behaves_like 'ToInvitations(html)', 'alert.invitation.email_joined' # NOTE: HTMLもログイン状態になる
      it_behaves_like 'ToNG(json)', 422, nil, 'alert.invitation.email_joined'
    end
    shared_examples_for '[ログイン中][*][ある]招待コードが存在しない' do
      let_it_be(:invitation) { FactoryBot.build_stubbed(:invitation) }
      let(:attributes) { valid_attributes }
      it_behaves_like 'ToNG(html)', 404
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中][*][ある]招待コードが存在しない' do
      let_it_be(:invitation) { FactoryBot.build_stubbed(:invitation) }
      let(:attributes) { valid_attributes }
      it_behaves_like 'ToNG(html)', 404 # NOTE: HTMLもログイン状態になる
      it_behaves_like 'ToNG(json)', 404
    end

    shared_examples_for '[ログイン中][*]権限がある' do |power|
      include_context 'set_member_power', power
      it_behaves_like '[ログイン中][*][ある]招待コードが存在する', :active
      it_behaves_like '[ログイン中][*][ある]招待コードが存在する', :expired
      it_behaves_like '[ログイン中][*][ある]招待コードが存在する', :deleted
      it_behaves_like '[ログイン中][*][ある]招待コードが参加済み'
      it_behaves_like '[ログイン中][*][ある]招待コードが存在しない'
    end
    shared_examples_for '[APIログイン中][*]権限がある' do |power|
      include_context 'set_member_power', power
      it_behaves_like '[APIログイン中][*][ある]招待コードが存在する', :active
      it_behaves_like '[APIログイン中][*][ある]招待コードが存在する', :expired
      it_behaves_like '[APIログイン中][*][ある]招待コードが存在する', :deleted
      it_behaves_like '[APIログイン中][*][ある]招待コードが参加済み'
      it_behaves_like '[APIログイン中][*][ある]招待コードが存在しない'
    end
    shared_examples_for '[ログイン中][*]権限がない' do |power|
      include_context 'set_member_power', power
      let_it_be(:invitation) { FactoryBot.create(:invitation, :active) }
      let(:attributes) { valid_attributes }
      it_behaves_like 'NG(html)'
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(html)', 403
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中][*]権限がない' do |power|
      include_context 'set_member_power', power
      let_it_be(:invitation) { FactoryBot.create(:invitation, :active) }
      let(:attributes) { valid_attributes }
      it_behaves_like 'NG(html)'
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(html)', 403 # NOTE: HTMLもログイン状態になる
      it_behaves_like 'ToNG(json)', 403
    end

    shared_examples_for '[ログイン中][*]' do
      it_behaves_like '[ログイン中][*]権限がある', :admin
      it_behaves_like '[ログイン中][*]権限がない', :writer
      it_behaves_like '[ログイン中][*]権限がない', :reader
      it_behaves_like '[ログイン中][*]権限がない', nil
    end
    shared_examples_for '[APIログイン中][*]' do
      it_behaves_like '[APIログイン中][*]権限がある', :admin
      it_behaves_like '[APIログイン中][*]権限がない', :writer
      it_behaves_like '[APIログイン中][*]権限がない', :reader
      it_behaves_like '[APIログイン中][*]権限がない', nil
    end

    shared_examples_for '[ログイン中]スペースが存在しない' do
      let_it_be(:space) { space_not }
      let_it_be(:invitation) { FactoryBot.create(:invitation, :active) }
      let(:attributes) { valid_attributes }
      # it_behaves_like 'NG(html)' # NOTE: 存在しない為
      # it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(html)', 404
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中]スペースが存在しない' do
      let_it_be(:space) { space_not }
      let_it_be(:invitation) { FactoryBot.create(:invitation, :active) }
      let(:attributes) { valid_attributes }
      # it_behaves_like 'NG(html)' # NOTE: 存在しない為
      # it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(html)', 404 # NOTE: HTMLもログイン状態になる
      it_behaves_like 'ToNG(json)', 404
    end
    shared_examples_for '[ログイン中]スペースが公開' do
      let_it_be(:space) { space_public }
      it_behaves_like '[ログイン中][*]'
    end
    shared_examples_for '[APIログイン中]スペースが公開' do
      let_it_be(:space) { space_public }
      it_behaves_like '[APIログイン中][*]'
    end
    shared_examples_for '[ログイン中]スペースが公開（削除予約済み）' do
      let_it_be(:space) { space_public_destroy }
      it_behaves_like '[ログイン中][*]'
    end
    shared_examples_for '[APIログイン中]スペースが公開（削除予約済み）' do
      let_it_be(:space) { space_public_destroy }
      it_behaves_like '[APIログイン中][*]'
    end
    shared_examples_for '[ログイン中]スペースが非公開' do
      let_it_be(:space) { space_private }
      it_behaves_like '[ログイン中][*]'
    end
    shared_examples_for '[APIログイン中]スペースが非公開' do
      let_it_be(:space) { space_private }
      it_behaves_like '[APIログイン中][*]'
    end
    shared_examples_for '[ログイン中]スペースが非公開（削除予約済み）' do
      let_it_be(:space) { space_private_destroy }
      it_behaves_like '[ログイン中][*]'
    end
    shared_examples_for '[APIログイン中]スペースが非公開（削除予約済み）' do
      let_it_be(:space) { space_private_destroy }
      it_behaves_like '[APIログイン中][*]'
    end

    context '未ログイン' do
      include_context '未ログイン処理'
      include_context 'valid_condition'
      it_behaves_like 'NG(html)'
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToLogin(html)'
      it_behaves_like 'ToNG(json)', 401
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
      it_behaves_like 'NG(html)'
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToInvitations(html)', 'alert.user.destroy_reserved'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    context 'APIログイン中' do
      include_context 'APIログイン処理'
      it_behaves_like '[APIログイン中]スペースが存在しない'
      it_behaves_like '[APIログイン中]スペースが公開'
      it_behaves_like '[APIログイン中]スペースが公開（削除予約済み）'
      it_behaves_like '[APIログイン中]スペースが非公開'
      it_behaves_like '[APIログイン中]スペースが非公開（削除予約済み）'
    end
    context 'APIログイン中（削除予約済み）' do
      include_context 'APIログイン処理', :destroy_reserved
      include_context 'valid_condition'
      it_behaves_like 'NG(html)'
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToInvitations(html)', 'alert.user.destroy_reserved' # NOTE: HTMLもログイン状態になる
      it_behaves_like 'ToNG(json)', 422, nil, 'alert.user.destroy_reserved'
    end
  end
end
