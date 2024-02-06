require 'rails_helper'

RSpec.describe 'Members', type: :request do
  let(:response_json) { JSON.parse(response.body) }
  let(:response_json_member) { response_json['member'] }

  # POST /members/:space_code/update/:user_code メンバー情報変更(処理)
  # POST /members/:space_code/update/:user_code(.json) メンバー情報変更API(処理)
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）, APIログイン中, APIログイン中（削除予約済み）
  #   スペース: 存在しない, 公開, 非公開
  #   権限: ある（管理者）, ない（投稿者, 閲覧者, なし）
  #   対象メンバー: いる（他人, 自分）, いない
  #   パラメータなし, 有効なパラメータ, 無効なパラメータ
  #   ＋URLの拡張子: ない, .json
  #   ＋Acceptヘッダ: HTMLが含まれる, JSONが含まれる
  describe 'POST #update' do
    subject { post update_member_path(space_code: space.code, user_code: show_user.code, format: subject_format), params:, headers: auth_headers.merge(accept_headers) }
    let_it_be(:valid_attributes)   { FactoryBot.attributes_for(:member) }
    let_it_be(:invalid_attributes) { valid_attributes.merge(power: nil) }
    let_it_be(:created_user) { FactoryBot.create(:user) }
    let_it_be(:other_user)   { FactoryBot.create(:user) }

    shared_context 'valid_condition' do
      let_it_be(:space) { FactoryBot.create(:space, :public, created_user:) }
      let_it_be(:member_myself) { FactoryBot.create(:member, space:, user:) if user.present? }
      let(:user_power) { :admin }
      let_it_be(:show_user) { other_user }
      let_it_be(:member) { FactoryBot.create(:member, space:, user: show_user) }
      let(:params) { { member: valid_attributes } }
    end

    # テスト内容
    let(:current_member) { Member.find(member.id) }
    shared_examples_for 'OK' do
      it '対象項目が変更される' do
        subject
        expect(current_member.power).to eq(attributes[:power].to_s)
      end
    end
    shared_examples_for 'NG' do
      it '変更されない' do
        subject
        expect(current_member).to eq(member)
      end
    end

    shared_examples_for 'ToOK(html/*)' do
      it 'メンバー一覧（対象コード付き）にリダイレクトする' do
        is_expected.to redirect_to(members_path(space_code: space.code, active: member.user.code))
        expect(flash[:alert]).to be_nil
        expect(flash[:notice]).to eq(get_locale('notice.member.update'))
      end
    end
    shared_examples_for 'ToOK(json/json)' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it 'HTTPステータスが200。対象項目が一致する' do
        is_expected.to eq(200)
        expect(response_json['success']).to eq(true)
        expect(response_json['notice']).to eq(get_locale('notice.member.update'))

        count = expect_member_json(response_json_member, current_member, user_power)
        expect(response_json_member.count).to eq(count)

        expect(response_json.count).to eq(3)
      end
    end

    # テストケース
    shared_examples_for '[ログイン中][*][ある][他人]パラメータなし' do
      let(:params) { nil }
      message = get_locale('activerecord.errors.models.member.attributes.power.blank')
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToNG(html)', 422, [message]
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中][*][ある][他人]パラメータなし' do
      let(:params) { nil }
      message = get_locale('activerecord.errors.models.member.attributes.power.blank')
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToNG(html)', 422, [message] # NOTE: HTMLもログイン状態になる
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 422, { power: [message] }
    end
    shared_examples_for '[ログイン中][*][ある][他人]有効なパラメータ' do
      let(:params) { { member: attributes } }
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
    shared_examples_for '[APIログイン中][*][ある][他人]有効なパラメータ' do
      let(:params) { { member: attributes } }
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
    shared_examples_for '[ログイン中][*][ある][他人]無効なパラメータ' do
      let(:params) { { member: invalid_attributes } }
      message = get_locale('activerecord.errors.models.member.attributes.power.blank')
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToNG(html)', 422, [message]
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中][*][ある][他人]無効なパラメータ' do
      let(:params) { { member: invalid_attributes } }
      message = get_locale('activerecord.errors.models.member.attributes.power.blank')
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToNG(html)', 422, [message] # NOTE: HTMLもログイン状態になる
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 422, { power: [message] }
    end

    shared_examples_for '[ログイン中][*][ある]対象メンバーがいる（他人）' do
      let_it_be(:show_user) { other_user }
      let_it_be(:member)    { FactoryBot.create(:member, space:, user: show_user) }
      it_behaves_like '[ログイン中][*][ある][他人]パラメータなし'
      it_behaves_like '[ログイン中][*][ある][他人]有効なパラメータ'
      it_behaves_like '[ログイン中][*][ある][他人]無効なパラメータ'
    end
    shared_examples_for '[APIログイン中][*][ある]対象メンバーがいる（他人）' do
      let_it_be(:show_user) { other_user }
      let_it_be(:member)    { FactoryBot.create(:member, space:, user: show_user) }
      it_behaves_like '[APIログイン中][*][ある][他人]パラメータなし'
      it_behaves_like '[APIログイン中][*][ある][他人]有効なパラメータ'
      it_behaves_like '[APIログイン中][*][ある][他人]無効なパラメータ'
    end
    shared_examples_for '[ログイン中][*][ある]対象メンバーがいる（自分）' do
      let_it_be(:show_user) { user }
      let_it_be(:member)    { member_myself }
      let(:params) { { member: valid_attributes } }
      it_behaves_like 'NG(html)'
      it_behaves_like 'ToNG(html)', Settings.api_only_mode ? 406 : 403
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中][*][ある]対象メンバーがいる（自分）' do
      let_it_be(:show_user) { user }
      let_it_be(:member)    { member_myself }
      let(:params) { { member: valid_attributes } }
      it_behaves_like 'NG(html)'
      it_behaves_like 'ToNG(html)', Settings.api_only_mode ? 406 : 403 # NOTE: HTMLもログイン状態になる
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 403
    end
    shared_examples_for '[ログイン中][*][ある]対象メンバーがいない' do
      let_it_be(:show_user) { other_user }
      let_it_be(:member)    { member_myself }
      let(:params) { { member: valid_attributes } }
      # it_behaves_like 'NG(html)' # NOTE: 存在しない為
      it_behaves_like 'ToNG(html)', Settings.api_only_mode ? 406 : 404
      # it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中][*][ある]対象メンバーがいない' do
      let_it_be(:show_user) { other_user }
      let_it_be(:member)    { member_myself }
      let(:params) { { member: valid_attributes } }
      # it_behaves_like 'NG(html)' # NOTE: 存在しない為
      it_behaves_like 'ToNG(html)', Settings.api_only_mode ? 406 : 404 # NOTE: HTMLもログイン状態になる
      # it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 404
    end

    shared_examples_for '[ログイン中][*]権限がある' do |power|
      let_it_be(:member_myself) { FactoryBot.create(:member, power, space:, user:) }
      let(:user_power) { power }
      it_behaves_like '[ログイン中][*][ある]対象メンバーがいる（他人）'
      it_behaves_like '[ログイン中][*][ある]対象メンバーがいる（自分）'
      it_behaves_like '[ログイン中][*][ある]対象メンバーがいない'
    end
    shared_examples_for '[APIログイン中][*]権限がある' do |power|
      let_it_be(:member_myself) { FactoryBot.create(:member, power, space:, user:) }
      let(:user_power) { power }
      it_behaves_like '[APIログイン中][*][ある]対象メンバーがいる（他人）'
      it_behaves_like '[APIログイン中][*][ある]対象メンバーがいる（自分）'
      it_behaves_like '[APIログイン中][*][ある]対象メンバーがいない'
    end
    shared_examples_for '[ログイン中][*]権限がない' do |power|
      let_it_be(:member_myself) { FactoryBot.create(:member, power, space:, user:) if power.present? }
      let(:user_power) { power }
      let_it_be(:show_user) { other_user }
      let_it_be(:member)    { FactoryBot.create(:member, space:, user: show_user) }
      let(:params) { { member: valid_attributes } }
      it_behaves_like 'NG(html)'
      it_behaves_like 'ToNG(html)', Settings.api_only_mode ? 406 : 403
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中][*]権限がない' do |power|
      let_it_be(:member_myself) { FactoryBot.create(:member, power, space:, user:) if power.present? }
      let(:user_power) { power }
      let_it_be(:show_user) { other_user }
      let_it_be(:member)    { FactoryBot.create(:member, space:, user: show_user) }
      let(:params) { { member: valid_attributes } }
      it_behaves_like 'NG(html)'
      it_behaves_like 'ToNG(html)', Settings.api_only_mode ? 406 : 403 # NOTE: HTMLもログイン状態になる
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 403
    end

    shared_examples_for '[ログイン中]スペースが存在しない' do
      let_it_be(:space)     { FactoryBot.build_stubbed(:space) }
      let_it_be(:show_user) { other_user }
      let(:params) { { member: valid_attributes } }
      # it_behaves_like 'NG(html)' # NOTE: 存在しない為
      it_behaves_like 'ToNG(html)', Settings.api_only_mode ? 406 : 404
      # it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中]スペースが存在しない' do
      let_it_be(:space)     { FactoryBot.build_stubbed(:space) }
      let_it_be(:show_user) { other_user }
      let(:params) { { member: valid_attributes } }
      # it_behaves_like 'NG(html)' # NOTE: 存在しない為
      it_behaves_like 'ToNG(html)', Settings.api_only_mode ? 406 : 404 # NOTE: HTMLもログイン状態になる
      # it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 404
    end
    shared_examples_for '[ログイン中]スペースが公開' do
      let_it_be(:space) { FactoryBot.create(:space, :public, created_user:) }
      it_behaves_like '[ログイン中][*]権限がある', :admin
      it_behaves_like '[ログイン中][*]権限がない', :writer
      it_behaves_like '[ログイン中][*]権限がない', :reader
      it_behaves_like '[ログイン中][*]権限がない', nil
    end
    shared_examples_for '[APIログイン中]スペースが公開' do
      let_it_be(:space) { FactoryBot.create(:space, :public, created_user:) }
      it_behaves_like '[APIログイン中][*]権限がある', :admin
      it_behaves_like '[APIログイン中][*]権限がない', :writer
      it_behaves_like '[APIログイン中][*]権限がない', :reader
      it_behaves_like '[APIログイン中][*]権限がない', nil
    end
    shared_examples_for '[ログイン中]スペースが非公開' do
      let_it_be(:space) { FactoryBot.create(:space, :private, created_user:) }
      it_behaves_like '[ログイン中][*]権限がある', :admin
      it_behaves_like '[ログイン中][*]権限がない', :writer
      it_behaves_like '[ログイン中][*]権限がない', :reader
      it_behaves_like '[ログイン中][*]権限がない', nil
    end
    shared_examples_for '[APIログイン中]スペースが非公開' do
      let_it_be(:space) { FactoryBot.create(:space, :private, created_user:) }
      it_behaves_like '[APIログイン中][*]権限がある', :admin
      it_behaves_like '[APIログイン中][*]権限がない', :writer
      it_behaves_like '[APIログイン中][*]権限がない', :reader
      it_behaves_like '[APIログイン中][*]権限がない', nil
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
      include_context 'valid_condition'
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
