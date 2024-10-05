require 'rails_helper'

RSpec.describe 'Invitations', type: :request do
  let(:response_json) { JSON.parse(response.body) }
  let(:response_json_invitation) { response_json['invitation'] }

  # POST /invitations/:space_code/update/:code 招待URL設定変更API(処理)
  # POST /invitations/:space_code/update/:code(.json) 招待URL設定変更API(処理)
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）, APIログイン中, APIログイン中（削除予約済み）
  #   スペース: 存在しない, 公開, 非公開
  #   権限: ある（管理者）, ない（投稿者, 閲覧者, なし）
  #   招待コード: 存在する（有効, 期限切れ, 削除済み）, 参加済み, 存在しない
  #   パラメータなし, 有効なパラメータ, 無効なパラメータ
  #     削除: ない, ある
  #     削除取り消し: ない, ある
  #   ＋URLの拡張子: ない, .json
  #   ＋Acceptヘッダ: HTMLが含まれる, JSONが含まれる
  describe 'POST #update' do
    subject { post update_invitation_path(space_code: space.code, code: invitation.code, format: subject_format), params:, headers: }
    let(:headers) { auth_headers.merge(accept_headers) }

    let_it_be(:valid_attributes)   { { memo: 'メモ', ended_date: '9999-12-31', ended_time: '23:59', ended_zone: '+09:00' } }
    let_it_be(:invalid_attributes) { valid_attributes.merge(ended_time: nil) }
    let_it_be(:created_user) { FactoryBot.create(:user) }

    shared_context 'valid_condition' do
      let_it_be(:space) { FactoryBot.create(:space, :public, created_user:) }
      before_all { FactoryBot.create(:member, space:, user:) if user.present? }
      let_it_be(:invitation) { FactoryBot.create(:invitation, :active, space:, created_user:) }
      let(:params) { { invitation: valid_attributes } }
    end

    # テスト内容
    let(:current_invitation) { Invitation.find(invitation.id) }
    shared_examples_for 'OK' do
      let!(:start_time) { Time.current.floor }
      let(:schedule_days) { Settings.invitation_destroy_schedule_days.days }
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
        expect(response_json['success']).to be(true)
        expect(response_json['notice']).to eq(get_locale('notice.invitation.update'))

        count = expect_invitation_json(response_json_invitation, current_invitation)
        ## 招待削除の猶予期間
        expect(response_json_invitation['destroy_schedule_days']).to eq(Settings.invitation_destroy_schedule_days)
        expect(response_json_invitation.count).to eq(count + 1)

        expect(response_json.count).to eq(3)
      end
    end

    # テストケース
    shared_examples_for '[ログイン中][*][ある][存在する]パラメータなし' do
      let(:params) { nil }
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToOK(html)' # NOTE: 必須項目がない為、変更なしで成功する
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中][*][ある][存在する]パラメータなし' do
      let(:params) { nil }
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToOK(html)' # NOTE: 必須項目がない為、変更なしで成功する
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToOK(json)' # NOTE: 必須項目がない為、変更なしで成功する
    end
    shared_examples_for '[ログイン中][*][ある][存在する]有効なパラメータ' do |add_attributes|
      let(:params) { { invitation: attributes } }
      let(:attributes) { valid_attributes.merge(add_attributes) }
      if Settings.api_only_mode
        it_behaves_like 'NG(html)'
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'OK(html)'
        it_behaves_like 'ToOK(html)'
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中][*][ある][存在する]有効なパラメータ' do |add_attributes|
      let(:params) { { invitation: attributes } }
      let(:attributes) { valid_attributes.merge(add_attributes) }
      if Settings.api_only_mode
        it_behaves_like 'NG(html)'
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'OK(html)'
        it_behaves_like 'ToOK(html)' # NOTE: HTMLもログイン状態になる
      end
      it_behaves_like 'OK(json)'
      it_behaves_like 'ToOK(json)'
    end
    shared_examples_for '[ログイン中][*][ある][存在する]無効なパラメータ' do
      let(:params) { { invitation: invalid_attributes } }
      message = get_locale('activerecord.errors.models.invitation.attributes.ended_time.blank')
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToNG(html)', 422, [message]
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中][*][ある][存在する]無効なパラメータ' do
      let(:params) { { invitation: invalid_attributes } }
      message = get_locale('activerecord.errors.models.invitation.attributes.ended_time.blank')
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToNG(html)', 422, [message] # NOTE: HTMLもログイン状態になる
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 422, { ended_time: [message] }
    end

    shared_examples_for '[ログイン中][*][ある]招待コードが存在する' do |status|
      let_it_be(:invitation) { FactoryBot.create(:invitation, status, space:, created_user:) }
      it_behaves_like '[ログイン中][*][ある][存在する]パラメータなし'
      it_behaves_like '[ログイン中][*][ある][存在する]有効なパラメータ', {}
      it_behaves_like '[ログイン中][*][ある][存在する]有効なパラメータ', { delete: true } # TODO: APIとまとめる
      it_behaves_like '[ログイン中][*][ある][存在する]有効なパラメータ', { undo_delete: true }
      it_behaves_like '[ログイン中][*][ある][存在する]有効なパラメータ', { delete: true, undo_delete: true }
      it_behaves_like '[ログイン中][*][ある][存在する]無効なパラメータ'
    end
    shared_examples_for '[APIログイン中][*][ある]招待コードが存在する' do |status|
      let_it_be(:invitation) { FactoryBot.create(:invitation, status, space:, created_user:) }
      it_behaves_like '[APIログイン中][*][ある][存在する]パラメータなし'
      it_behaves_like '[APIログイン中][*][ある][存在する]有効なパラメータ', {}
      it_behaves_like '[APIログイン中][*][ある][存在する]有効なパラメータ', { delete: true }
      it_behaves_like '[APIログイン中][*][ある][存在する]有効なパラメータ', { undo_delete: true }
      it_behaves_like '[APIログイン中][*][ある][存在する]有効なパラメータ', { delete: true, undo_delete: true }
      it_behaves_like '[APIログイン中][*][ある][存在する]無効なパラメータ'
    end
    shared_examples_for '[ログイン中][*][ある]招待コードが参加済み' do
      let_it_be(:invitation) { FactoryBot.create(:invitation, :email_joined, space:, created_user:) }
      let(:params) { { invitation: valid_attributes } }
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToInvitations(html)', 'alert.invitation.email_joined'
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中][*][ある]招待コードが参加済み' do
      let_it_be(:invitation) { FactoryBot.create(:invitation, :email_joined, space:, created_user:) }
      let(:params) { { invitation: valid_attributes } }
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToInvitations(html)', 'alert.invitation.email_joined' # NOTE: HTMLもログイン状態になる
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 422, nil, 'alert.invitation.email_joined'
    end
    shared_examples_for '[ログイン中][*][ある]招待コードが存在しない' do
      let_it_be(:invitation) { FactoryBot.build_stubbed(:invitation) }
      let(:params) { { invitation: valid_attributes } }
      # it_behaves_like 'NG(html)' # NOTE: 存在しない為
      it_behaves_like 'ToNG(html)', Settings.api_only_mode ? 406 : 404
      # it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中][*][ある]招待コードが存在しない' do
      let_it_be(:invitation) { FactoryBot.build_stubbed(:invitation) }
      let(:params) { { invitation: valid_attributes } }
      # it_behaves_like 'NG(html)' # NOTE: 存在しない為
      it_behaves_like 'ToNG(html)', Settings.api_only_mode ? 406 : 404 # NOTE: HTMLもログイン状態になる
      # it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 404
    end

    shared_examples_for '[ログイン中][*]権限がある' do |power|
      before_all { FactoryBot.create(:member, power, space:, user:) }
      it_behaves_like '[ログイン中][*][ある]招待コードが存在する', :active
      it_behaves_like '[ログイン中][*][ある]招待コードが存在する', :expired
      it_behaves_like '[ログイン中][*][ある]招待コードが存在する', :deleted
      it_behaves_like '[ログイン中][*][ある]招待コードが参加済み'
      it_behaves_like '[ログイン中][*][ある]招待コードが存在しない'
    end
    shared_examples_for '[APIログイン中][*]権限がある' do |power|
      before_all { FactoryBot.create(:member, power, space:, user:) }
      it_behaves_like '[APIログイン中][*][ある]招待コードが存在する', :active
      it_behaves_like '[APIログイン中][*][ある]招待コードが存在する', :expired
      it_behaves_like '[APIログイン中][*][ある]招待コードが存在する', :deleted
      it_behaves_like '[APIログイン中][*][ある]招待コードが参加済み'
      it_behaves_like '[APIログイン中][*][ある]招待コードが存在しない'
    end
    shared_examples_for '[ログイン中][*]権限がない' do |power|
      before_all { FactoryBot.create(:member, power, space:, user:) if power.present? }
      let_it_be(:invitation) { FactoryBot.create(:invitation, :active, space:, created_user:) }
      let(:params) { { invitation: valid_attributes } }
      it_behaves_like 'NG(html)'
      it_behaves_like 'ToNG(html)', Settings.api_only_mode ? 406 : 403
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中][*]権限がない' do |power|
      before_all { FactoryBot.create(:member, power, space:, user:) if power.present? }
      let_it_be(:invitation) { FactoryBot.create(:invitation, :active, space:, created_user:) }
      let(:params) { { invitation: valid_attributes } }
      it_behaves_like 'NG(html)'
      it_behaves_like 'ToNG(html)', Settings.api_only_mode ? 406 : 403 # NOTE: HTMLもログイン状態になる
      it_behaves_like 'NG(json)'
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
      let_it_be(:space) { FactoryBot.build_stubbed(:space) }
      let_it_be(:invitation) { FactoryBot.build_stubbed(:invitation, :active) }
      let(:params) { { invitation: valid_attributes } }
      # it_behaves_like 'NG(html)' # NOTE: 存在しない為
      it_behaves_like 'ToNG(html)', Settings.api_only_mode ? 406 : 404
      # it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中]スペースが存在しない' do
      let_it_be(:space) { FactoryBot.build_stubbed(:space) }
      let_it_be(:invitation) { FactoryBot.build_stubbed(:invitation, :active) }
      let(:params) { { invitation: valid_attributes } }
      # it_behaves_like 'NG(html)' # NOTE: 存在しない為
      it_behaves_like 'ToNG(html)', Settings.api_only_mode ? 406 : 404 # NOTE: HTMLもログイン状態になる
      # it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 404
    end
    shared_examples_for '[ログイン中]スペースが公開' do
      let_it_be(:space) { FactoryBot.create(:space, :public, created_user:) }
      it_behaves_like '[ログイン中][*]'
    end
    shared_examples_for '[APIログイン中]スペースが公開' do
      let_it_be(:space) { FactoryBot.create(:space, :public, created_user:) }
      it_behaves_like '[APIログイン中][*]'
    end
    shared_examples_for '[ログイン中]スペースが非公開' do
      let_it_be(:space) { FactoryBot.create(:space, :private, created_user:) }
      it_behaves_like '[ログイン中][*]'
    end
    shared_examples_for '[APIログイン中]スペースが非公開' do
      let_it_be(:space) { FactoryBot.create(:space, :private, created_user:) }
      it_behaves_like '[APIログイン中][*]'
    end

    context '未ログイン' do
      include_context '未ログイン処理'
      include_context 'valid_condition'
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToLogin(html)'
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 401
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
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToInvitations(html)', 'alert.user.destroy_reserved'
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    context 'APIログイン中' do
      include_context 'APIログイン処理'
      it_behaves_like '[APIログイン中]スペースが存在しない'
      it_behaves_like '[APIログイン中]スペースが公開'
      it_behaves_like '[APIログイン中]スペースが非公開'
    end
    context 'APIログイン中（削除予約済み）' do
      include_context 'APIログイン処理', :destroy_reserved
      include_context 'valid_condition'
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToInvitations(html)', 'alert.user.destroy_reserved' # NOTE: HTMLもログイン状態になる
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 422, nil, 'alert.user.destroy_reserved'
    end
  end
end
