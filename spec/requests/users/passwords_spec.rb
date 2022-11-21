require 'rails_helper'

RSpec.describe 'Users::Passwords', type: :request do
  # テスト内容（共通）
  shared_examples_for 'ToOK' do
    it 'HTTPステータスが200' do
      is_expected.to eq(200)
    end
  end
  shared_examples_for 'ToError' do |error_msg|
    it 'HTTPステータスが200。対象のエラーメッセージが含まれる' do # NOTE: 再入力
      is_expected.to eq(200)
      expect(response.body).to include(I18n.t(error_msg))
    end
  end
  shared_examples_for 'ToTop' do |alert, notice|
    it 'トップページにリダイレクトする' do
      is_expected.to redirect_to(root_path)
      expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
      expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
    end
  end
  shared_examples_for 'ToLogin' do |alert, notice|
    it 'ログインにリダイレクトする' do
      is_expected.to redirect_to(new_user_session_path)
      expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
      expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
    end
  end
  shared_examples_for 'ToNew' do |alert, notice|
    it 'パスワード再設定[メール送信]にリダイレクトする' do
      is_expected.to redirect_to(new_user_password_path)
      expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
      expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
    end
  end

  # GET /users/password/reset パスワード再設定[メール送信]
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中
  describe 'GET #new' do
    subject { get new_user_password_path }

    # テストケース
    context '未ログイン' do
      it_behaves_like 'ToOK'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
  end

  # POST /users/password/reset パスワード再設定[メール送信](処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中
  #   有効なパラメータ（未ロック, ロック中, メール未確認, メールアドレス変更中）, 無効なパラメータ
  describe 'POST #create' do
    subject { post create_user_password_path, params: { user: attributes } }
    let_it_be(:send_user_unlocked)      { FactoryBot.create(:user) }
    let_it_be(:send_user_locked)        { FactoryBot.create(:user, :locked) }
    let_it_be(:send_user_unconfirmed)   { FactoryBot.create(:user, :unconfirmed) }
    let_it_be(:send_user_email_changed) { FactoryBot.create(:user, :email_changed) }
    let_it_be(:not_user)                { FactoryBot.attributes_for(:user) }
    let(:valid_attributes)   { { email: send_user.email } }
    let(:invalid_attributes) { { email: not_user[:email] } }

    # テスト内容
    shared_examples_for 'OK' do
      let(:url) { "http://#{Settings['base_domain']}#{edit_user_password_path}" }
      it 'メールが送信される' do
        subject
        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect(ActionMailer::Base.deliveries[0].subject).to eq(get_subject('devise.mailer.reset_password_instructions.subject')) # パスワード再設定方法のお知らせ
        expect(ActionMailer::Base.deliveries[0].html_part.body).to include(url)
        expect(ActionMailer::Base.deliveries[0].text_part.body).to include(url)
      end
    end
    shared_examples_for 'NG' do
      it 'メールが送信されない' do
        expect { subject }.to change(ActionMailer::Base.deliveries, :count).by(0)
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]有効なパラメータ（未ロック）' do
      let(:send_user)  { send_user_unlocked }
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      it_behaves_like 'ToLogin', nil, 'devise.passwords.send_instructions'
    end
    shared_examples_for '[ログイン中]有効なパラメータ（未ロック）' do
      let(:send_user)  { send_user_unlocked }
      let(:attributes) { valid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]有効なパラメータ（ロック中）' do # NOTE: ロック中も出来ても良さそう
      let(:send_user)  { send_user_locked }
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      it_behaves_like 'ToLogin', nil, 'devise.passwords.send_instructions'
    end
    shared_examples_for '[ログイン中]有効なパラメータ（ロック中）' do
      let(:send_user)  { send_user_locked }
      let(:attributes) { valid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]有効なパラメータ（メール未確認）' do # NOTE: メール未確認も出来ても良さそう
      let(:send_user)  { send_user_unconfirmed }
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      it_behaves_like 'ToLogin', nil, 'devise.passwords.send_instructions'
    end
    shared_examples_for '[ログイン中]有効なパラメータ（メール未確認）' do
      let(:send_user)  { send_user_unconfirmed }
      let(:attributes) { valid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]有効なパラメータ（メールアドレス変更中）' do # NOTE: メールアドレス変更中も出来ても良さそう
      let(:send_user)  { send_user_email_changed }
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      it_behaves_like 'ToLogin', nil, 'devise.passwords.send_instructions'
    end
    shared_examples_for '[ログイン中]有効なパラメータ（メールアドレス変更中）' do
      let(:send_user)  { send_user_email_changed }
      let(:attributes) { valid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToError', 'errors.messages.not_found'
    end
    shared_examples_for '[ログイン中]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]有効なパラメータ（未ロック）'
      it_behaves_like '[未ログイン]有効なパラメータ（ロック中）'
      it_behaves_like '[未ログイン]有効なパラメータ（メール未確認）'
      it_behaves_like '[未ログイン]有効なパラメータ（メールアドレス変更中）'
      it_behaves_like '[未ログイン]無効なパラメータ'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中]有効なパラメータ（未ロック）'
      it_behaves_like '[ログイン中]有効なパラメータ（ロック中）'
      it_behaves_like '[ログイン中]有効なパラメータ（メール未確認）'
      it_behaves_like '[ログイン中]有効なパラメータ（メールアドレス変更中）'
      it_behaves_like '[ログイン中]無効なパラメータ'
    end
  end

  # GET /users/password パスワード再設定
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中
  #   トークン: 期限内（未ロック, ロック中, メール未確認, メールアドレス変更中）, 期限切れ, 存在しない, ない
  describe 'GET #edit' do
    subject { get edit_user_password_path(reset_password_token: reset_password_token) }

    # テストケース
    shared_examples_for '[未ログイン]トークンが期限内（未ロック）' do
      include_context 'パスワードリセットトークン作成', true
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[ログイン中]トークンが期限内（未ロック）' do
      include_context 'パスワードリセットトークン作成', true
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]トークンが期限内（ロック中）' do # NOTE: ロック中も出来ても良さそう
      include_context 'パスワードリセットトークン作成', true, true
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[ログイン中]トークンが期限内（ロック中）' do
      include_context 'パスワードリセットトークン作成', true, true
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]トークンが期限内（メール未確認）' do # NOTE: メール未確認も出来ても良さそう
      include_context 'パスワードリセットトークン作成', true, false, true
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[ログイン中]トークンが期限内（メール未確認）' do
      include_context 'パスワードリセットトークン作成', true, false, true
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]トークンが期限内（メールアドレス変更中）' do # NOTE: メールアドレス変更中も出来ても良さそう
      include_context 'パスワードリセットトークン作成', true, false, true, true
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[ログイン中]トークンが期限内（メールアドレス変更中）' do
      include_context 'パスワードリセットトークン作成', true, false, true, true
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]トークンが期限切れ' do
      include_context 'パスワードリセットトークン作成', false
      it_behaves_like 'ToNew', 'activerecord.errors.models.user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[ログイン中]トークンが期限切れ' do
      include_context 'パスワードリセットトークン作成', false
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]トークンが存在しない' do
      let(:reset_password_token) { NOT_TOKEN }
      it_behaves_like 'ToNew', 'activerecord.errors.models.user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[ログイン中]トークンが存在しない' do
      let(:reset_password_token) { NOT_TOKEN }
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]トークンがない' do
      let(:reset_password_token) { nil }
      it_behaves_like 'ToLogin', 'devise.passwords.no_token', nil
    end
    shared_examples_for '[ログイン中]トークンがない' do
      let(:reset_password_token) { nil }
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]トークンが期限内（未ロック）'
      it_behaves_like '[未ログイン]トークンが期限内（ロック中）'
      it_behaves_like '[未ログイン]トークンが期限内（メール未確認）'
      it_behaves_like '[未ログイン]トークンが期限内（メールアドレス変更中）'
      it_behaves_like '[未ログイン]トークンが期限切れ'
      it_behaves_like '[未ログイン]トークンが存在しない'
      it_behaves_like '[未ログイン]トークンがない'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中]トークンが期限内（未ロック）'
      it_behaves_like '[ログイン中]トークンが期限内（ロック中）'
      it_behaves_like '[ログイン中]トークンが期限内（メール未確認）'
      it_behaves_like '[ログイン中]トークンが期限内（メールアドレス変更中）'
      it_behaves_like '[ログイン中]トークンが期限切れ'
      it_behaves_like '[ログイン中]トークンが存在しない'
      it_behaves_like '[ログイン中]トークンがない'
    end
  end

  # PUT /users/password パスワード再設定(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中
  #   トークン: 期限内（未ロック, ロック中, メール未確認, メールアドレス変更中）, 期限切れ, 存在しない, ない
  #   有効なパラメータ, 無効なパラメータ
  describe 'PUT #update' do
    subject { put update_user_password_path, params: { user: attributes } }
    let(:new_password) { Faker::Internet.password(min_length: 8) }
    let(:valid_attributes)   { { reset_password_token: reset_password_token, password: new_password, password_confirmation: new_password } }
    let(:invalid_attributes) { { reset_password_token: reset_password_token, password: nil, password_confirmation: nil } }
    let(:current_user) { User.find(send_user.id) }

    # テスト内容
    shared_examples_for 'OK' do |change_confirmed = false|
      let!(:start_time) { Time.current.floor }
      it "パスワードリセット送信日時がなし#{'・メールアドレス確認日時が現在日時' if change_confirmed}に変更される。メールが送信される" do
        subject
        expect(current_user.reset_password_sent_at).to be_nil
        expect(current_user.confirmed_at).to change_confirmed ? be_between(start_time, Time.current) : eq(send_user.confirmed_at)
        expect(current_user.locked_at).to be_nil # NOTE: ロック中の場合は解除する
        expect(current_user.failed_attempts).to eq(0)

        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect(ActionMailer::Base.deliveries[0].subject).to eq(get_subject('devise.mailer.password_change.subject')) # パスワード変更完了のお知らせ
      end
    end
    shared_examples_for 'NG' do
      it 'パスワードリセット送信日時が変更されない。メールが送信されない' do
        subject
        expect(current_user.reset_password_sent_at).to eq(send_user.reset_password_sent_at)

        expect(ActionMailer::Base.deliveries.count).to eq(0)
      end
    end

    # テストケース
    shared_examples_for '[未ログイン][期限内]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      it_behaves_like 'ToTop', nil, 'devise.passwords.updated'
    end
    shared_examples_for '[未ログイン][期限内（メール未確認）]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      # it_behaves_like 'OK
      it_behaves_like 'OK', true
      # it_behaves_like 'ToLogin', 'devise.failure.unconfirmed', 'devise.passwords.updated'
      it_behaves_like 'ToTop', nil, 'devise.passwords.updated'
    end
    shared_examples_for '[未ログイン][期限内（メールアドレス変更中）]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      it_behaves_like 'ToLogin', 'devise.failure.unconfirmed', 'devise.passwords.updated'
    end
    shared_examples_for '[ログイン中][期限内/期限切れ]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン][期限切れ]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNew', 'activerecord.errors.models.user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[未ログイン][存在しない/ない]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      # it_behaves_like 'NG' # NOTE: トークンが存在しない為、送信日時がない
      it_behaves_like 'ToNew', 'activerecord.errors.models.user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[ログイン中][存在しない/ない]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      # it_behaves_like 'NG' # NOTE: トークンが存在しない為、送信日時がない
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン][期限内]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToError', 'activerecord.errors.models.user.attributes.password.blank'
    end
    shared_examples_for '[ログイン中][期限内/期限切れ]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン][期限切れ]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNew', 'activerecord.errors.models.user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[未ログイン][存在しない/ない]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      # it_behaves_like 'NG' # NOTE: トークンが存在しない為、送信日時がない
      it_behaves_like 'ToNew', 'activerecord.errors.models.user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[ログイン中][存在しない/ない]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      # it_behaves_like 'NG' # NOTE: トークンが存在しない為、送信日時がない
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end

    shared_examples_for '[未ログイン]トークンが期限内（未ロック）' do
      include_context 'パスワードリセットトークン作成', true
      it_behaves_like '[未ログイン][期限内]有効なパラメータ'
      it_behaves_like '[未ログイン][期限内]無効なパラメータ'
    end
    shared_examples_for '[ログイン中]トークンが期限内（未ロック）' do
      include_context 'パスワードリセットトークン作成', true
      it_behaves_like '[ログイン中][期限内/期限切れ]有効なパラメータ'
      it_behaves_like '[ログイン中][期限内/期限切れ]無効なパラメータ'
    end
    shared_examples_for '[未ログイン]トークンが期限内（ロック中）' do
      include_context 'パスワードリセットトークン作成', true, true
      it_behaves_like '[未ログイン][期限内]有効なパラメータ'
      it_behaves_like '[未ログイン][期限内]無効なパラメータ'
    end
    shared_examples_for '[ログイン中]トークンが期限内（ロック中）' do
      include_context 'パスワードリセットトークン作成', true, true
      it_behaves_like '[ログイン中][期限内/期限切れ]有効なパラメータ'
      it_behaves_like '[ログイン中][期限内/期限切れ]無効なパラメータ'
    end
    shared_examples_for '[未ログイン]トークンが期限内（メール未確認）' do
      include_context 'パスワードリセットトークン作成', true, false, true
      it_behaves_like '[未ログイン][期限内（メール未確認）]有効なパラメータ'
      it_behaves_like '[未ログイン][期限内]無効なパラメータ'
    end
    shared_examples_for '[ログイン中]トークンが期限内（メール未確認）' do
      include_context 'パスワードリセットトークン作成', true, false, true
      it_behaves_like '[ログイン中][期限内/期限切れ]有効なパラメータ'
      it_behaves_like '[ログイン中][期限内/期限切れ]無効なパラメータ'
    end
    shared_examples_for '[未ログイン]トークンが期限内（メールアドレス変更中）' do
      include_context 'パスワードリセットトークン作成', true, false, true, true
      it_behaves_like '[未ログイン][期限内（メールアドレス変更中）]有効なパラメータ'
      it_behaves_like '[未ログイン][期限内]無効なパラメータ'
    end
    shared_examples_for '[ログイン中]トークンが期限内（メールアドレス変更中）' do
      include_context 'パスワードリセットトークン作成', true, false, true, true
      it_behaves_like '[ログイン中][期限内/期限切れ]有効なパラメータ'
      it_behaves_like '[ログイン中][期限内/期限切れ]無効なパラメータ'
    end
    shared_examples_for '[未ログイン]トークンが期限切れ' do
      include_context 'パスワードリセットトークン作成', false
      it_behaves_like '[未ログイン][期限切れ]有効なパラメータ'
      it_behaves_like '[未ログイン][期限切れ]無効なパラメータ'
    end
    shared_examples_for '[ログイン中]トークンが期限切れ' do
      include_context 'パスワードリセットトークン作成', false
      it_behaves_like '[ログイン中][期限内/期限切れ]有効なパラメータ'
      it_behaves_like '[ログイン中][期限内/期限切れ]無効なパラメータ'
    end
    shared_examples_for '[未ログイン]トークンが存在しない' do
      let(:reset_password_token) { NOT_TOKEN }
      it_behaves_like '[未ログイン][存在しない/ない]有効なパラメータ'
      it_behaves_like '[未ログイン][存在しない/ない]無効なパラメータ'
    end
    shared_examples_for '[ログイン中]トークンが存在しない' do
      let(:reset_password_token) { NOT_TOKEN }
      it_behaves_like '[ログイン中][存在しない/ない]有効なパラメータ'
      it_behaves_like '[ログイン中][存在しない/ない]無効なパラメータ'
    end
    shared_examples_for '[未ログイン]トークンがない' do
      let(:reset_password_token) { nil }
      it_behaves_like '[未ログイン][存在しない/ない]有効なパラメータ'
      it_behaves_like '[未ログイン][存在しない/ない]無効なパラメータ'
    end
    shared_examples_for '[ログイン中]トークンがない' do
      let(:reset_password_token) { nil }
      it_behaves_like '[ログイン中][存在しない/ない]有効なパラメータ'
      it_behaves_like '[ログイン中][存在しない/ない]無効なパラメータ'
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]トークンが期限内（未ロック）'
      it_behaves_like '[未ログイン]トークンが期限内（ロック中）'
      it_behaves_like '[未ログイン]トークンが期限内（メール未確認）'
      it_behaves_like '[未ログイン]トークンが期限内（メールアドレス変更中）'
      it_behaves_like '[未ログイン]トークンが期限切れ'
      it_behaves_like '[未ログイン]トークンが存在しない'
      it_behaves_like '[未ログイン]トークンがない'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中]トークンが期限内（未ロック）'
      it_behaves_like '[ログイン中]トークンが期限内（ロック中）'
      it_behaves_like '[ログイン中]トークンが期限内（メール未確認）'
      it_behaves_like '[ログイン中]トークンが期限内（メールアドレス変更中）'
      it_behaves_like '[ログイン中]トークンが期限切れ'
      it_behaves_like '[ログイン中]トークンが存在しない'
      it_behaves_like '[ログイン中]トークンがない'
    end
  end
end
