require 'rails_helper'

RSpec.describe 'Members', type: :request do
  let(:response_json) { JSON.parse(response.body) }
  let(:response_json_email)  { response_json['email'] }
  let(:response_json_emails) { response_json['emails'] }

  # POST /members/:space_code/create メンバー招待(処理)
  # POST /members/:space_code/create(.json) メンバー招待API(処理)
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）, APIログイン中, APIログイン中（削除予約済み）
  #   スペース: 存在しない, 公開, 非公開
  #   権限: ある（管理者）, ない（投稿者, 閲覧者, なし）
  #   パラメータなし, 有効なパラメータ, 無効なパラメータ
  #   ＋URLの拡張子: ない, .json
  #   ＋Acceptヘッダ: HTMLが含まれる, JSONが含まれる
  describe 'POST #create' do
    subject { post create_member_path(space_code: space.code, format: subject_format), params: { member: attributes }, headers: auth_headers.merge(accept_headers) }
    let_it_be(:exist_user)     { FactoryBot.create(:user) }
    let_it_be(:new_user)       { FactoryBot.create(:user) }
    let_it_be(:not_exist_user) { FactoryBot.build_stubbed(:user) }
    let_it_be(:emails)         { [exist_user.email, new_user.email, not_exist_user.email] }
    let_it_be(:valid_attributes)   { FactoryBot.attributes_for(:member).merge({ emails: emails.join("\r\n") }) }
    let_it_be(:invalid_attributes) { valid_attributes.merge(emails: nil) }
    let(:current_member) { Member.last }

    shared_context 'valid_condition' do
      let_it_be(:space) { FactoryBot.create(:space) }
      include_context 'set_power', :admin
      let(:attributes) { valid_attributes }
    end
    shared_context 'set_power' do |power|
      let(:user_power) { power }
      before_all do
        FactoryBot.create(:member, power: power, space: space, user: user) if power.present? && user.present?
        FactoryBot.create(:member, space: space, user: exist_user)
      end
    end

    # テスト内容
    shared_examples_for 'OK' do
      it 'メンバーが1件作成・対象項目が設定される' do
        expect do
          subject
          expect(current_member.space).to eq(space)
          expect(current_member.user).to eq(new_user)
          expect(current_member.power.to_sym).to eq(attributes[:power])
          expect(current_member.invitationed_user_id).to be(user.id)
          expect(current_member.last_updated_user).to be_nil
        end.to change(Member, :count).by(1)
      end
    end
    shared_examples_for 'NG' do
      it 'メンバーが作成されない' do
        expect { subject }.to change(Member, :count).by(0)
      end
    end

    shared_examples_for 'ToOK(html/*)' do
      it 'メンバー招待（結果）にリダイレクトする' do
        is_expected.to redirect_to(result_member_path(space.code))
        expect(flash[:alert]).to be_nil
        expect(flash[:notice]).to eq(I18n.t('notice.member.create'))
        expect(flash[:emails]).to eq(emails)
        expect(flash[:exist_user_mails]).to eq([exist_user.email])
        expect(flash[:create_user_mails]).to eq([new_user.email])
        expect(flash[:power]).to eq(attributes[:power].to_s)
      end
    end
    shared_examples_for 'ToOK(json/json)' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      let(:member_count) { 1 }
      it 'HTTPステータスが201。対象項目が一致する' do
        is_expected.to eq(201)
        expect(response_json['success']).to eq(true)
        expect(response_json['alert']).to be_nil
        expect(response_json['notice']).to eq(I18n.t('notice.member.create'))

        expect(response_json_email['count']).to eq(emails.count)
        expect(response_json_email['create_count']).to eq(1)
        expect(response_json_email['exist_count']).to eq(1)
        expect(response_json_email['notfound_count']).to eq(1)

        expect(response_json_emails[0]['email']).to eq(emails[0])
        expect(response_json_emails[0]['result']).to eq('exist')
        expect(response_json_emails[0]['result_i18n']).to eq('既に参加しています。')
        expect(response_json_emails[1]['email']).to eq(emails[1])
        expect(response_json_emails[1]['result']).to eq('create')
        expect(response_json_emails[1]['result_i18n']).to eq('招待しました。')
        expect(response_json_emails[2]['email']).to eq(emails[2])
        expect(response_json_emails[2]['result']).to eq('notfound')
        expect(response_json_emails[2]['result_i18n']).to eq('アカウントが存在しません。登録後に招待してください。')
        expect(response_json['power']).to eq(attributes[:power].to_s)
        expect(response_json['power_i18n']).to eq(Member.powers_i18n[attributes[:power].to_s])

        expect(response_json['user_codes'].sort).to eq([exist_user.code, new_user.code].sort)
      end
    end

    # テストケース
    shared_examples_for '[ログイン中][*][ある]パラメータなし' do
      let(:attributes) { nil }
      it_behaves_like 'NG(html)'
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(html)', 422
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中][*][ある]パラメータなし' do
      let(:attributes) { nil }
      it_behaves_like 'NG(html)'
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(html)', 422, [I18n.t('activerecord.errors.models.member.attributes.emails.blank'), I18n.t('activerecord.errors.models.member.attributes.power.blank')]
      it_behaves_like 'ToNG(json)', 422, { emails: [I18n.t('activerecord.errors.models.member.attributes.emails.blank')], power: [I18n.t('activerecord.errors.models.member.attributes.power.blank')] }
    end
    shared_examples_for '[ログイン中][*][ある]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK(html)'
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToOK(html)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中][*][ある]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK(html)'
      it_behaves_like 'OK(json)'
      it_behaves_like 'ToOK(html)' # NOTE: HTMLもログイン状態になる
      it_behaves_like 'ToOK(json)'
    end
    shared_examples_for '[ログイン中][*][ある]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG(html)'
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(html)', 422
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中][*][ある]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG(html)'
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(html)', 422, [I18n.t('activerecord.errors.models.member.attributes.emails.blank')] # NOTE: HTMLもログイン状態になる
      it_behaves_like 'ToNG(json)', 422, { emails: [I18n.t('activerecord.errors.models.member.attributes.emails.blank')] }
    end

    shared_examples_for '[ログイン中][*]権限がある' do |power|
      include_context 'set_power', power
      it_behaves_like '[ログイン中][*][ある]パラメータなし'
      it_behaves_like '[ログイン中][*][ある]有効なパラメータ'
      it_behaves_like '[ログイン中][*][ある]無効なパラメータ'
    end
    shared_examples_for '[APIログイン中][*]権限がある' do |power|
      include_context 'set_power', power
      it_behaves_like '[APIログイン中][*][ある]パラメータなし'
      it_behaves_like '[APIログイン中][*][ある]有効なパラメータ'
      it_behaves_like '[APIログイン中][*][ある]無効なパラメータ'
    end
    shared_examples_for '[ログイン中][*]権限がない' do |power|
      include_context 'set_power', power
      let(:attributes) { valid_attributes }
      it_behaves_like 'NG(html)'
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(html)', 403
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中][*]権限がない' do |power|
      include_context 'set_power', power
      let(:attributes) { valid_attributes }
      it_behaves_like 'NG(html)'
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(html)', 403 # NOTE: HTMLもログイン状態になる
      it_behaves_like 'ToNG(json)', 403
    end

    shared_examples_for '[ログイン中]スペースが存在しない' do
      let_it_be(:space) { FactoryBot.build_stubbed(:space) }
      let(:attributes) { valid_attributes }
      it_behaves_like 'NG(html)'
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(html)', 404
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中]スペースが存在しない' do
      let_it_be(:space) { FactoryBot.build_stubbed(:space) }
      let(:attributes) { valid_attributes }
      it_behaves_like 'NG(html)'
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(html)', 404 # NOTE: HTMLもログイン状態になる
      it_behaves_like 'ToNG(json)', 404
    end
    shared_examples_for '[ログイン中]スペースが公開' do
      let_it_be(:space) { FactoryBot.create(:space, :public) }
      it_behaves_like '[ログイン中][*]権限がある', :admin
      it_behaves_like '[ログイン中][*]権限がない', :writer
      it_behaves_like '[ログイン中][*]権限がない', :reader
      it_behaves_like '[ログイン中][*]権限がない', nil
    end
    shared_examples_for '[APIログイン中]スペースが公開' do
      let_it_be(:space) { FactoryBot.create(:space, :public) }
      it_behaves_like '[APIログイン中][*]権限がある', :admin
      it_behaves_like '[APIログイン中][*]権限がない', :writer
      it_behaves_like '[APIログイン中][*]権限がない', :reader
      it_behaves_like '[APIログイン中][*]権限がない', nil
    end
    shared_examples_for '[ログイン中]スペースが非公開' do
      let_it_be(:space) { FactoryBot.create(:space, :private) }
      it_behaves_like '[ログイン中][*]権限がある', :admin
      it_behaves_like '[ログイン中][*]権限がない', :writer
      it_behaves_like '[ログイン中][*]権限がない', :reader
      it_behaves_like '[ログイン中][*]権限がない', nil
    end
    shared_examples_for '[APIログイン中]スペースが非公開' do
      let_it_be(:space) { FactoryBot.create(:space, :private) }
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
      it_behaves_like 'ToMembers(html)', 'alert.user.destroy_reserved'
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
      it_behaves_like 'ToMembers(html)', 'alert.user.destroy_reserved' # NOTE: HTMLもログイン状態になる
      it_behaves_like 'ToNG(json)', 422, nil, 'alert.user.destroy_reserved'
    end
  end
end
