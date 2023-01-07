require 'rails_helper'

RSpec.describe 'Users::Registrations', type: :request do
  # GET /users/sign_up アカウント登録
  # 前提条件
  #   未ログイン, 招待コードあり
  # テストパターン
  #   招待コード: 有効, 期限切れ, 削除済み, 参加済み, 存在しない
  describe 'GET #new' do
    subject { get new_user_registration_path(code: invitation.code) }

    # テストケース
    shared_examples_for '[無効]' do |status|
      let(:invitation) { FactoryBot.create(:invitation, status) }
      it_behaves_like 'ToNG(html/html)', 404, [get_locale('alert.invitation.notfound')]
    end

    context '招待コードが有効' do
      let(:invitation) { FactoryBot.create(:invitation, :active) }
      it_behaves_like 'ToOK[status]'
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
      let(:invitation) { FactoryBot.build_stubbed(:invitation, :active) }
      it_behaves_like 'ToNG(html/html)', 404, [get_locale('alert.invitation.notfound')]
    end
  end

  # POST /users/sign_up アカウント登録(処理)
  # 前提条件
  #   未ログイン, 招待コードあり, 有効なパラメータ
  # テストパターン
  #   招待コード: 有効, 期限切れ, 削除済み, 参加済み, 存在しない
  #   他のスペースでの招待: なし, あり
  #   対象: メールアドレス, ドメイン
  #   パラメータのメールアドレス/ドメイン: 招待と一致/含まれる, 不一致/含まれない
  describe 'POST #create' do
    subject { post create_user_registration_path(code: invitation.code), params: { user: attributes } }
    let_it_be(:new_user) { FactoryBot.attributes_for(:user, email: 'test@example.com') }
    let_it_be(:valid_attributes_email)       { { name: new_user[:name], email: new_user[:email], password: new_user[:password] } }
    let_it_be(:valid_attributes_email_diff)  { { name: new_user[:name], email: 'test@diff.example.com', password: new_user[:password] } }
    let_it_be(:valid_attributes_domain)      { { name: new_user[:name], email_local: 'test', email_domain: 'example.com', password: new_user[:password] } }
    let_it_be(:valid_attributes_domain_diff) { { name: new_user[:name], email_local: 'test', email_domain: 'diff.example.com', password: new_user[:password] } }
    let_it_be(:created_user) { FactoryBot.create(:user) }
    before_all { FactoryBot.create(:invitation, :active, :email, created_user: created_user) } # NOTE: 対象外
    let(:current_user) { User.find_by!(email: email) }

    shared_context 'valid_condition' do |status|
      let(:attributes) { valid_attributes_email }
      let_it_be(:invitation) { FactoryBot.create(:invitation, status, email: new_user[:email], domains: nil, created_user: created_user) }
    end

    # テスト内容
    shared_examples_for 'OK' do
      let!(:start_time) { Time.current.floor }
      let(:url) { "http://#{Settings['base_domain']}#{user_confirmation_path}" }
      it '作成・対象項目が設定される。メールが送信される' do
        expect do
          subject
          expect(current_user.name).to eq(attributes[:name]) # メールアドレス、氏名

          expect(ActionMailer::Base.deliveries.count).to eq(1)
          expect(ActionMailer::Base.deliveries[0].subject).to eq(get_subject('devise.mailer.confirmation_instructions.subject')) # メールアドレス確認のお願い
          expect(ActionMailer::Base.deliveries[0].html_part.body).to include(url)
          expect(ActionMailer::Base.deliveries[0].text_part.body).to include(url)

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
      it '作成されない。メールが送信されない' do
        expect { subject }.to change(User, :count).by(0) && change(ActionMailer::Base.deliveries, :count).by(0) && change(Member, :count).by(0)
      end
    end

    # テストケース
    shared_examples_for '[有効][*][メールアドレス]パラメータのメールアドレスが招待と一致' do
      let(:attributes)  { valid_attributes_email }
      let(:email)       { attributes[:email] }
      let(:invitations)    { [invitation, other_invitation].compact }
      let(:invitation_ids) { [invitation.id, other_invitation&.id].compact }
      it_behaves_like 'OK'
      it_behaves_like 'ToLogin', nil, 'devise.registrations.signed_up_but_unconfirmed'
    end
    shared_examples_for '[有効][*][メールアドレス]パラメータのメールアドレスが招待と不一致' do
      let(:attributes)  { valid_attributes_email_diff }
      let(:email)       { new_user[:email] } # NOTE: パラメータのメールアドレスは無視する
      let(:invitations)    { [invitation, other_invitation].compact }
      let(:invitation_ids) { [invitation.id, other_invitation&.id].compact }
      it_behaves_like 'OK'
      it_behaves_like 'ToLogin', nil, 'devise.registrations.signed_up_but_unconfirmed'
    end
    shared_examples_for '[有効][*][ドメイン]パラメータのドメインが招待に含まれる' do
      let(:attributes)  { valid_attributes_domain }
      let(:email)       { "#{attributes[:email_local]}@#{attributes[:email_domain]}" }
      let(:invitations)    { [invitation, other_invitation].compact }
      let(:invitation_ids) { [other_invitation&.id].compact }
      it_behaves_like 'OK'
      it_behaves_like 'ToLogin', nil, 'devise.registrations.signed_up_but_unconfirmed'
    end
    shared_examples_for '[有効][*][ドメイン]パラメータのドメインが招待に含まれない' do
      let(:attributes) { valid_attributes_domain_diff }
      it_behaves_like 'NG'
      it_behaves_like 'ToError', 'activerecord.errors.models.user.attributes.email.invalid'
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
      it_behaves_like 'ToNG(html/html)', 404, [get_locale('alert.invitation.notfound')]
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
      it_behaves_like 'ToNG(html/html)', 404, [get_locale('alert.invitation.notfound')]
    end
  end
end
