require 'rails_helper'

RSpec.describe 'Users::Confirmations', type: :request do
  # テスト内容（共通）
  shared_examples_for 'ToNew' do |alert, notice|
    it 'メールアドレス確認[メール再送]にリダイレクトする' do
      is_expected.to redirect_to(new_user_confirmation_path)
      expect(flash[:alert]).to alert.present? ? eq(get_locale(alert)) : be_nil
      expect(flash[:notice]).to notice.present? ? eq(get_locale(notice)) : be_nil
    end
  end

  # GET /users/confirmation/resend メールアドレス確認[メール再送]
  # テストパターン
  #   未ログイン, ログイン中（メール確認済み, メールアドレス変更中）
  describe 'GET #new' do
    subject { get new_user_confirmation_path }

    # テストケース
    if Settings.api_only_mode
      it_behaves_like 'ToNG(html)', 404
      next
    end

    context '未ログイン' do
      it_behaves_like 'ToOK[status]'
    end
    context 'ログイン中（メール確認済み）' do
      include_context 'ログイン処理'
      it_behaves_like 'ToOK[status]' # NOTE: リンクないけど、送れても良さそう
    end
    context 'ログイン中（メールアドレス変更中）' do
      include_context 'ログイン処理', :email_changed
      it_behaves_like 'ToOK[status]' # NOTE: ログイン中でも再送したい
    end
  end

  # POST /users/confirmation/resend メールアドレス確認[メール再送](処理)
  # テストパターン
  #   未ログイン, ログイン中
  #   有効なパラメータ（メール未確認, メール確認済み, メールアドレス変更中）, 無効なパラメータ
  describe 'POST #create' do
    subject { post create_user_confirmation_path, params: { user: attributes } }
    let_it_be(:send_user_unconfirmed)   { FactoryBot.create(:user, :unconfirmed) }
    let_it_be(:send_user_confirmed)     { FactoryBot.create(:user) }
    let_it_be(:send_user_email_changed) { FactoryBot.create(:user, :email_changed) }
    let_it_be(:not_user)                { FactoryBot.attributes_for(:user) }
    let(:valid_attributes)   { { email: send_user.email } }
    let(:invalid_attributes) { { email: not_user[:email] } }

    # テスト内容
    shared_examples_for 'OK' do
      let(:url) { "http://#{Settings.base_domain}#{user_confirmation_path}" }
      it 'メールが送信される' do
        subject
        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect(ActionMailer::Base.deliveries[0].subject).to eq(get_subject('devise.mailer.confirmation_instructions.subject')) # メールアドレス確認のお願い
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
    if Settings.api_only_mode
      let(:send_user)  { send_user_unconfirmed }
      let(:attributes) { valid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG(html)', 404
      next
    end

    shared_examples_for '[*]有効なパラメータ（メール未確認）' do # NOTE: ログイン中も出来ても良さそう
      let(:send_user)  { send_user_unconfirmed }
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      it_behaves_like 'ToLogin', nil, 'devise.confirmations.send_instructions'
    end
    shared_examples_for '[*]有効なパラメータ（メール確認済み）' do
      let(:send_user)  { send_user_confirmed }
      let(:attributes) { valid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToError', 'errors.messages.already_confirmed'
    end
    shared_examples_for '[*]有効なパラメータ（メールアドレス変更中）' do # NOTE: ログイン中でも再送したい
      let(:send_user)  { send_user_email_changed }
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      it_behaves_like 'ToLogin', nil, 'devise.confirmations.send_instructions'
    end
    shared_examples_for '[*]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToError', 'errors.messages.not_found'
    end

    shared_examples_for '[*]' do
      it_behaves_like '[*]有効なパラメータ（メール未確認）'
      it_behaves_like '[*]有効なパラメータ（メール確認済み）'
      it_behaves_like '[*]有効なパラメータ（メールアドレス変更中）'
      it_behaves_like '[*]無効なパラメータ'
    end

    context '未ログイン' do
      it_behaves_like '[*]'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[*]'
    end
  end

  # GET /users/confirmation メールアドレス確認(処理)
  # テストパターン
  #   未ログイン, ログイン中
  #   トークン: 期限内, 期限切れ, 存在しない, ない
  #   確認日時: ない（未確認）, 確認送信日時より前（未確認）, 確認送信日時より後（確認済み）
  describe 'GET #show' do
    subject { get user_confirmation_path(confirmation_token:) }

    # テスト内容
    let(:current_user) { User.find(send_user.id) }
    shared_examples_for 'OK' do
      let!(:start_time) { Time.now.utc.floor }
      it '確認日時が現在日時に変更される' do
        subject
        expect(current_user.confirmed_at).to be_between(start_time, Time.now.utc)
      end
    end
    shared_examples_for 'NG' do
      it '確認日時が変更されない' do
        subject
        expect(current_user.confirmed_at).to eq(send_user.confirmed_at)
      end
    end

    # テストケース
    if Settings.api_only_mode
      let_it_be(:confirmation_sent_at) { Time.now.utc }
      include_context 'メールアドレス確認トークン作成', false, nil
      it_behaves_like 'NG'
      it_behaves_like 'ToNG(html)', 404
      next
    end

    shared_examples_for '[未ログイン][期限内]確認日時がない（未確認）' do
      include_context 'メールアドレス確認トークン作成', false, nil
      it_behaves_like 'OK'
      it_behaves_like 'ToLogin', nil, 'devise.confirmations.confirmed'
    end
    shared_examples_for '[ログイン中][期限内]確認日時がない（未確認）' do # NOTE: ログイン中も出来ても良さそう
      include_context 'メールアドレス確認トークン作成', false, nil
      it_behaves_like 'OK'
      it_behaves_like 'ToTop', nil, 'devise.confirmations.confirmed'
    end
    shared_examples_for '[*][期限切れ]確認日時がない（未確認）' do
      include_context 'メールアドレス確認トークン作成', false, nil
      it_behaves_like 'NG'
      it_behaves_like 'ToNew', 'activerecord.errors.models.user.attributes.confirmation_token.invalid', nil
    end
    shared_examples_for '[*][存在しない/ない]確認日時がない（未確認）' do
      # it_behaves_like 'NG' # NOTE: トークンが存在しない為、確認日時がない
      it_behaves_like 'ToNew', 'activerecord.errors.models.user.attributes.confirmation_token.invalid', nil
    end
    shared_examples_for '[未ログイン][期限内]確認日時が確認送信日時より前（未確認）' do
      include_context 'メールアドレス確認トークン作成', true, true
      it_behaves_like 'OK'
      it_behaves_like 'ToLogin', nil, 'devise.confirmations.confirmed'
    end
    shared_examples_for '[ログイン中][期限内]確認日時が確認送信日時より前（未確認）' do # NOTE: ログイン中も出来ても良さそう
      include_context 'メールアドレス確認トークン作成', true, true
      it_behaves_like 'OK'
      it_behaves_like 'ToTop', nil, 'devise.confirmations.confirmed'
    end
    shared_examples_for '[*][期限切れ]確認日時が確認送信日時より前（未確認）' do
      include_context 'メールアドレス確認トークン作成', true, true
      it_behaves_like 'NG'
      it_behaves_like 'ToNew', 'activerecord.errors.models.user.attributes.confirmation_token.invalid', nil
    end
    shared_examples_for '[未ログイン][期限内]確認日時が確認送信日時より後（確認済み）' do
      include_context 'メールアドレス確認トークン作成', true, false
      it_behaves_like 'NG'
      it_behaves_like 'ToLogin', 'errors.messages.already_confirmed', nil
    end
    shared_examples_for '[ログイン中][期限内]確認日時が確認送信日時より後（確認済み）' do
      include_context 'メールアドレス確認トークン作成', true, false
      it_behaves_like 'NG'
      it_behaves_like 'ToLogin', 'errors.messages.already_confirmed', nil # NOTE: ログインからトップにリダイレクト
    end
    shared_examples_for '[*][期限切れ]確認日時が確認送信日時より後（確認済み）' do
      include_context 'メールアドレス確認トークン作成', true, false
      it_behaves_like 'NG'
      it_behaves_like 'ToLogin', 'errors.messages.already_confirmed', nil
    end

    shared_examples_for '[未ログイン]トークンが期限内' do
      let_it_be(:confirmation_sent_at) { Time.now.utc }
      it_behaves_like '[未ログイン][期限内]確認日時がない（未確認）'
      it_behaves_like '[未ログイン][期限内]確認日時が確認送信日時より前（未確認）'
      it_behaves_like '[未ログイン][期限内]確認日時が確認送信日時より後（確認済み）'
    end
    shared_examples_for '[ログイン中]トークンが期限内' do
      let_it_be(:confirmation_sent_at) { Time.now.utc }
      it_behaves_like '[ログイン中][期限内]確認日時がない（未確認）'
      it_behaves_like '[ログイン中][期限内]確認日時が確認送信日時より前（未確認）'
      it_behaves_like '[ログイン中][期限内]確認日時が確認送信日時より後（確認済み）'
    end
    shared_examples_for '[*]トークンが期限切れ' do
      let_it_be(:confirmation_sent_at) { Time.now.utc - User.confirm_within - 1.hour }
      it_behaves_like '[*][期限切れ]確認日時がない（未確認）'
      it_behaves_like '[*][期限切れ]確認日時が確認送信日時より前（未確認）'
      it_behaves_like '[*][期限切れ]確認日時が確認送信日時より後（確認済み）'
    end
    shared_examples_for '[*]トークンが存在しない' do
      let(:confirmation_token) { NOT_TOKEN }
      it_behaves_like '[*][存在しない/ない]確認日時がない（未確認）'
      # it_behaves_like '[*][存在しない]確認日時が確認送信日時より前（未確認）' # NOTE: トークンが存在しない為、確認日時がない
      # it_behaves_like '[*][存在しない]確認日時が確認送信日時より後（確認済み）' # NOTE: トークンが存在しない為、確認日時がない
    end
    shared_examples_for '[*]トークンがない' do
      let(:confirmation_token) { nil }
      it_behaves_like '[*][存在しない/ない]確認日時がない（未確認）'
      # it_behaves_like '[*][ない]確認日時が確認送信日時より前（未確認）' # NOTE: トークンが存在しない為、確認日時がない
      # it_behaves_like '[*][ない]確認日時が確認送信日時より後（確認済み）' # NOTE: トークンが存在しない為、確認日時がない
    end

    shared_examples_for '[*]' do
      it_behaves_like '[*]トークンが期限切れ'
      it_behaves_like '[*]トークンが存在しない'
      it_behaves_like '[*]トークンがない'
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]トークンが期限内'
      it_behaves_like '[*]'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中]トークンが期限内'
      it_behaves_like '[*]'
    end
  end
end
