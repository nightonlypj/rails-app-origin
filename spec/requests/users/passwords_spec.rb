require 'rails_helper'

RSpec.describe 'Users::Passwords', type: :request do
  # GET /users/password/new パスワード再設定[メール送信]
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  describe 'GET #new' do
    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get new_user_password_path
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToTop' do |alert, notice|
      it 'トップページにリダイレクト' do
        get new_user_password_path
        expect(response).to redirect_to(root_path)
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
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
  end

  # POST /users/password/new パスワード再設定[メール送信](処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   有効なパラメータ, 無効なパラメータ → 事前にデータ作成
  describe 'POST #create' do
    let!(:send_user) { FactoryBot.create(:user) }
    let!(:valid_attributes) { { email: send_user.email } }
    let!(:invalid_attributes) { { email: nil } }

    # テスト内容
    shared_examples_for 'OK' do
      it 'メールが送信される' do
        before_count = ActionMailer::Base.deliveries.count
        post create_user_password_path, params: { user: attributes }
        expect(ActionMailer::Base.deliveries.count).to eq(before_count + 1) # パスワード再設定方法のお知らせ
      end
    end
    shared_examples_for 'NG' do
      it 'メールが送信されない' do
        before_count = ActionMailer::Base.deliveries.count
        post create_user_password_path, params: { user: attributes }
        expect(ActionMailer::Base.deliveries.count).to eq(before_count)
      end
    end

    shared_examples_for 'ToError' do
      it '成功ステータス' do # Tips: 再入力
        post create_user_password_path, params: { user: attributes }
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToTop' do |alert, notice|
      it 'トップページにリダイレクト' do
        post create_user_password_path, params: { user: attributes }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToLogin' do |alert, notice|
      it 'ログインにリダイレクト' do
        post create_user_password_path, params: { user: attributes }
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      it_behaves_like 'ToLogin', nil, 'devise.passwords.send_instructions'
    end
    shared_examples_for '[ログイン中/削除予約済み]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToError'
    end
    shared_examples_for '[ログイン中/削除予約済み]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]有効なパラメータ'
      it_behaves_like '[未ログイン]無効なパラメータ'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ'
      it_behaves_like '[ログイン中/削除予約済み]無効なパラメータ'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ'
      it_behaves_like '[ログイン中/削除予約済み]無効なパラメータ'
    end
  end

  # GET /users/password/edit パスワード再設定
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   トークン: 期限内, 期限切れ, 存在しない, ない → データ作成
  describe 'GET #edit' do
    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get edit_user_password_path(reset_password_token: reset_password_token)
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToTop' do |alert, notice|
      it 'トップページにリダイレクト' do
        get edit_user_password_path(reset_password_token: reset_password_token)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToLogin' do |alert, notice|
      it 'ログインにリダイレクト' do
        get edit_user_password_path(reset_password_token: reset_password_token)
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToNew' do |alert, notice|
      it 'パスワード再設定[メール送信]にリダイレクト' do
        get edit_user_password_path(reset_password_token: reset_password_token)
        expect(response).to redirect_to(new_user_password_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]トークンが期限内' do
      include_context 'パスワードリセットトークン作成', true
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[ログイン中/削除予約済み]トークンが期限内' do
      include_context 'パスワードリセットトークン作成', true
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]トークンが期限切れ' do
      include_context 'パスワードリセットトークン作成', false
      it_behaves_like 'ToNew', 'activerecord.errors.models.user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[ログイン中/削除予約済み]トークンが期限切れ' do
      include_context 'パスワードリセットトークン作成', false
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]トークンが存在しない' do
      let!(:reset_password_token) { NOT_TOKEN }
      it_behaves_like 'ToNew', 'activerecord.errors.models.user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[ログイン中/削除予約済み]トークンが存在しない' do
      let!(:reset_password_token) { NOT_TOKEN }
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]トークンがない' do
      let!(:reset_password_token) { NO_TOKEN }
      it_behaves_like 'ToLogin', 'devise.passwords.no_token', nil
    end
    shared_examples_for '[ログイン中/削除予約済み]トークンがない' do
      let!(:reset_password_token) { NO_TOKEN }
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]トークンが期限内'
      it_behaves_like '[未ログイン]トークンが期限切れ'
      it_behaves_like '[未ログイン]トークンが存在しない'
      it_behaves_like '[未ログイン]トークンがない'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中/削除予約済み]トークンが期限内'
      it_behaves_like '[ログイン中/削除予約済み]トークンが期限切れ'
      it_behaves_like '[ログイン中/削除予約済み]トークンが存在しない'
      it_behaves_like '[ログイン中/削除予約済み]トークンがない'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[ログイン中/削除予約済み]トークンが期限内'
      it_behaves_like '[ログイン中/削除予約済み]トークンが期限切れ'
      it_behaves_like '[ログイン中/削除予約済み]トークンが存在しない'
      it_behaves_like '[ログイン中/削除予約済み]トークンがない'
    end
  end

  # PUT(PATCH) /users/password パスワード再設定(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   トークン: 期限内, 期限切れ, 存在しない, ない → データ作成
  #   有効なパラメータ, 無効なパラメータ → 事前にデータ作成
  describe 'PUT #update' do
    let!(:valid_attributes) { FactoryBot.attributes_for(:user) }
    let!(:invalid_attributes) { FactoryBot.attributes_for(:user, password: nil) }

    # テスト内容
    shared_examples_for 'OK' do
      it 'パスワードリセット送信日時がなしに変更される' do
        put update_user_password_path, params: { user: attributes.merge({ reset_password_token: reset_password_token }) }
        expect(User.find(@send_user.id).reset_password_sent_at).to be_nil
      end
      it 'メールが送信される' do
        before_count = ActionMailer::Base.deliveries.count
        put update_user_password_path, params: { user: attributes.merge({ reset_password_token: reset_password_token }) }
        expect(ActionMailer::Base.deliveries.count).to eq(before_count + 1) # パスワード変更完了のお知らせ
      end
    end
    shared_examples_for 'NG' do
      it 'パスワードリセット送信日時が変更されない' do
        put update_user_password_path, params: { user: attributes.merge({ reset_password_token: reset_password_token }) }
        expect(User.find(@send_user.id).reset_password_sent_at).to eq(@send_user.reset_password_sent_at)
      end
      it 'メールが送信されない' do
        before_count = ActionMailer::Base.deliveries.count
        put update_user_password_path, params: { user: attributes.merge({ reset_password_token: reset_password_token }) }
        expect(ActionMailer::Base.deliveries.count).to eq(before_count)
      end
    end

    shared_examples_for 'ToError' do
      it '成功ステータス' do # Tips: 再入力
        put update_user_password_path, params: { user: attributes.merge({ reset_password_token: reset_password_token }) }
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToTop' do |alert, notice|
      it 'トップページにリダイレクト' do
        put update_user_password_path, params: { user: attributes.merge({ reset_password_token: reset_password_token }) }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToNew' do |alert, notice|
      it 'パスワード再設定[メール送信]にリダイレクト' do
        put update_user_password_path, params: { user: attributes.merge({ reset_password_token: reset_password_token }) }
        expect(response).to redirect_to(new_user_password_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[未ログイン][期限内]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      it_behaves_like 'ToTop', nil, 'devise.passwords.updated'
    end
    shared_examples_for '[ログイン中/削除予約済み][期限内/期限切れ]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン][期限切れ]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNew', 'activerecord.errors.models.user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[未ログイン][存在しない/ない]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、送信日時がない
      it_behaves_like 'ToNew', 'activerecord.errors.models.user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[ログイン中/削除予約済み][存在しない/ない]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、送信日時がない
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン][期限内]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToError'
    end
    shared_examples_for '[ログイン中/削除予約済み][期限内/期限切れ]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン][期限切れ]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNew', 'activerecord.errors.models.user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[未ログイン][存在しない/ない]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、送信日時がない
      it_behaves_like 'ToNew', 'activerecord.errors.models.user.attributes.reset_password_token.invalid', nil
    end
    shared_examples_for '[ログイン中/削除予約済み][存在しない/ない]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、送信日時がない
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end

    shared_examples_for '[未ログイン]トークンが期限内' do
      include_context 'パスワードリセットトークン作成', true
      it_behaves_like '[未ログイン][期限内]有効なパラメータ'
      it_behaves_like '[未ログイン][期限内]無効なパラメータ'
    end
    shared_examples_for '[ログイン中/削除予約済み]トークンが期限内' do
      include_context 'パスワードリセットトークン作成', true
      it_behaves_like '[ログイン中/削除予約済み][期限内/期限切れ]有効なパラメータ'
      it_behaves_like '[ログイン中/削除予約済み][期限内/期限切れ]無効なパラメータ'
    end
    shared_examples_for '[未ログイン]トークンが期限切れ' do
      include_context 'パスワードリセットトークン作成', false
      it_behaves_like '[未ログイン][期限切れ]有効なパラメータ'
      it_behaves_like '[未ログイン][期限切れ]無効なパラメータ'
    end
    shared_examples_for '[ログイン中/削除予約済み]トークンが期限切れ' do
      include_context 'パスワードリセットトークン作成', false
      it_behaves_like '[ログイン中/削除予約済み][期限内/期限切れ]有効なパラメータ'
      it_behaves_like '[ログイン中/削除予約済み][期限内/期限切れ]無効なパラメータ'
    end
    shared_examples_for '[未ログイン]トークンが存在しない' do
      let!(:reset_password_token) { NOT_TOKEN }
      it_behaves_like '[未ログイン][存在しない/ない]有効なパラメータ'
      it_behaves_like '[未ログイン][存在しない/ない]無効なパラメータ'
    end
    shared_examples_for '[ログイン中/削除予約済み]トークンが存在しない' do
      let!(:reset_password_token) { NOT_TOKEN }
      it_behaves_like '[ログイン中/削除予約済み][存在しない/ない]有効なパラメータ'
      it_behaves_like '[ログイン中/削除予約済み][存在しない/ない]無効なパラメータ'
    end
    shared_examples_for '[未ログイン]トークンがない' do
      let!(:reset_password_token) { NO_TOKEN }
      it_behaves_like '[未ログイン][存在しない/ない]有効なパラメータ'
      it_behaves_like '[未ログイン][存在しない/ない]無効なパラメータ'
    end
    shared_examples_for '[ログイン中/削除予約済み]トークンがない' do
      let!(:reset_password_token) { NO_TOKEN }
      it_behaves_like '[ログイン中/削除予約済み][存在しない/ない]有効なパラメータ'
      it_behaves_like '[ログイン中/削除予約済み][存在しない/ない]無効なパラメータ'
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]トークンが期限内'
      it_behaves_like '[未ログイン]トークンが期限切れ'
      it_behaves_like '[未ログイン]トークンが存在しない'
      it_behaves_like '[未ログイン]トークンがない'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中/削除予約済み]トークンが期限内'
      it_behaves_like '[ログイン中/削除予約済み]トークンが期限切れ'
      it_behaves_like '[ログイン中/削除予約済み]トークンが存在しない'
      it_behaves_like '[ログイン中/削除予約済み]トークンがない'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[ログイン中/削除予約済み]トークンが期限内'
      it_behaves_like '[ログイン中/削除予約済み]トークンが期限切れ'
      it_behaves_like '[ログイン中/削除予約済み]トークンが存在しない'
      it_behaves_like '[ログイン中/削除予約済み]トークンがない'
    end
  end
end
