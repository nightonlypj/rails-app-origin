require 'rails_helper'

RSpec.describe 'Invitations', type: :request do
  let(:response_json) { JSON.parse(response.body) }

  # POST /invitations/:space_code/update/:code 招待URL設定変更API(処理)
  # POST /invitations/:space_code/update/:code(.json) 招待URL設定変更API(処理)
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）, APIログイン中, APIログイン中（削除予約済み）
  #   スペース: 存在しない, 公開, 非公開
  #   権限: ある（管理者）, ない（投稿者, 閲覧者, なし）
  #   招待コード: 存在する（有効, 期限切れ, 削除済み）, 参加済み, 存在しない
  #   パラメータなし, 有効なパラメータ, 無効なパラメータ
  #   ＋URLの拡張子: ない, .json
  #   ＋Acceptヘッダ: HTMLが含まれる, JSONが含まれる
  describe 'POST #update' do
    subject { post update_invitation_path(space_code: space.code, code: invitation.code, format: subject_format), params: { invitation: attributes }, headers: auth_headers.merge(accept_headers) }
    let_it_be(:valid_attributes)   { FactoryBot.attributes_for(:invitation) }
    let_it_be(:invalid_attributes) { valid_attributes.merge(ended_date: '9999-01-01', ended_time: nil) }
    let(:current_invitation) { Invitation.last }

    let_it_be(:space_not)     { FactoryBot.build_stubbed(:space) }
    let_it_be(:space_public)  { FactoryBot.create(:space, :public) }
    let_it_be(:space_private) { FactoryBot.create(:space, :private) }
    shared_context 'valid_condition' do
      let(:attributes) { valid_attributes }
      let_it_be(:space) { space_public }
      include_context 'set_member_power', :admin
      let_it_be(:invitation) { FactoryBot.create(:invitation, :active) }
    end

    # テスト内容
    shared_examples_for 'OK' do
      it '対象項目が変更される' do
        subject
        expect(current_invitation.power).to eq(attributes[:power].to_s)
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
    shared_examples_for '[ログイン中][*][ある][存在]パラメータなし' do
      let(:attributes) { nil }
      it_behaves_like 'NG(html)'
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToOK(html)' # NOTE: 必須項目がない為、変更なしで成功する
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中][*][ある][存在]パラメータなし' do
      let(:attributes) { nil }
      it_behaves_like 'NG(html)'
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToOK(html)' # NOTE: 必須項目がない為、変更なしで成功する
      it_behaves_like 'ToOK(json)' # NOTE: 必須項目がない為、変更なしで成功する
    end
    shared_examples_for '[ログイン中][*][ある][存在]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK(html)'
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToOK(html)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中][*][ある][存在]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK(html)'
      it_behaves_like 'OK(json)'
      it_behaves_like 'ToOK(html)' # NOTE: HTMLもログイン状態になる
      it_behaves_like 'ToOK(json)'
    end
    shared_examples_for '[ログイン中][*][ある][存在]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG(html)'
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(html)', 422, [get_locale('activerecord.errors.models.invitation.attributes.ended_time.blank')]
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中][*][ある][存在]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG(html)'
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(html)', 422, [get_locale('activerecord.errors.models.invitation.attributes.ended_time.blank')] # NOTE: HTMLもログイン状態になる
      it_behaves_like 'ToNG(json)', 422, { ended_time: [get_locale('activerecord.errors.models.invitation.attributes.ended_time.blank')] }
    end

    shared_examples_for '[ログイン中][*][ある]招待コードが存在する' do |status|
      let_it_be(:invitation) { FactoryBot.create(:invitation, status, space: space) }
      it_behaves_like '[ログイン中][*][ある][存在]パラメータなし'
      it_behaves_like '[ログイン中][*][ある][存在]有効なパラメータ'
      it_behaves_like '[ログイン中][*][ある][存在]無効なパラメータ'
    end
    shared_examples_for '[APIログイン中][*][ある]招待コードが存在する' do |status|
      let_it_be(:invitation) { FactoryBot.create(:invitation, status, space: space) }
      it_behaves_like '[APIログイン中][*][ある][存在]パラメータなし'
      it_behaves_like '[APIログイン中][*][ある][存在]有効なパラメータ'
      it_behaves_like '[APIログイン中][*][ある][存在]無効なパラメータ'
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
      it_behaves_like '[ログイン中][*]権限がある', :admin
      it_behaves_like '[ログイン中][*]権限がない', :writer
      it_behaves_like '[ログイン中][*]権限がない', :reader
      it_behaves_like '[ログイン中][*]権限がない', nil
    end
    shared_examples_for '[APIログイン中]スペースが公開' do
      let_it_be(:space) { space_public }
      it_behaves_like '[APIログイン中][*]権限がある', :admin
      it_behaves_like '[APIログイン中][*]権限がない', :writer
      it_behaves_like '[APIログイン中][*]権限がない', :reader
      it_behaves_like '[APIログイン中][*]権限がない', nil
    end
    shared_examples_for '[ログイン中]スペースが非公開' do
      let_it_be(:space) { space_private }
      it_behaves_like '[ログイン中][*]権限がある', :admin
      it_behaves_like '[ログイン中][*]権限がない', :writer
      it_behaves_like '[ログイン中][*]権限がない', :reader
      it_behaves_like '[ログイン中][*]権限がない', nil
    end
    shared_examples_for '[APIログイン中]スペースが非公開' do
      let_it_be(:space) { space_private }
      it_behaves_like '[APIログイン中][*]権限がある', :admin
      it_behaves_like '[APIログイン中][*]権限がない', :writer
      it_behaves_like '[APIログイン中][*]権限がない', :reader
      it_behaves_like '[APIログイン中][*]権限がない', nil
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
      it_behaves_like '[ログイン中]スペースが非公開'
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
      it_behaves_like '[APIログイン中]スペースが非公開'
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
