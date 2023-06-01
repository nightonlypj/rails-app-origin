require 'rails_helper'

RSpec.describe 'Invitations', type: :request do
  let(:response_json) { JSON.parse(response.body) }
  let(:response_json_invitation) { response_json['invitation'] }

  # POST /invitations/:space_code/create 招待URL作成(処理)
  # POST /invitations/:space_code/create(.json) 招待URL作成API(処理)
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）, APIログイン中, APIログイン中（削除予約済み）
  #   スペース: 存在しない, 公開, 非公開
  #   権限: ある（管理者）, ない（投稿者, 閲覧者, なし）
  #   パラメータなし, 有効なパラメータ（ドメイン: 1件, 最大数と同じ）, 無効なパラメータ（ドメイン: ない, 最大数より多い, 不正な形式が含まれる）
  #   ＋URLの拡張子: ない, .json
  #   ＋Acceptヘッダ: HTMLが含まれる, JSONが含まれる
  describe 'POST #create' do
    subject { post create_invitation_path(space_code: space.code, format: subject_format), params: params, headers: auth_headers.merge(accept_headers) }
    let_it_be(:valid_attributes)     { FactoryBot.attributes_for(:invitation, :create).reject { |key| key == :code } }
    let_it_be(:valid_attributes_max) { FactoryBot.attributes_for(:invitation, :create_max).reject { |key| key == :code } }
    let_it_be(:invalid_attributes)        { valid_attributes.merge(domains: nil) }
    let_it_be(:invalid_attributes_over)   { valid_attributes.merge(domains: "#{valid_attributes_max[:domains]}\n#{valid_attributes[:domains]}") }
    let_it_be(:invalid_attributes_format) { valid_attributes.merge(domains: "#{valid_attributes[:domains]}\naaa") }
    let(:current_invitation) { Invitation.last }

    let_it_be(:space_not)     { FactoryBot.build_stubbed(:space) }
    let_it_be(:space_public)  { FactoryBot.create(:space, :public) }
    let_it_be(:space_private) { FactoryBot.create(:space, :private) }
    shared_context 'valid_condition' do
      let(:params) { { invitation: valid_attributes } }
      let_it_be(:space) { space_public }
      include_context 'set_member_power', :admin
    end

    # テスト内容
    shared_examples_for 'OK' do
      it '招待が1件作成・対象項目が設定される' do
        expect do
          subject
          expect(current_invitation.space).to eq(space)
          expect(current_invitation.email).to be_nil
          expect(current_invitation.domains_array.join("\n")).to eq(attributes[:domains])
          expect(current_invitation.power.to_sym).to eq(attributes[:power])
          expect(current_invitation.memo).to eq(attributes[:memo])
          expect(current_invitation.ended_at).to be_nil
          expect(current_invitation.destroy_requested_at).to be_nil
          expect(current_invitation.destroy_schedule_at).to be_nil
          expect(current_invitation.email_joined_at).to be_nil
          expect(current_invitation.created_user_id).to be(user.id)
          expect(current_invitation.last_updated_user).to be_nil
        end.to change(Invitation, :count).by(1)
      end
    end
    shared_examples_for 'NG' do
      it '招待が作成されない' do
        expect { subject }.to change(Invitation, :count).by(0)
      end
    end

    shared_examples_for 'ToOK(html/*)' do
      it_behaves_like 'ToInvitations(html)', nil, 'notice.invitation.create'
    end
    shared_examples_for 'ToOK(json/json)' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      let(:invitation_count) { 1 }
      it 'HTTPステータスが201。対象項目が一致する' do
        is_expected.to eq(201)
        expect(response_json['success']).to eq(true)
        expect(response_json['notice']).to eq(get_locale('notice.invitation.create'))

        count = expect_invitation_json(response_json_invitation, current_invitation)
        ## 招待削除の猶予期間
        expect(response_json_invitation['destroy_schedule_days']).to eq(Settings.invitation_destroy_schedule_days)
        expect(response_json_invitation.count).to eq(count + 1)

        expect(response_json.count).to eq(3)
      end
    end

    # テストケース
    shared_examples_for '[ログイン中][*][ある]パラメータなし' do
      let(:params) { nil }
      msg_domains = get_locale('activerecord.errors.models.invitation.attributes.domains.blank')
      msg_power   = get_locale('activerecord.errors.models.invitation.attributes.power.blank')
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToNG(html)', 422, [msg_domains, msg_power]
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中][*][ある]パラメータなし' do
      let(:params) { nil }
      msg_domains = get_locale('activerecord.errors.models.invitation.attributes.domains.blank')
      msg_power   = get_locale('activerecord.errors.models.invitation.attributes.power.blank')
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToNG(html)', 422, [msg_domains, msg_power]
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 422, { domains: [msg_domains], power: [msg_power] }
    end
    shared_examples_for '[ログイン中][*][ある]有効なパラメータ（ドメインが1件）' do
      let(:params) { { invitation: attributes } }
      let(:attributes) { valid_attributes }
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
    shared_examples_for '[APIログイン中][*][ある]有効なパラメータ（ドメインが1件）' do
      let(:params) { { invitation: attributes } }
      let(:attributes) { valid_attributes }
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
    shared_examples_for '[ログイン中][*][ある]有効なパラメータ（ドメインが最大数と同じ）' do
      let(:params) { { invitation: attributes } }
      let(:attributes) { valid_attributes_max }
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
    shared_examples_for '[APIログイン中][*][ある]有効なパラメータ（ドメインが最大数と同じ）' do
      let(:params) { { invitation: attributes } }
      let(:attributes) { valid_attributes_max }
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
    shared_examples_for '[ログイン中][*][ある]無効なパラメータ（ドメインがない）' do
      let(:params) { { invitation: invalid_attributes } }
      message = get_locale('activerecord.errors.models.invitation.attributes.domains.blank')
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToNG(html)', 422, [message]
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中][*][ある]無効なパラメータ（ドメインがない）' do
      let(:params) { { invitation: invalid_attributes } }
      message = get_locale('activerecord.errors.models.invitation.attributes.domains.blank')
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToNG(html)', 422, [message] # NOTE: HTMLもログイン状態になる
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 422, { domains: [message] }
    end
    shared_examples_for '[ログイン中][*][ある]無効なパラメータ（ドメインが最大数より多い）' do
      let(:params) { { invitation: invalid_attributes_over } }
      message = get_locale('activerecord.errors.models.invitation.attributes.domains.max_count', count: Settings.invitation_domains_max_count)
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToNG(html)', 422, [message]
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中][*][ある]無効なパラメータ（ドメインが最大数より多い）' do
      let(:params) { { invitation: invalid_attributes_over } }
      message = get_locale('activerecord.errors.models.invitation.attributes.domains.max_count', count: Settings.invitation_domains_max_count)
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToNG(html)', 422, [message] # NOTE: HTMLもログイン状態になる
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 422, { domains: [message] }
    end
    shared_examples_for '[ログイン中][*][ある]無効なパラメータ（ドメインに不正な形式が含まれる）' do
      let(:params) { { invitation: invalid_attributes_format } }
      message = get_locale('activerecord.errors.models.invitation.attributes.domains.invalid', domain: 'aaa')
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToNG(html)', 422, [message]
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中][*][ある]無効なパラメータ（ドメインに不正な形式が含まれる）' do
      let(:params) { { invitation: invalid_attributes_format } }
      message = get_locale('activerecord.errors.models.invitation.attributes.domains.invalid', domain: 'aaa')
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToNG(html)', 422, [message] # NOTE: HTMLもログイン状態になる
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 422, { domains: [message] }
    end

    shared_examples_for '[ログイン中][*]権限がある' do |power|
      include_context 'set_member_power', power
      it_behaves_like '[ログイン中][*][ある]パラメータなし'
      it_behaves_like '[ログイン中][*][ある]有効なパラメータ（ドメインが1件）'
      it_behaves_like '[ログイン中][*][ある]有効なパラメータ（ドメインが最大数と同じ）'
      it_behaves_like '[ログイン中][*][ある]無効なパラメータ（ドメインがない）'
      it_behaves_like '[ログイン中][*][ある]無効なパラメータ（ドメインが最大数より多い）'
      it_behaves_like '[ログイン中][*][ある]無効なパラメータ（ドメインに不正な形式が含まれる）'
    end
    shared_examples_for '[APIログイン中][*]権限がある' do |power|
      include_context 'set_member_power', power
      it_behaves_like '[APIログイン中][*][ある]パラメータなし'
      it_behaves_like '[APIログイン中][*][ある]有効なパラメータ（ドメインが1件）'
      it_behaves_like '[APIログイン中][*][ある]有効なパラメータ（ドメインが最大数と同じ）'
      it_behaves_like '[APIログイン中][*][ある]無効なパラメータ（ドメインがない）'
      it_behaves_like '[APIログイン中][*][ある]無効なパラメータ（ドメインが最大数より多い）'
      it_behaves_like '[APIログイン中][*][ある]無効なパラメータ（ドメインに不正な形式が含まれる）'
    end
    shared_examples_for '[ログイン中][*]権限がない' do |power|
      include_context 'set_member_power', power
      let(:params) { { invitation: valid_attributes } }
      it_behaves_like 'NG(html)'
      it_behaves_like 'ToNG(html)', Settings.api_only_mode ? 406 : 403
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中][*]権限がない' do |power|
      include_context 'set_member_power', power
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
      let_it_be(:space) { space_not }
      let(:params) { { invitation: valid_attributes } }
      it_behaves_like 'NG(html)'
      it_behaves_like 'ToNG(html)', Settings.api_only_mode ? 406 : 404
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中]スペースが存在しない' do
      let_it_be(:space) { space_not }
      let(:params) { { invitation: valid_attributes } }
      it_behaves_like 'NG(html)'
      it_behaves_like 'ToNG(html)', Settings.api_only_mode ? 406 : 404 # NOTE: HTMLもログイン状態になる
      it_behaves_like 'NG(json)'
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
    shared_examples_for '[ログイン中]スペースが非公開' do
      let_it_be(:space) { space_private }
      it_behaves_like '[ログイン中][*]'
    end
    shared_examples_for '[APIログイン中]スペースが非公開' do
      let_it_be(:space) { space_private }
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
