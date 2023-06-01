require 'rails_helper'

RSpec.describe 'Members', type: :request do
  let(:response_json) { JSON.parse(response.body) }

  # POST /members/:space_code/delete メンバー削除(処理)
  # POST /members/:space_code/delete(.json) メンバー削除API(処理)
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）, APIログイン中, APIログイン中（削除予約済み）
  #   スペース: 存在しない, 公開, 非公開
  #   権限: ある（管理者）, ない（投稿者, 閲覧者, なし）
  #   パラメータなし, 有効なパラメータ（他人のコードのみ, 自分のコードも含む, 存在しないコードも含む）, 無効なパラメータ（コードなし, 自分のコードのみ, 存在しないコードのみ）
  #   ＋URLの拡張子: ない, .json
  #   ＋Acceptヘッダ: HTMLが含まれる, JSONが含まれる
  describe 'POST #destroy' do
    subject { post destroy_member_path(space_code: space.code, format: subject_format), params: params, headers: auth_headers.merge(accept_headers) }

    let_it_be(:space_not)     { FactoryBot.build_stubbed(:space) }
    let_it_be(:space_public)  { FactoryBot.create(:space, :public) }
    let_it_be(:space_private) { FactoryBot.create(:space, :private) }
    let_it_be(:member_nojoin) { FactoryBot.create(:member) }
    shared_context 'valid_condition' do |format_html|
      let_it_be(:space) { space_public }
      let_it_be(:member_destroy) { FactoryBot.create(:member, :admin, space: space) }
      include_context 'set_member_power', :admin
      include_context 'set_params1', format_html
    end
    shared_context 'set_params1' do |format_html|
      let(:notice_key)     { 'destroy' }
      let(:input_count)    { 1 }
      let(:destroy_count)  { 1 }
      let(:include_myself) { false }
      let(:params) do
        { codes: format_html ? { member_destroy.user.code => '1' } : [member_destroy.user.code] }
      end
    end
    shared_context 'set_params_include_myself' do |format_html|
      let(:notice_key)     { 'destroy_include_myself' }
      let(:input_count)    { 2 }
      let(:destroy_count)  { 1 }
      let(:include_myself) { true }
      let(:params) do
        { codes: format_html ? { member_myself.user.code => '1', member_destroy.user.code => '1' } : [member_myself.user.code, member_destroy.user.code] }
      end
    end
    shared_context 'set_params_include_notfound' do |format_html|
      let(:notice_key)     { 'destroy_include_notfound' }
      let(:input_count)    { 2 }
      let(:destroy_count)  { 1 }
      let(:include_myself) { false }
      let(:params) do
        { codes: format_html ? { member_nojoin.user.code => '1', member_destroy.user.code => '1' } : [member_nojoin.user.code, member_destroy.user.code] }
      end
    end
    shared_context 'set_params_myself' do |format_html|
      let(:params) do
        { codes: format_html ? { member_myself.user.code => '1' } : [member_myself.user.code] }
      end
    end
    shared_context 'set_params_notfound' do |format_html|
      let(:params) do
        { codes: format_html ? { member_nojoin.user.code => '1' } : [member_nojoin.user.code] }
      end
    end

    # テスト内容
    shared_examples_for 'OK' do
      it 'メンバーが削除される' do
        expect { subject }.to change(Member, :count).by(destroy_count * -1)
      end
    end
    shared_examples_for 'NG' do
      it 'メンバーが削除されない' do
        expect { subject }.to change(Member, :count).by(0)
      end
    end

    shared_examples_for 'ToOK(html/*)' do
      it 'メンバー一覧にリダイレクトする' do
        is_expected.to redirect_to(members_path(space.code))
        expect(flash[:alert]).to be_nil
        expect(flash[:notice]).to eq(get_locale("notice.member.#{notice_key}", count: input_count, destroy_count: destroy_count))
      end
    end
    shared_examples_for 'ToOK(json/json)' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it 'HTTPステータスが200。対象項目が一致する' do
        is_expected.to eq(200)
        expect(response_json['success']).to eq(true)
        expect(response_json['notice']).to eq(get_locale("notice.member.#{notice_key}", count: input_count, destroy_count: destroy_count))
        expect(response_json['count']).to eq(input_count)
        expect(response_json['destroy_count']).to eq(destroy_count)
        expect(response_json['include_myself']).to eq(include_myself)
        expect(response_json.count).to eq(5)
      end
    end

    # テストケース
    shared_examples_for '[ログイン中][*][ある]パラメータなし' do
      let(:params) { nil }
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToMembers(html)', 'alert.member.destroy.codes.blank'
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中][*][ある]パラメータなし' do
      let(:params) { nil }
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToMembers(html)', 'alert.member.destroy.codes.blank' # NOTE: HTMLもログイン状態になる
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 422, nil, 'alert.member.destroy.codes.blank'
    end
    shared_examples_for '[ログイン中][*][ある]有効なパラメータ（他人のコードのみ）' do
      include_context 'set_params1', true
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
    shared_examples_for '[APIログイン中][*][ある]有効なパラメータ（他人のコードのみ）' do
      include_context 'set_params1', false
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
    shared_examples_for '[ログイン中][*][ある]有効なパラメータ（自分のコードも含む）' do
      include_context 'set_params_include_myself', true
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
    shared_examples_for '[APIログイン中][*][ある]有効なパラメータ（自分のコードも含む）' do
      include_context 'set_params_include_myself', false
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
    shared_examples_for '[ログイン中][*][ある]有効なパラメータ（存在しないコードも含む）' do
      include_context 'set_params_include_notfound', true
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
    shared_examples_for '[APIログイン中][*][ある]有効なパラメータ（存在しないコードも含む）' do
      include_context 'set_params_include_notfound', false
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
    shared_examples_for '[ログイン中][*][ある]無効なパラメータ（コードなし）' do
      let(:params) { { codes: {} } }
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToMembers(html)', 'alert.member.destroy.codes.blank'
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中][*][ある]無効なパラメータ（コードなし）' do
      let(:params) { { codes: [] } }
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToMembers(html)', 'alert.member.destroy.codes.blank' # NOTE: HTMLもログイン状態になる
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 422, nil, 'alert.member.destroy.codes.blank'
    end
    shared_examples_for '[ログイン中][*][ある]無効なパラメータ（自分のコードのみ）' do
      include_context 'set_params_myself', true
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToMembers(html)', 'alert.member.destroy.codes.myself'
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中][*][ある]無効なパラメータ（自分のコードのみ）' do
      include_context 'set_params_myself', false
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToMembers(html)', 'alert.member.destroy.codes.myself' # NOTE: HTMLもログイン状態になる
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 422, nil, 'alert.member.destroy.codes.myself'
    end
    shared_examples_for '[ログイン中][*][ある]無効なパラメータ（存在しないコードのみ）' do
      include_context 'set_params_notfound', true
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToMembers(html)', 'alert.member.destroy.codes.notfound'
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中][*][ある]無効なパラメータ（存在しないコードのみ）' do
      include_context 'set_params_notfound', false
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToMembers(html)', 'alert.member.destroy.codes.notfound' # NOTE: HTMLもログイン状態になる
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 422, nil, 'alert.member.destroy.codes.notfound'
    end

    shared_examples_for '[ログイン中][*]権限がある' do |power|
      include_context 'set_member_power', power
      it_behaves_like '[ログイン中][*][ある]パラメータなし'
      it_behaves_like '[ログイン中][*][ある]有効なパラメータ（他人のコードのみ）'
      it_behaves_like '[ログイン中][*][ある]有効なパラメータ（自分のコードも含む）'
      it_behaves_like '[ログイン中][*][ある]有効なパラメータ（存在しないコードも含む）'
      it_behaves_like '[ログイン中][*][ある]無効なパラメータ（コードなし）'
      it_behaves_like '[ログイン中][*][ある]無効なパラメータ（自分のコードのみ）'
      it_behaves_like '[ログイン中][*][ある]無効なパラメータ（存在しないコードのみ）'
    end
    shared_examples_for '[APIログイン中][*]権限がある' do |power|
      include_context 'set_member_power', power
      it_behaves_like '[APIログイン中][*][ある]パラメータなし'
      it_behaves_like '[APIログイン中][*][ある]有効なパラメータ（他人のコードのみ）'
      it_behaves_like '[APIログイン中][*][ある]有効なパラメータ（自分のコードも含む）'
      it_behaves_like '[APIログイン中][*][ある]有効なパラメータ（存在しないコードも含む）'
      it_behaves_like '[APIログイン中][*][ある]無効なパラメータ（コードなし）'
      it_behaves_like '[APIログイン中][*][ある]無効なパラメータ（自分のコードのみ）'
      it_behaves_like '[APIログイン中][*][ある]無効なパラメータ（存在しないコードのみ）'
    end
    shared_examples_for '[ログイン中][*]権限がない' do |power|
      include_context 'set_member_power', power
      include_context 'set_params1', true
      it_behaves_like 'NG(html)'
      it_behaves_like 'ToNG(html)', Settings.api_only_mode ? 406 : 403
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中][*]権限がない' do |power|
      include_context 'set_member_power', power
      include_context 'set_params1', false
      it_behaves_like 'NG(html)'
      it_behaves_like 'ToNG(html)', Settings.api_only_mode ? 406 : 403 # NOTE: HTMLもログイン状態になる
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 403
    end

    shared_examples_for '[ログイン中]スペースが存在しない' do
      let_it_be(:space) { space_not }
      let(:params) { { codes: {} } }
      it_behaves_like 'NG(html)'
      it_behaves_like 'ToNG(html)', Settings.api_only_mode ? 406 : 404
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中]スペースが存在しない' do
      let_it_be(:space) { space_not }
      let(:params) { { codes: [] } }
      it_behaves_like 'NG(html)'
      it_behaves_like 'ToNG(html)', Settings.api_only_mode ? 406 : 404 # NOTE: HTMLもログイン状態になる
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 404
    end
    shared_examples_for '[ログイン中]スペースが公開' do
      let_it_be(:space) { space_public }
      let_it_be(:member_destroy) { FactoryBot.create(:member, :admin, space: space) }
      it_behaves_like '[ログイン中][*]権限がある', :admin
      it_behaves_like '[ログイン中][*]権限がない', :writer
      it_behaves_like '[ログイン中][*]権限がない', :reader
      it_behaves_like '[ログイン中][*]権限がない', nil
    end
    shared_examples_for '[APIログイン中]スペースが公開' do
      let_it_be(:space) { space_public }
      let_it_be(:member_destroy) { FactoryBot.create(:member, :admin, space: space) }
      it_behaves_like '[APIログイン中][*]権限がある', :admin
      it_behaves_like '[APIログイン中][*]権限がない', :writer
      it_behaves_like '[APIログイン中][*]権限がない', :reader
      it_behaves_like '[APIログイン中][*]権限がない', nil
    end
    shared_examples_for '[ログイン中]スペースが非公開' do
      let_it_be(:space) { space_private }
      let_it_be(:member_destroy) { FactoryBot.create(:member, :admin, space: space) }
      it_behaves_like '[ログイン中][*]権限がある', :admin
      it_behaves_like '[ログイン中][*]権限がない', :writer
      it_behaves_like '[ログイン中][*]権限がない', :reader
      it_behaves_like '[ログイン中][*]権限がない', nil
    end
    shared_examples_for '[APIログイン中]スペースが非公開' do
      let_it_be(:space) { space_private }
      let_it_be(:member_destroy) { FactoryBot.create(:member, :admin, space: space) }
      it_behaves_like '[APIログイン中][*]権限がある', :admin
      it_behaves_like '[APIログイン中][*]権限がない', :writer
      it_behaves_like '[APIログイン中][*]権限がない', :reader
      it_behaves_like '[APIログイン中][*]権限がない', nil
    end

    context '未ログイン' do
      include_context '未ログイン処理'
      include_context 'valid_condition', true
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
      include_context 'valid_condition', true
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToMembers(html)', 'alert.user.destroy_reserved'
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
      include_context 'valid_condition', false
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToMembers(html)', 'alert.user.destroy_reserved' # NOTE: HTMLもログイン状態になる
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 422, nil, 'alert.user.destroy_reserved'
    end
  end
end
