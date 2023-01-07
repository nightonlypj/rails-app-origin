require 'rails_helper'

RSpec.describe 'Users::Auth::Registrations', type: :request do
  let(:response_json) { JSON.parse(response.body) }
  let(:response_json_invitation) { response_json['invitation'] }

  # GET /users/auth/invitation(.json) 招待情報取得API
  # テストパターン
  #   未ログイン, ログイン中, APIログイン中
  #   招待コード: 有効, 期限切れ, 削除済み, 参加済み, 存在しない, ない
  #   対象: メールアドレス, ドメイン
  #   ＋URLの拡張子: .json, ない
  #   ＋Acceptヘッダ: JSONが含まれる, JSONが含まれない
  describe 'GET #invitation' do
    subject { get invitation_user_auth_registration_path(code: invitation&.code, format: subject_format), headers: auth_headers.merge(accept_headers) }

    # テスト内容
    shared_examples_for 'ToOK(json/json)' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it 'HTTPステータスが200。対象項目が一致する' do
        is_expected.to eq(200)
        expect(response_json['success']).to eq(true)
        if invitation.email.present?
          expect(response_json_invitation['email']).to eq(invitation.email)
          expect(response_json_invitation['domains']).to be_nil
        else
          expect(response_json_invitation['email']).to be_nil
          expect(response_json_invitation['domains']).to eq(invitation.domains_array)
        end
      end
    end

    # テストケース
    shared_examples_for '[未ログイン/ログイン中][有効]対象がメールアドレス' do
      let(:invitation) { FactoryBot.create(:invitation, :active, :email) }
      it_behaves_like 'ToNG(html)', 406
      it_behaves_like 'ToOK(json)'
    end
    shared_examples_for '[未ログイン/ログイン中][有効]対象がドメイン' do
      let(:invitation) { FactoryBot.create(:invitation, :active, :domains) }
      it_behaves_like 'ToNG(html)', 406
      it_behaves_like 'ToOK(json)'
    end
    shared_examples_for '[未ログイン/ログイン中][無効]' do |status|
      let(:invitation) { FactoryBot.create(:invitation, status, :email) if status.present? }
      it_behaves_like 'ToNG(html)', 406
      it_behaves_like 'ToNG(json)', 404, nil, 'alert.invitation.notfound'
    end

    shared_examples_for '[未ログイン/ログイン中]招待コードが有効' do
      it_behaves_like '[未ログイン/ログイン中][有効]対象がメールアドレス'
      it_behaves_like '[未ログイン/ログイン中][有効]対象がドメイン'
    end
    shared_examples_for '[未ログイン/ログイン中]招待コードが期限切れ' do
      it_behaves_like '[未ログイン/ログイン中][無効]', :expired
    end
    shared_examples_for '[未ログイン/ログイン中]招待コードが削除済み' do
      it_behaves_like '[未ログイン/ログイン中][無効]', :deleted
    end
    shared_examples_for '[未ログイン/ログイン中]招待コードが参加済み' do
      it_behaves_like '[未ログイン/ログイン中][無効]', :email_joined
    end
    shared_examples_for '[未ログイン/ログイン中]招待コードが存在しない' do
      let(:invitation) { FactoryBot.build_stubbed(:invitation) }
      it_behaves_like 'ToNG(html)', 406
      it_behaves_like 'ToNG(json)', 404, nil, 'alert.invitation.notfound'
    end
    shared_examples_for '[未ログイン/ログイン中]招待コードがない' do
      it_behaves_like '[未ログイン/ログイン中][無効]', nil
    end

    shared_examples_for '[未ログイン/ログイン中]' do
      it_behaves_like '[未ログイン/ログイン中]招待コードが有効'
      it_behaves_like '[未ログイン/ログイン中]招待コードが期限切れ'
      it_behaves_like '[未ログイン/ログイン中]招待コードが削除済み'
      it_behaves_like '[未ログイン/ログイン中]招待コードが参加済み'
      it_behaves_like '[未ログイン/ログイン中]招待コードが存在しない'
      it_behaves_like '[未ログイン/ログイン中]招待コードがない'
    end

    context '未ログイン' do
      include_context '未ログイン処理'
      it_behaves_like '[未ログイン/ログイン中]'
    end
    context 'ログイン中' do
      include_context '未ログイン処理'
      it_behaves_like '[未ログイン/ログイン中]'
    end
    context 'APIログイン中' do
      include_context 'APIログイン処理'
      let(:invitation) { FactoryBot.create(:invitation, :active, :email) }
      it_behaves_like 'ToNG(html)', 406
      it_behaves_like 'ToNG(json)', 401, nil, 'devise.failure.already_authenticated'
    end
  end

  # POST /users/auth/sign_up(.json) アカウント登録API(処理)
  # 前提条件
  #   未ログイン（URLの拡張子が.json/AcceptヘッダにJSONが含まれる）, 招待コードあり, 有効なパラメータ
  # テストパターン
  #   招待コード: 有効, 期限切れ, 削除済み, 参加済み, 存在しない
  #   他のスペースでの招待: なし, あり
  #   対象: メールアドレス, ドメイン
  #   パラメータのメールアドレス/ドメイン: 招待と一致/含まれる, 不一致/含まれない
  describe 'POST #create' do
    subject { post create_user_auth_registration_path(code: invitation.code, format: subject_format), params: attributes, headers: auth_headers.merge(accept_headers) }
    let_it_be(:new_user) { FactoryBot.attributes_for(:user, email: 'test@example.com') }
    let_it_be(:valid_attributes_email)       { { name: new_user[:name], email: new_user[:email], password: new_user[:password], confirm_success_url: FRONT_SITE_URL } }
    let_it_be(:valid_attributes_email_diff)  { { name: new_user[:name], email: 'test@diff.example.com', password: new_user[:password], confirm_success_url: FRONT_SITE_URL } }
    let_it_be(:valid_attributes_domain)      { { name: new_user[:name], email_local: 'test', email_domain: 'example.com', password: new_user[:password], confirm_success_url: FRONT_SITE_URL } }
    let_it_be(:valid_attributes_domain_diff) { { name: new_user[:name], email_local: 'test', email_domain: 'diff.example.com', password: new_user[:password], confirm_success_url: FRONT_SITE_URL } }
    let_it_be(:created_user) { FactoryBot.create(:user) }
    before_all { FactoryBot.create(:invitation, :active, :email, created_user: created_user) } # NOTE: 対象外
    include_context 'Authテスト内容'
    let(:current_user) { User.find_by!(email: email) }
    let(:inside_spaces) { [] }

    include_context '未ログイン処理'
    shared_context 'valid_condition' do |status|
      let(:attributes) { valid_attributes_email }
      let_it_be(:invitation) { FactoryBot.create(:invitation, status, email: new_user[:email], domains: nil, created_user: created_user) }
    end

    # テスト内容
    shared_examples_for 'OK' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      let!(:start_time) { Time.current.floor }
      let(:url)       { "http://#{Settings['base_domain']}#{user_auth_confirmation_path}" }
      let(:url_param) { "redirect_url=#{URI.encode_www_form_component(attributes[:confirm_success_url])}" }
      it '作成・対象項目が設定される。メールが送信される' do
        expect do
          subject
          expect(current_user.name).to eq(attributes[:name]) # メールアドレス、氏名

          expect(ActionMailer::Base.deliveries.count).to eq(1)
          expect(ActionMailer::Base.deliveries[0].subject).to eq(get_subject('devise.mailer.confirmation_instructions.subject')) # メールアドレス確認のお願い
          expect(ActionMailer::Base.deliveries[0].html_part.body).to include(url)
          expect(ActionMailer::Base.deliveries[0].text_part.body).to include(url)
          expect(ActionMailer::Base.deliveries[0].html_part.body).to include(url_param)
          expect(ActionMailer::Base.deliveries[0].text_part.body).to include(url_param)

          # メンバー
          expect(Member.count).to eq(invitations.count)
          members = Member.order(:id)
          invitations.each_with_index do |item, index|
            expect(members[index].space).to eq(item.space)
            expect(members[index].user).to eq(current_user)
            expect(members[index].power).to eq(item.power)
            expect(members[index].invitationed_user).to eq(item.created_user)
            expect(members[index].invitationed_at).to item.email.present? ? eq(item.created_at.floor) : be_between(start_time, Time.current)
          end

          # 招待
          update_invitations = Invitation.where(id: invitation_ids).order(:id)
          update_invitations.each do |update_invitation|
            expect(update_invitation.email_joined_at).to be_between(start_time, Time.current)
            expect(update_invitation.last_updated_user_id).to be_nil
            expect(update_invitation.updated_at).to be_between(start_time, Time.current)
          end
        end.to change(User, :count).by(1)
      end
    end
    shared_examples_for 'NG' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it '作成されない。メールが送信されない' do
        expect { subject }.to change(User, :count).by(0) && change(ActionMailer::Base.deliveries, :count).by(0) && change(Member, :count).by(0)
      end
    end

    shared_examples_for 'ToOK(json/json)' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it 'HTTPステータスが200。対象項目が一致する。認証ヘッダがない' do
        is_expected.to eq(200)
        expect_success_json
        expect_not_exist_auth_header
      end
    end

    # テストケース
    shared_examples_for '[有効][*][メールアドレス]パラメータのメールアドレスが招待と一致' do
      let(:attributes)  { valid_attributes_email }
      let(:email)       { attributes[:email] }
      let(:invitations)    { [invitation, other_invitation].compact }
      let(:invitation_ids) { [invitation.id, other_invitation&.id].compact }
      it_behaves_like 'OK'
      it_behaves_like 'ToOK(json/json)'
    end
    shared_examples_for '[有効][*][メールアドレス]パラメータのメールアドレスが招待と不一致' do
      let(:attributes)  { valid_attributes_email_diff }
      let(:email)       { new_user[:email] } # NOTE: パラメータのメールアドレスは無視する
      let(:invitations)    { [invitation, other_invitation].compact }
      let(:invitation_ids) { [invitation.id, other_invitation&.id].compact }
      it_behaves_like 'OK'
      it_behaves_like 'ToOK(json/json)'
    end
    shared_examples_for '[有効][*][ドメイン]パラメータのドメインが招待に含まれる' do
      let(:attributes)  { valid_attributes_domain }
      let(:email)       { "#{attributes[:email_local]}@#{attributes[:email_domain]}" }
      let(:invitations)    { [invitation, other_invitation].compact }
      let(:invitation_ids) { [other_invitation&.id].compact }
      it_behaves_like 'OK'
      it_behaves_like 'ToOK(json/json)'
    end
    shared_examples_for '[有効][*][ドメイン]パラメータのドメインが招待に含まれない' do
      let(:attributes) { valid_attributes_domain_diff }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG(json/json)', 422, {
        email: [get_locale('activerecord.errors.models.user.attributes.email.invalid')],
        full_messages: ["#{User.human_attribute_name(:email)} #{get_locale('activerecord.errors.models.user.attributes.email.invalid')}"]
      }
    end

    shared_examples_for '[有効][*]対象がメールアドレス' do
      let_it_be(:invitation) { FactoryBot.create(:invitation, :active, email: new_user[:email], domains: nil, created_user: created_user, created_at: Time.current - 1.hour) }
      it_behaves_like '[有効][*][メールアドレス]パラメータのメールアドレスが招待と一致'
      it_behaves_like '[有効][*][メールアドレス]パラメータのメールアドレスが招待と不一致'
    end
    shared_examples_for '[有効][*]対象がドメイン' do
      let_it_be(:invitation) do
        domains = ['example.org', valid_attributes_domain[:email_domain]].to_s
        FactoryBot.create(:invitation, :active, email: nil, domains: domains, created_user: created_user, created_at: Time.current - 1.hour)
      end
      it_behaves_like '[有効][*][ドメイン]パラメータのドメインが招待に含まれる'
      it_behaves_like '[有効][*][ドメイン]パラメータのドメインが招待に含まれない'
    end

    shared_examples_for '[有効]他のスペースでの招待なし' do
      let_it_be(:other_invitation) { nil }
      it_behaves_like '[有効][*]対象がメールアドレス'
      it_behaves_like '[有効][*]対象がドメイン'
    end
    shared_examples_for '[有効]他のスペースでの招待あり' do
      let_it_be(:other_invitation) { FactoryBot.create(:invitation, :active, email: new_user[:email], domains: nil, created_user: created_user, created_at: Time.current - 1.day) }
      it_behaves_like '[有効][*]対象がメールアドレス'
      it_behaves_like '[有効][*]対象がドメイン'
    end
    shared_examples_for '[無効]' do |status|
      include_context 'valid_condition', status
      it_behaves_like 'NG'
      it_behaves_like 'ToNG(json/json)', 404, nil, 'alert.invitation.notfound'
    end

    context '招待コードが有効' do
      it_behaves_like '[有効]他のスペースでの招待なし'
      it_behaves_like '[有効]他のスペースでの招待あり'
    end
    context '招待コードが期限切れ' do
      it_behaves_like '[無効]', :expired
    end
    context '招待コードが削除済み' do
      it_behaves_like '[無効]', :deleted
    end
    context '招待コードが参加済み' do
      it_behaves_like '[無効]', :email_joined
    end
    context '招待コードが存在しない' do
      let(:attributes) { valid_attributes_email }
      let_it_be(:invitation) { FactoryBot.build_stubbed(:invitation) }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG(json/json)', 404, nil, 'alert.invitation.notfound'
    end
  end
end
