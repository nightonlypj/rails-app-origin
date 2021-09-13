require 'rails_helper'

RSpec.describe 'Users::Passwords', type: :request do
  # GET /users/password/new パスワード再設定[メール送信]
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中
  describe 'GET #new' do
    subject { get new_user_password_path }

    # テスト内容
    shared_examples_for 'ToOK' do
      it 'HTTPステータスが200' do
        is_expected.to eq(200)
      end
    end
    shared_examples_for 'ToTop' do |alert, notice|
      it 'トップページにリダイレクトする' do
        is_expected.to redirect_to(root_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    context '未ログイン' do
      it_behaves_like 'ToOK'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
  end

  # POST /users/password/new パスワード再設定[メール送信](処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中
  #   有効なパラメータ（未ロック, ロック中, メール未確認）, 無効なパラメータ
  describe 'POST #create' do
    subject { post create_user_password_path, params: { user: attributes } }
    let(:send_user_unlocked)    { FactoryBot.create(:user) }
    let(:send_user_locked)      { FactoryBot.create(:user_locked) }
    let(:send_user_unconfirmed) { FactoryBot.create(:user_unconfirmed) }
    let(:not_user)              { FactoryBot.attributes_for(:user) }
    let(:valid_attributes)   { { email: send_user.email } }
    let(:invalid_attributes) { { email: not_user[:email] } }

    # テスト内容
    shared_examples_for 'OK' do
      it 'メールが送信される' do
        subject
        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect(ActionMailer::Base.deliveries[0].subject).to eq(get_subject('devise.mailer.reset_password_instructions.subject')) # パスワード再設定方法のお知らせ
      end
    end
    shared_examples_for 'NG' do
      it 'メールが送信されない' do
        expect { subject }.to change(ActionMailer::Base.deliveries, :count).by(0)
      end
    end

    shared_examples_for 'ToError' do |error_msg|
      it 'HTTPステータスが200。対象のエラーメッセージが含まれる' do # Tips: 再入力
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
    shared_examples_for '[未ログイン]有効なパラメータ（ロック中）' do # Tips: ロック中も出来ても良さそう
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
    shared_examples_for '[未ログイン]有効なパラメータ（メール未確認）' do # Tips: メール未確認も出来ても良さそう
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
      it_behaves_like '[未ログイン]無効なパラメータ'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中]有効なパラメータ（未ロック）'
      it_behaves_like '[ログイン中]有効なパラメータ（ロック中）'
      it_behaves_like '[ログイン中]有効なパラメータ（メール未確認）'
      it_behaves_like '[ログイン中]無効なパラメータ'
    end
  end

  # GET /users/password/edit パスワード再設定
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中
  #   トークン: 期限内（未ロック, ロック中, メール未確認）, 期限切れ, 存在しない, ない
  describe 'GET #edit' do
    subject { get edit_user_password_path(reset_password_token: reset_password_token) }

    # テスト内容
    shared_examples_for 'ToOK' do
      it 'HTTPステータスが200' do
        is_expected.to eq(200)
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

    # テストケース
    shared_examples_for '[未ログイン]トークンが期限内（未ロック）' do
      include_context 'パスワードリセットトークン作成', true
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[ログイン中]トークンが期限内（未ロック）' do
      include_context 'パスワードリセットトークン作成', true
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]トークンが期限内（ロック中）' do # Tips: ロック中も出来ても良さそう
      include_context 'パスワードリセットトークン作成', true, true
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[ログイン中]トークンが期限内（ロック中）' do
      include_context 'パスワードリセットトークン作成', true, true
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]トークンが期限内（メール未確認）' do # Tips: メール未確認も出来ても良さそう
      include_context 'パスワードリセットトークン作成', true, false, true
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[ログイン中]トークンが期限内（メール未確認）' do
      include_context 'パスワードリセットトークン作成', true, false, true
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
      it_behaves_like '[未ログイン]トークンが期限切れ'
      it_behaves_like '[未ログイン]トークンが存在しない'
      it_behaves_like '[未ログイン]トークンがない'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中]トークンが期限内（未ロック）'
      it_behaves_like '[ログイン中]トークンが期限内（ロック中）'
      it_behaves_like '[ログイン中]トークンが期限内（メール未確認）'
      it_behaves_like '[ログイン中]トークンが期限切れ'
      it_behaves_like '[ログイン中]トークンが存在しない'
      it_behaves_like '[ログイン中]トークンがない'
    end
  end

  # PUT(PATCH) /users/password パスワード再設定(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中
  #   トークン: 期限内（未ロック, ロック中, メール未確認）, 期限切れ, 存在しない, ない
  #   有効なパラメータ, 無効なパラメータ
  describe 'PUT #update' do
    subject { put update_user_password_path, params: { user: attributes } }
    let(:new_password) { Faker::Internet.password(min_length: 8) }
    let(:valid_attributes)   { { reset_password_token: reset_password_token, password: new_password, password_confirmation: new_password } }
    let(:invalid_attributes) { { reset_password_token: reset_password_token, password: new_password, password_confirmation: nil } }

    # テスト内容
    shared_examples_for 'OK' do |check_confirmed = false|
      let!(:start_time) { Time.current.floor }
      it "パスワードリセット送信日時がなし#{'・メールアドレス確認日時が現在日時' if check_confirmed}に変更される。メールが送信される" do
        subject
        expect(User.find(send_user.id).reset_password_sent_at).to be_nil
        expect(User.find(send_user.id).confirmed_at).to be_between(start_time, Time.current) if check_confirmed

        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect(ActionMailer::Base.deliveries[0].subject).to eq(get_subject('devise.mailer.password_change.subject')) # パスワード変更完了のお知らせ
      end
    end
    shared_examples_for 'NG' do
      it 'パスワードリセット送信日時が変更されない。メールが送信されない' do
        subject
        expect(User.find(send_user.id).reset_password_sent_at).to eq(send_user.reset_password_sent_at)

        expect(ActionMailer::Base.deliveries.count).to eq(0)
      end
    end

    shared_examples_for 'ToError' do |error_msg|
      it 'HTTPステータスが200。対象のエラーメッセージが含まれる' do # Tips: 再入力
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

    # テストケース
    shared_examples_for '[未ログイン][期限内]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      it_behaves_like 'ToTop', nil, 'devise.passwords.updated'
    end
    shared_examples_for '[未ログイン][期限内（メール未確認）]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      # it_behaves_like 'OK', true # Tips: 確認済みに変更して、ログイ中にしたい
      it_behaves_like 'ToLogin', 'devise.failure.unconfirmed', 'devise.passwords.updated'
      # it_behaves_like 'ToTop', nil, 'devise.passwords.updated'
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
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、送信日時がない
      it_behaves_like 'ToNew', 'activerecord.errors.models.user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[ログイン中][存在しない/ない]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、送信日時がない
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン][期限内]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToError', 'activerecord.errors.models.user.attributes.password_confirmation.confirmation'
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
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、送信日時がない
      it_behaves_like 'ToNew', 'activerecord.errors.models.user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[ログイン中][存在しない/ない]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、送信日時がない
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
      it_behaves_like '[未ログイン]トークンが期限切れ'
      it_behaves_like '[未ログイン]トークンが存在しない'
      it_behaves_like '[未ログイン]トークンがない'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中]トークンが期限内（未ロック）'
      it_behaves_like '[ログイン中]トークンが期限内（ロック中）'
      it_behaves_like '[ログイン中]トークンが期限内（メール未確認）'
      it_behaves_like '[ログイン中]トークンが期限切れ'
      it_behaves_like '[ログイン中]トークンが存在しない'
      it_behaves_like '[ログイン中]トークンがない'
    end
  end
end
