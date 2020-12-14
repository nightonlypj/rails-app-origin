require 'rails_helper'

RSpec.describe 'Users::Confirmations', type: :request do
  include_context '共通ヘッダー'
  include_context 'リクエストスペース作成'
  let!(:send_user) { FactoryBot.create(:user, confirmed_at: nil) }
  let!(:valid_attributes) { FactoryBot.attributes_for(:user, email: send_user.email) }
  let!(:invalid_attributes) { FactoryBot.attributes_for(:user, email: nil) }
  shared_context 'token作成' do |valid_flag, confirmed_blank_flag, confirmed_before_flag|
    let!(:token) { Faker::Internet.password(min_length: 20, max_length: 20) }
    before do
      @user = FactoryBot.build(:user, confirmation_token: token, confirmed_at: nil)
      @user.confirmation_sent_at = valid_flag ? Time.now.utc : Time.now.utc - @user.class.confirm_within - 1.hour
      unless confirmed_blank_flag
        @user.confirmed_at = @user.confirmation_sent_at + (confirmed_before_flag ? -1.hour : 1.hour)
        @user.unconfirmed_email = "a#{@user.email}"
      end
      @user.save!
    end
  end

  # GET /users/confirmation/new メールアドレス確認メール再送
  describe 'GET /users/confirmation/new' do
    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get new_user_confirmation_path, headers: headers
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToBase' do
      it 'ベースドメインにリダイレクト' do
        get new_user_confirmation_path, headers: headers
        expect(response).to redirect_to("//#{Settings['base_domain']}#{new_user_confirmation_path}")
      end
    end

    # テストケース
    shared_examples_for 'ベースドメイン' do
      let!(:headers) { base_headers }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '存在するサブドメイン' do
      let!(:headers) { @space_headers }
      it_behaves_like 'ToBase'
    end
    shared_examples_for '存在しないサブドメイン' do
      let!(:headers) { not_space_headers }
      it_behaves_like 'ToBase'
    end

    context '未ログイン' do
      it_behaves_like 'ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like 'ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
  end

  # POST /users/confirmation メールアドレス確認メール再送(処理)
  describe 'POST /users/confirmation' do
    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        post user_confirmation_path, params: { user: attributes }, headers: headers
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToNG' do
      it '存在しないステータス' do
        post user_confirmation_path, params: { user: attributes }, headers: headers
        expect(response).to be_not_found
      end
    end
    shared_examples_for 'ToLogin' do
      it 'ログインにリダイレクト' do
        post user_confirmation_path, params: { user: attributes }, headers: headers
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    # テストケース
    shared_examples_for '[ベースドメイン]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '[サブドメイン]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like 'ToNG'
    end
    shared_examples_for '[ベースドメイン]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'ToOK' # Tips: 再入力の為
    end
    shared_examples_for '[サブドメイン]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'ToNG'
    end

    shared_examples_for 'ベースドメイン' do
      let!(:headers) { base_headers }
      it_behaves_like '[ベースドメイン]有効なパラメータ'
      it_behaves_like '[ベースドメイン]無効なパラメータ'
    end
    shared_examples_for '存在するサブドメイン' do
      let!(:headers) { @space_headers }
      it_behaves_like '[サブドメイン]有効なパラメータ'
      it_behaves_like '[サブドメイン]無効なパラメータ'
    end
    shared_examples_for '存在しないサブドメイン' do
      let!(:headers) { not_space_headers }
      it_behaves_like '[サブドメイン]有効なパラメータ'
      it_behaves_like '[サブドメイン]無効なパラメータ'
    end

    context '未ログイン' do
      it_behaves_like 'ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like 'ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
  end

  # GET /users/confirmation メールアドレス確認(処理)
  describe 'GET /users/confirmation' do
    # テスト内容
    shared_examples_for 'OK' do
      let!(:start_time) { Time.now.utc }
      it '確認日時が現在日時に変更される' do
        get "#{user_confirmation_path}?confirmation_token=#{token}", headers: headers
        expect(User.find(@user.id).confirmed_at).to be_between(start_time, Time.now.utc)
      end
    end
    shared_examples_for 'NG' do
      it '確認日時が変更されない' do
        get "#{user_confirmation_path}?confirmation_token=#{token}", headers: headers
        expect(User.find(@user.id).confirmed_at).to eq(@user.confirmed_at)
      end
    end

    shared_examples_for 'ToTop' do
      it 'トップページにリダイレクト' do
        get "#{user_confirmation_path}?confirmation_token=#{token}", headers: headers
        expect(response).to redirect_to(root_path)
      end
    end
    shared_examples_for 'ToLogin' do
      it 'ログインにリダイレクト' do
        get "#{user_confirmation_path}?confirmation_token=#{token}", headers: headers
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    shared_examples_for 'ToNew' do
      it 'メールアドレス確認メール再送にリダイレクト' do
        get "#{user_confirmation_path}?confirmation_token=#{token}", headers: headers
        expect(response).to redirect_to(new_user_confirmation_path)
      end
    end
    shared_examples_for 'ToBase' do
      it 'ベースドメインにリダイレクト' do
        get "#{user_confirmation_path}?confirmation_token=#{token}", headers: headers
        expect(response).to redirect_to("//#{Settings['base_domain']}#{user_confirmation_path}?confirmation_token=#{token}")
      end
    end

    # テストケース
    shared_examples_for '[未ログイン][ベースドメイン]期限内のtoken、未確認（確認日時がない）' do
      include_context 'token作成', true, true
      it_behaves_like 'OK'
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '[未ログイン][サブドメイン]期限内のtoken、未確認（確認日時がない）' do
      include_context 'token作成', true, true
      it_behaves_like 'NG'
      it_behaves_like 'ToBase'
    end
    shared_examples_for '[ログイン中][ベースドメイン]期限内のtoken、未確認（確認日時がない）' do
      include_context 'token作成', true, true
      it_behaves_like 'OK'
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[ログイン中][サブドメイン]期限内のtoken、未確認（確認日時がない）' do
      include_context 'token作成', true, true
      it_behaves_like 'NG'
      it_behaves_like 'ToBase'
    end
    shared_examples_for '[未ログイン][ベースドメイン]期限内のtoken、未確認（確認日時が確認送信日時より前）' do
      include_context 'token作成', true, false, true
      it_behaves_like 'OK'
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '[未ログイン][サブドメイン]期限内のtoken、未確認（確認日時が確認送信日時より前）' do
      include_context 'token作成', true, false, true
      it_behaves_like 'NG'
      it_behaves_like 'ToBase'
    end
    shared_examples_for '[ログイン中][ベースドメイン]期限内のtoken、未確認（確認日時が確認送信日時より前）' do
      include_context 'token作成', true, false, true
      it_behaves_like 'OK'
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[ログイン中][サブドメイン]期限内のtoken、未確認（確認日時が確認送信日時より前）' do
      include_context 'token作成', true, false, true
      it_behaves_like 'NG'
      it_behaves_like 'ToBase'
    end
    shared_examples_for '[ベースドメイン]期限内のtoken、確認済み（確認日時が確認送信日時より後）' do
      include_context 'token作成', true, false, false
      it_behaves_like 'NG'
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '[サブドメイン]期限内のtoken、確認済み（確認日時が確認送信日時より後）' do
      include_context 'token作成', true, false, false
      it_behaves_like 'NG'
      it_behaves_like 'ToBase'
    end
    shared_examples_for '[ベースドメイン]期限切れのtoken、未確認（確認日時がない）' do
      include_context 'token作成', false, true
      it_behaves_like 'NG'
      it_behaves_like 'ToNew'
    end
    shared_examples_for '[サブドメイン]期限切れのtoken、未確認（確認日時がない）' do
      include_context 'token作成', false, true
      it_behaves_like 'NG'
      it_behaves_like 'ToBase'
    end
    shared_examples_for '[ベースドメイン]期限切れのtoken、未確認（確認日時が確認送信日時より前）' do
      include_context 'token作成', false, false, true
      it_behaves_like 'NG'
      it_behaves_like 'ToNew'
    end
    shared_examples_for '[サブドメイン]期限切れのtoken、未確認（確認日時が確認送信日時より前）' do
      include_context 'token作成', false, false, true
      it_behaves_like 'NG'
      it_behaves_like 'ToBase'
    end
    shared_examples_for '[ベースドメイン]期限切れのtoken、確認済み（確認日時が確認送信日時より後）' do
      include_context 'token作成', false, false, false
      it_behaves_like 'NG'
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '[サブドメイン]期限切れのtoken、確認済み（確認日時が確認送信日時より後）' do
      include_context 'token作成', false, false, false
      it_behaves_like 'NG'
      it_behaves_like 'ToBase'
    end
    shared_examples_for '[ベースドメイン]存在しないtoken' do
      let!(:token) { 'not' }
      it_behaves_like 'ToNew'
    end
    shared_examples_for '[サブドメイン]存在しないtoken' do
      let!(:token) { 'not' }
      it_behaves_like 'ToBase'
    end
    shared_examples_for '[ベースドメイン]tokenなし' do
      let!(:token) { '' }
      it_behaves_like 'ToNew'
    end
    shared_examples_for '[サブドメイン]tokenなし' do
      let!(:token) { '' }
      it_behaves_like 'ToBase'
    end

    shared_examples_for '[ベースドメイン]' do
      it_behaves_like '[ベースドメイン]期限内のtoken、確認済み（確認日時が確認送信日時より後）'
      it_behaves_like '[ベースドメイン]期限切れのtoken、未確認（確認日時がない）'
      it_behaves_like '[ベースドメイン]期限切れのtoken、未確認（確認日時が確認送信日時より前）'
      it_behaves_like '[ベースドメイン]期限切れのtoken、確認済み（確認日時が確認送信日時より後）'
      it_behaves_like '[ベースドメイン]存在しないtoken'
      it_behaves_like '[ベースドメイン]tokenなし'
    end
    shared_examples_for '[サブドメイン]' do
      it_behaves_like '[サブドメイン]期限内のtoken、確認済み（確認日時が確認送信日時より後）'
      it_behaves_like '[サブドメイン]期限切れのtoken、未確認（確認日時がない）'
      it_behaves_like '[サブドメイン]期限切れのtoken、未確認（確認日時が確認送信日時より前）'
      it_behaves_like '[サブドメイン]期限切れのtoken、確認済み（確認日時が確認送信日時より後）'
      it_behaves_like '[サブドメイン]存在しないtoken'
      it_behaves_like '[サブドメイン]tokenなし'
    end

    shared_examples_for '[未ログイン]ベースドメイン' do
      let!(:headers) { base_headers }
      it_behaves_like '[未ログイン][ベースドメイン]期限内のtoken、未確認（確認日時がない）'
      it_behaves_like '[未ログイン][ベースドメイン]期限内のtoken、未確認（確認日時が確認送信日時より前）'
      it_behaves_like '[ベースドメイン]'
    end
    shared_examples_for '[ログイン中]ベースドメイン' do
      let!(:headers) { base_headers }
      it_behaves_like '[ログイン中][ベースドメイン]期限内のtoken、未確認（確認日時がない）'
      it_behaves_like '[ログイン中][ベースドメイン]期限内のtoken、未確認（確認日時が確認送信日時より前）'
      it_behaves_like '[ベースドメイン]'
    end
    shared_examples_for '[未ログイン]存在するサブドメイン' do
      let!(:headers) { @space_headers }
      it_behaves_like '[未ログイン][サブドメイン]期限内のtoken、未確認（確認日時がない）'
      it_behaves_like '[未ログイン][サブドメイン]期限内のtoken、未確認（確認日時が確認送信日時より前）'
      it_behaves_like '[サブドメイン]'
    end
    shared_examples_for '[ログイン中]存在するサブドメイン' do
      let!(:headers) { @space_headers }
      it_behaves_like '[ログイン中][サブドメイン]期限内のtoken、未確認（確認日時がない）'
      it_behaves_like '[ログイン中][サブドメイン]期限内のtoken、未確認（確認日時が確認送信日時より前）'
      it_behaves_like '[サブドメイン]'
    end
    shared_examples_for '[未ログイン]存在しないサブドメイン' do
      let!(:headers) { not_space_headers }
      it_behaves_like '[未ログイン][サブドメイン]期限内のtoken、未確認（確認日時がない）'
      it_behaves_like '[未ログイン][サブドメイン]期限内のtoken、未確認（確認日時が確認送信日時より前）'
      it_behaves_like '[サブドメイン]'
    end
    shared_examples_for '[ログイン中]存在しないサブドメイン' do
      let!(:headers) { not_space_headers }
      it_behaves_like '[ログイン中][サブドメイン]期限内のtoken、未確認（確認日時がない）'
      it_behaves_like '[ログイン中][サブドメイン]期限内のtoken、未確認（確認日時が確認送信日時より前）'
      it_behaves_like '[サブドメイン]'
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]ベースドメイン'
      it_behaves_like '[未ログイン]存在するサブドメイン'
      it_behaves_like '[未ログイン]存在しないサブドメイン'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中]ベースドメイン'
      it_behaves_like '[ログイン中]存在するサブドメイン'
      it_behaves_like '[ログイン中]存在しないサブドメイン'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[ログイン中]ベースドメイン'
      it_behaves_like '[ログイン中]存在するサブドメイン'
      it_behaves_like '[ログイン中]存在しないサブドメイン'
    end
  end
end
