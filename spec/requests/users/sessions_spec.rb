require 'rails_helper'

RSpec.describe 'Users::Sessions', type: :request do
  # GET /users/sign_in ログイン
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  describe 'GET #new' do
    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get new_user_session_path
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToTop' do |alert, notice|
      it 'トップページにリダイレクト' do
        get new_user_session_path
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

  # POST /users/sign_in ログイン(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, 未ログイン（削除予約済み）, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   有効なパラメータ, 無効なパラメータ → 事前にデータ作成
  describe 'POST #create' do
    shared_context '有効なパラメータ' do
      let!(:attributes) { { email: user.email, password: user.password } }
    end
    shared_context '無効なパラメータ' do
      let!(:attributes) { { email: user.email, password: nil } }
    end

    # テスト内容
    shared_examples_for 'ToError' do
      it '成功ステータス' do # Tips: 再入力
        post create_user_session_path, params: { user: attributes }
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToTop' do |alert, notice|
      it 'トップページにリダイレクト' do
        post create_user_session_path, params: { user: attributes }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]有効なパラメータ' do
      include_context '有効なパラメータ'
      it_behaves_like 'ToTop', nil, 'devise.sessions.signed_in'
    end
    shared_examples_for '[ログイン中/削除予約済み]有効なパラメータ' do
      include_context '有効なパラメータ'
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]無効なパラメータ' do
      include_context '無効なパラメータ'
      it_behaves_like 'ToError'
    end
    shared_examples_for '[ログイン中/削除予約済み]無効なパラメータ' do
      include_context '無効なパラメータ'
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end

    context '未ログイン' do
      include_context 'ユーザー作成'
      it_behaves_like '[未ログイン]有効なパラメータ'
      it_behaves_like '[未ログイン]無効なパラメータ'
    end
    context '未ログイン（削除予約済み）' do
      include_context 'ユーザー作成', true
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

  # DELETE(GET) /users/sign_out ログアウト(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  describe 'DELETE #destroy' do
    # テスト内容
    shared_examples_for 'ToLogin' do |alert, notice|
      it 'ログインにリダイレクト' do
        delete destroy_user_session_path
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    context '未ログイン' do
      it_behaves_like 'ToLogin', nil, 'devise.sessions.already_signed_out'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'ToLogin', nil, 'devise.sessions.signed_out'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like 'ToLogin', nil, 'devise.sessions.signed_out'
    end
  end
end
