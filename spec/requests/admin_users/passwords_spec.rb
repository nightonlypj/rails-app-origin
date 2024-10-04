require 'rails_helper'

RSpec.describe 'AdminUsers::Passwords', type: :request do
  # テスト内容（共通）
  shared_examples_for 'ToNew' do |alert, notice|
    it 'パスワード再設定[メール送信]にリダイレクトする' do
      is_expected.to redirect_to(new_admin_user_password_path)
      expect(flash[:alert]).to alert.present? ? eq(get_locale(alert)) : be_nil
      expect(flash[:notice]).to notice.present? ? eq(get_locale(notice)) : be_nil
    end
  end

  # GET /admin/password/reset パスワード再設定[メール送信]
  # テストパターン
  #   未ログイン, ログイン中
  describe 'GET #new' do
    subject { get new_admin_user_password_path }

    # テストケース
    context '未ログイン' do
      it_behaves_like 'ToOK[status]'
    end
    context 'ログイン中' do
      include_context 'ログイン処理（管理者）'
      it_behaves_like 'ToAdmin', 'devise.failure.already_authenticated', nil
    end
  end

  # POST /admin/password/reset パスワード再設定[メール送信](処理)
  # テストパターン
  #   未ログイン, ログイン中
  #   有効なパラメータ（未ロック, ロック中）, 無効なパラメータ
  describe 'POST #create' do
    subject { post create_admin_user_password_path, params: { admin_user: attributes } }
    let_it_be(:send_admin_user_unlocked) { FactoryBot.create(:admin_user) }
    let_it_be(:send_admin_user_locked)   { FactoryBot.create(:admin_user, :locked) }
    let_it_be(:not_admin_user)           { FactoryBot.attributes_for(:admin_user) }
    let(:valid_attributes)   { { email: send_admin_user.email } }
    let(:invalid_attributes) { { email: not_admin_user[:email] } }

    # テスト内容
    shared_examples_for 'OK' do
      let(:url) { "http://#{Settings.base_domain}#{edit_admin_user_password_path}" }
      it 'メールが送信される' do
        subject
        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect(ActionMailer::Base.deliveries[0].subject).to eq(get_subject('devise.mailer.reset_password_instructions.admin_user_subject')) # パスワード再設定方法のお知らせ
        expect(ActionMailer::Base.deliveries[0].html_part.body).to include(url)
        expect(ActionMailer::Base.deliveries[0].text_part.body).to include(url)
      end
    end
    shared_examples_for 'NG' do
      it 'メールが送信されない' do
        expect { subject }.not_to change(ActionMailer::Base.deliveries, :count)
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]有効なパラメータ（未ロック）' do
      let(:send_admin_user) { send_admin_user_unlocked }
      let(:attributes)      { valid_attributes }
      it_behaves_like 'OK'
      it_behaves_like 'ToAdminLogin', nil, 'devise.passwords.send_instructions'
    end
    shared_examples_for '[ログイン中]有効なパラメータ（未ロック）' do
      let(:send_admin_user) { send_admin_user_unlocked }
      let(:attributes)      { valid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToAdmin', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]有効なパラメータ（ロック中）' do # NOTE: ロック中も出来ても良さそう
      let(:send_admin_user) { send_admin_user_locked }
      let(:attributes)      { valid_attributes }
      it_behaves_like 'OK'
      it_behaves_like 'ToAdminLogin', nil, 'devise.passwords.send_instructions'
    end
    shared_examples_for '[ログイン中]有効なパラメータ（ロック中）' do
      let(:send_admin_user) { send_admin_user_locked }
      let(:attributes)      { valid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToAdmin', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToError', 'errors.messages.not_found'
    end
    shared_examples_for '[ログイン中]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToAdmin', 'devise.failure.already_authenticated', nil
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]有効なパラメータ（未ロック）'
      it_behaves_like '[未ログイン]有効なパラメータ（ロック中）'
      it_behaves_like '[未ログイン]無効なパラメータ'
    end
    context 'ログイン中' do
      include_context 'ログイン処理（管理者）'
      it_behaves_like '[ログイン中]有効なパラメータ（未ロック）'
      it_behaves_like '[ログイン中]有効なパラメータ（ロック中）'
      it_behaves_like '[ログイン中]無効なパラメータ'
    end
  end

  # GET /admin/password パスワード再設定
  # テストパターン
  #   未ログイン, ログイン中
  #   トークン: 期限内（未ロック, ロック中）, 期限切れ, 存在しない, ない
  describe 'GET #edit' do
    subject { get edit_admin_user_password_path(reset_password_token:) }

    # テストケース
    shared_examples_for '[未ログイン]トークンが期限内（未ロック）' do
      include_context 'パスワードリセットトークン作成（管理者）', true
      it_behaves_like 'ToOK[status]'
    end
    shared_examples_for '[ログイン中]トークンが期限内（未ロック）' do
      include_context 'パスワードリセットトークン作成（管理者）', true
      it_behaves_like 'ToAdmin', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]トークンが期限内（ロック中）' do # NOTE: ロック中も出来ても良さそう
      include_context 'パスワードリセットトークン作成（管理者）', true, true
      it_behaves_like 'ToOK[status]'
    end
    shared_examples_for '[ログイン中]トークンが期限内（ロック中）' do
      include_context 'パスワードリセットトークン作成（管理者）', true, true
      it_behaves_like 'ToAdmin', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]トークンが期限切れ' do
      include_context 'パスワードリセットトークン作成（管理者）', false
      it_behaves_like 'ToNew', 'activerecord.errors.models.admin_user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[ログイン中]トークンが期限切れ' do
      include_context 'パスワードリセットトークン作成（管理者）', false
      it_behaves_like 'ToAdmin', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]トークンが存在しない' do
      let(:reset_password_token) { NOT_TOKEN }
      it_behaves_like 'ToNew', 'activerecord.errors.models.admin_user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[ログイン中]トークンが存在しない' do
      let(:reset_password_token) { NOT_TOKEN }
      it_behaves_like 'ToAdmin', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]トークンがない' do
      let(:reset_password_token) { nil }
      it_behaves_like 'ToAdminLogin', 'devise.passwords.no_token', nil
    end
    shared_examples_for '[ログイン中]トークンがない' do
      let(:reset_password_token) { nil }
      it_behaves_like 'ToAdmin', 'devise.failure.already_authenticated', nil
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]トークンが期限内（未ロック）'
      it_behaves_like '[未ログイン]トークンが期限内（ロック中）'
      it_behaves_like '[未ログイン]トークンが期限切れ'
      it_behaves_like '[未ログイン]トークンが存在しない'
      it_behaves_like '[未ログイン]トークンがない'
    end
    context 'ログイン中' do
      include_context 'ログイン処理（管理者）'
      it_behaves_like '[ログイン中]トークンが期限内（未ロック）'
      it_behaves_like '[ログイン中]トークンが期限内（ロック中）'
      it_behaves_like '[ログイン中]トークンが期限切れ'
      it_behaves_like '[ログイン中]トークンが存在しない'
      it_behaves_like '[ログイン中]トークンがない'
    end
  end

  # PUT /admin/password パスワード再設定(処理)
  # テストパターン
  #   未ログイン, ログイン中
  #   トークン: 期限内（未ロック, ロック中）, 期限切れ, 存在しない, ない
  #   有効なパラメータ, 無効なパラメータ
  describe 'PUT #update' do
    subject { put update_admin_user_password_path, params: { admin_user: attributes } }
    let(:new_password) { Faker::Internet.password(min_length: 8) }
    let(:valid_attributes)   { { reset_password_token:, password: new_password, password_confirmation: new_password } }
    let(:invalid_attributes) { { reset_password_token:, password: nil, password_confirmation: nil } }

    # テスト内容
    let(:current_admin_user) { AdminUser.find(send_admin_user.id) }
    shared_examples_for 'OK' do
      it 'パスワードリセット送信日時がなしに変更される。メールが送信される' do
        subject
        expect(current_admin_user.reset_password_sent_at).to be_nil

        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect(ActionMailer::Base.deliveries[0].subject).to eq(get_subject('devise.mailer.password_change.admin_user_subject')) # パスワード変更完了のお知らせ
      end
    end
    shared_examples_for 'NG' do
      it 'パスワードリセット送信日時が変更されない。メールが送信されない' do
        subject
        expect(current_admin_user.reset_password_sent_at).to eq(send_admin_user.reset_password_sent_at)

        expect(ActionMailer::Base.deliveries.count).to eq(0)
      end
    end

    # テストケース
    shared_examples_for '[未ログイン][期限内]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      it_behaves_like 'ToAdmin', nil, 'devise.passwords.updated'
    end
    shared_examples_for '[ログイン中][期限内/期限切れ]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToAdmin', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン][期限切れ]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNew', 'activerecord.errors.models.admin_user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[未ログイン][存在しない]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      # it_behaves_like 'NG' # NOTE: トークンが存在しない為、送信日時がない
      it_behaves_like 'ToNew', 'activerecord.errors.models.admin_user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[ログイン中][存在しない]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      # it_behaves_like 'NG' # NOTE: トークンが存在しない為、送信日時がない
      it_behaves_like 'ToAdmin', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン][期限内]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToError', 'activerecord.errors.models.admin_user.attributes.password.blank'
    end
    shared_examples_for '[ログイン中][期限内/期限切れ]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToAdmin', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン][期限切れ]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNew', 'activerecord.errors.models.admin_user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[未ログイン][存在しない]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      # it_behaves_like 'NG' # NOTE: トークンが存在しない為、送信日時がない
      it_behaves_like 'ToNew', 'activerecord.errors.models.admin_user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[ログイン中][存在しない]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      # it_behaves_like 'NG' # NOTE: トークンが存在しない為、送信日時がない
      it_behaves_like 'ToAdmin', 'devise.failure.already_authenticated', nil
    end

    shared_examples_for '[未ログイン]トークンが期限内（未ロック）' do
      include_context 'パスワードリセットトークン作成（管理者）', true
      it_behaves_like '[未ログイン][期限内]有効なパラメータ'
      it_behaves_like '[未ログイン][期限内]無効なパラメータ'
    end
    shared_examples_for '[ログイン中]トークンが期限内（未ロック）' do
      include_context 'パスワードリセットトークン作成（管理者）', true
      it_behaves_like '[ログイン中][期限内/期限切れ]有効なパラメータ'
      it_behaves_like '[ログイン中][期限内/期限切れ]無効なパラメータ'
    end
    shared_examples_for '[未ログイン]トークンが期限内（ロック中）' do
      include_context 'パスワードリセットトークン作成（管理者）', true, true
      it_behaves_like '[未ログイン][期限内]有効なパラメータ' # NOTE: ロック中も出来ても良さそう
      it_behaves_like '[未ログイン][期限内]無効なパラメータ'
    end
    shared_examples_for '[ログイン中]トークンが期限内（ロック中）' do
      include_context 'パスワードリセットトークン作成（管理者）', true, true
      it_behaves_like '[ログイン中][期限内/期限切れ]有効なパラメータ'
      it_behaves_like '[ログイン中][期限内/期限切れ]無効なパラメータ'
    end
    shared_examples_for '[未ログイン]トークンが期限切れ' do
      include_context 'パスワードリセットトークン作成（管理者）', false
      it_behaves_like '[未ログイン][期限切れ]有効なパラメータ'
      it_behaves_like '[未ログイン][期限切れ]無効なパラメータ'
    end
    shared_examples_for '[ログイン中]トークンが期限切れ' do
      include_context 'パスワードリセットトークン作成（管理者）', false
      it_behaves_like '[ログイン中][期限内/期限切れ]有効なパラメータ'
      it_behaves_like '[ログイン中][期限内/期限切れ]無効なパラメータ'
    end
    shared_examples_for '[未ログイン]トークンが存在しない' do
      let(:reset_password_token) { NOT_TOKEN }
      it_behaves_like '[未ログイン][存在しない]有効なパラメータ'
      it_behaves_like '[未ログイン][存在しない]無効なパラメータ'
    end
    shared_examples_for '[ログイン中]トークンが存在しない' do
      let(:reset_password_token) { NOT_TOKEN }
      it_behaves_like '[ログイン中][存在しない]有効なパラメータ'
      it_behaves_like '[ログイン中][存在しない]無効なパラメータ'
    end
    shared_examples_for '[未ログイン]トークンがない' do
      let(:reset_password_token) { nil }
      it_behaves_like '[未ログイン][存在しない]有効なパラメータ'
      it_behaves_like '[未ログイン][存在しない]無効なパラメータ'
    end
    shared_examples_for '[ログイン中]トークンがない' do
      let(:reset_password_token) { nil }
      it_behaves_like '[ログイン中][存在しない]有効なパラメータ'
      it_behaves_like '[ログイン中][存在しない]無効なパラメータ'
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]トークンが期限内（未ロック）'
      it_behaves_like '[未ログイン]トークンが期限内（ロック中）'
      it_behaves_like '[未ログイン]トークンが期限切れ'
      it_behaves_like '[未ログイン]トークンが存在しない'
      it_behaves_like '[未ログイン]トークンがない'
    end
    context 'ログイン中' do
      include_context 'ログイン処理（管理者）'
      it_behaves_like '[ログイン中]トークンが期限内（未ロック）'
      it_behaves_like '[ログイン中]トークンが期限内（ロック中）'
      it_behaves_like '[ログイン中]トークンが期限切れ'
      it_behaves_like '[ログイン中]トークンが存在しない'
      it_behaves_like '[ログイン中]トークンがない'
    end
  end
end
