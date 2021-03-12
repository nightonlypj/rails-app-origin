require 'rails_helper'

RSpec.describe 'Spaces', type: :request do
  # POST /spaces/new（ベースドメイン） スペース作成(処理)
  # POST /spaces/new.json（ベースドメイン） スペース作成API
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   権限: Owner, Admin, Member, ない → データ作成
  #   顧客: 新規作成, 選択(所属, 未所属), 未選択, 不正値 → 固定値
  #   有効なパラメータ, 無効なパラメータ(顧客, スペース, 両方) → 事前にデータ作成
  #   ベースドメイン, 存在するサブドメイン, 存在しないサブドメイン → 事前にデータ作成
  describe 'POST #create' do
    include_context 'リクエストスペース作成'
    include_context '顧客作成（対象外）'
    let!(:valid_customer_attributes) { FactoryBot.attributes_for(:customer) }
    let!(:invalid_customer_attributes) { FactoryBot.attributes_for(:customer, code: nil, name: nil) }
    let!(:valid_space_attributes) { FactoryBot.attributes_for(:space) }
    let!(:invalid_space_attributes) { FactoryBot.attributes_for(:space, name: nil) }

    # テスト内容
    shared_examples_for 'OK' do
      it '作成される' do
        expect do
          post create_space_path, params: { space: attributes }, headers: headers
        end.to change(Space, :count).by(1) && change(Customer, :count).by(create_flag == 'true' ? 1 : 0)
      end
    end
    shared_examples_for 'NG' do
      it '作成されない' do
        expect do
          post create_space_path, params: { space: attributes }, headers: headers
        end.to change(Space, :count).by(0) && change(Customer, :count).by(0)
      end
    end

    shared_examples_for 'ToOK' do |alert, notice|
      it 'スペーストップにリダイレクト' do
        post create_space_path, params: { space: attributes }, headers: headers
        expect(response).to redirect_to("//#{attributes[:subdomain]}.#{Settings['base_domain']}")
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
      it '(json)成功ステータス' do
        post create_space_path(format: :json), params: { space: attributes }, headers: headers
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToError' do
      it '成功ステータス' do # Tips: 再入力
        post create_space_path, params: { space: attributes }, headers: headers
        expect(response).to be_successful
      end
      it '(json)失敗レスポンス' do
        post create_space_path(format: :json), params: { space: attributes }, headers: headers
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['status']).to eq('NG')
        expect(JSON.parse(response.body)['error'].count).not_to eq(0)
      end
    end
    shared_examples_for 'ToNot' do |error|
      it '存在しないステータス' do
        post create_space_path, params: { space: attributes }, headers: headers
        expect(response).to be_not_found
      end
      it '(json)存在しないエラー' do
        post create_space_path(format: :json), params: { space: attributes }, headers: headers
        expect(response).to be_not_found
        message = response.body.present? ? JSON.parse(response.body)['error'] : nil
        expect(message).to error.present? ? eq(I18n.t(error)) : be_nil
      end
    end
    shared_examples_for 'ToTop' do |alert, notice, error|
      it 'トップページにリダイレクト' do
        post create_space_path, params: { space: attributes }, headers: headers
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
      it '(json)権限エラー' do
        post create_space_path(format: :json), params: { space: attributes }, headers: headers
        expect(response).to be_forbidden
        message = response.body.present? ? JSON.parse(response.body)['error'] : nil
        expect(message).to error.present? ? eq(I18n.t(error)) : be_nil
      end
    end
    shared_examples_for 'ToLogin' do |alert, notice, error|
      it 'ログインにリダイレクト' do
        post create_space_path, params: { space: attributes }, headers: headers
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
      it '(json)認証エラー' do
        post create_space_path(format: :json), params: { space: attributes }, headers: headers
        expect(response).to be_unauthorized
        message = response.body.present? ? JSON.parse(response.body)['error'] : nil
        expect(message).to error.present? ? eq(I18n.t(error)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[ログイン中][Owner/Admin][新規作成/所属][有効]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'OK'
      it_behaves_like 'ToOK', nil, 'notice.space.create'
    end
    shared_examples_for '[ログイン中][Owner/Admin][新規作成/所属][無効]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToError'
    end
    shared_examples_for '[削除予約済み][*][*][*]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'alert.user.destroy_reserved', nil, 'alert.user.destroy_reserved'
    end
    shared_examples_for '[未ログイン][ない][*][*]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToLogin', 'devise.failure.unauthenticated', nil, 'devise.failure.unauthenticated'
    end
    shared_examples_for '[ログイン中][Member/ない][新規作成][有効]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'OK'
      it_behaves_like 'ToOK', nil, 'notice.space.create'
    end
    shared_examples_for '[ログイン中][Member/ない][新規作成][無効]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToError'
    end
    shared_examples_for '[ログイン中][Member/ない][所属][*]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToError'
    end
    shared_examples_for '[ログイン中][*][未所属/未選択/不正値][*]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToError'
    end
    shared_examples_for '[*][*][*][*]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'NG'
      it_behaves_like 'ToNot', 'errors.messages.domain_error'
    end
    shared_examples_for '[*][*][*][*]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToNot', 'errors.messages.domain_error'
    end

    shared_examples_for '[ログイン中][Owner/Admin][新規作成/所属]有効なパラメータ' do
      let!(:attributes) { valid_space_attributes.merge({ customer: valid_customer_attributes.merge({ create_flag: create_flag, code: code }) }) }
      it_behaves_like '[ログイン中][Owner/Admin][新規作成/所属][有効]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[削除予約済み][*][*]有効なパラメータ' do
      let!(:attributes) { valid_space_attributes.merge({ customer: valid_customer_attributes.merge({ create_flag: create_flag, code: code }) }) }
      it_behaves_like '[削除予約済み][*][*][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][ない][*]有効なパラメータ' do
      let!(:attributes) { valid_space_attributes.merge({ customer: valid_customer_attributes.merge({ create_flag: create_flag, code: code }) }) }
      it_behaves_like '[未ログイン][ない][*][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中][Member/ない][新規作成]有効なパラメータ' do
      let!(:attributes) { valid_space_attributes.merge({ customer: valid_customer_attributes.merge({ create_flag: create_flag, code: code }) }) }
      it_behaves_like '[ログイン中][Member/ない][新規作成][有効]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中][Member/ない][所属]有効なパラメータ' do
      let!(:attributes) { valid_space_attributes.merge({ customer: valid_customer_attributes.merge({ create_flag: create_flag, code: code }) }) }
      it_behaves_like '[ログイン中][Member/ない][所属][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中][*][未所属/未選択/不正値]有効なパラメータ' do
      let!(:attributes) { valid_space_attributes.merge({ customer: valid_customer_attributes.merge({ create_flag: create_flag, code: code }) }) }
      it_behaves_like '[ログイン中][*][未所属/未選択/不正値][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中][Owner/Admin][新規作成/所属]無効なパラメータ(顧客)' do
      let!(:attributes) { valid_space_attributes.merge({ customer: invalid_customer_attributes.merge({ create_flag: create_flag, code: code }) }) }
      it_behaves_like '[ログイン中][Owner/Admin][新規作成/所属][無効]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[削除予約済み][*][*]無効なパラメータ(顧客)' do
      let!(:attributes) { valid_space_attributes.merge({ customer: invalid_customer_attributes.merge({ create_flag: create_flag, code: code }) }) }
      it_behaves_like '[削除予約済み][*][*][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][ない][*]無効なパラメータ(顧客)' do
      let!(:attributes) { valid_space_attributes.merge({ customer: invalid_customer_attributes.merge({ create_flag: create_flag, code: code }) }) }
      it_behaves_like '[未ログイン][ない][*][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中][Member/ない][新規作成]無効なパラメータ(顧客)' do
      let!(:attributes) { valid_space_attributes.merge({ customer: invalid_customer_attributes.merge({ create_flag: create_flag, code: code }) }) }
      it_behaves_like '[ログイン中][Member/ない][新規作成][無効]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中][Member/ない][所属]無効なパラメータ(顧客)' do
      let!(:attributes) { valid_space_attributes.merge({ customer: invalid_customer_attributes.merge({ create_flag: create_flag, code: code }) }) }
      it_behaves_like '[ログイン中][Member/ない][所属][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中][*][未所属/未選択/不正値]無効なパラメータ(顧客)' do
      let!(:attributes) { valid_space_attributes.merge({ customer: invalid_customer_attributes.merge({ create_flag: create_flag, code: code }) }) }
      it_behaves_like '[ログイン中][*][未所属/未選択/不正値][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中][Owner/Admin][新規作成/所属]無効なパラメータ(スペース)' do
      let!(:attributes) { invalid_space_attributes.merge({ customer: valid_customer_attributes.merge({ create_flag: create_flag, code: code }) }) }
      it_behaves_like '[ログイン中][Owner/Admin][新規作成/所属][無効]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[削除予約済み][*][*]無効なパラメータ(スペース)' do
      let!(:attributes) { invalid_space_attributes.merge({ customer: valid_customer_attributes.merge({ create_flag: create_flag, code: code }) }) }
      it_behaves_like '[削除予約済み][*][*][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][ない][*]無効なパラメータ(スペース)' do
      let!(:attributes) { invalid_space_attributes.merge({ customer: valid_customer_attributes.merge({ create_flag: create_flag, code: code }) }) }
      it_behaves_like '[未ログイン][ない][*][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中][Member/ない][新規作成]無効なパラメータ(スペース)' do
      let!(:attributes) { invalid_space_attributes.merge({ customer: valid_customer_attributes.merge({ create_flag: create_flag, code: code }) }) }
      it_behaves_like '[ログイン中][Member/ない][新規作成][無効]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中][Member/ない][所属]無効なパラメータ(スペース)' do
      let!(:attributes) { invalid_space_attributes.merge({ customer: valid_customer_attributes.merge({ create_flag: create_flag, code: code }) }) }
      it_behaves_like '[ログイン中][Member/ない][所属][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中][*][未所属/未選択/不正値]無効なパラメータ(スペース)' do
      let!(:attributes) { invalid_space_attributes.merge({ customer: valid_customer_attributes.merge({ create_flag: create_flag, code: code }) }) }
      it_behaves_like '[ログイン中][*][未所属/未選択/不正値][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中][Owner/Admin][新規作成/所属]無効なパラメータ(両方)' do
      let!(:attributes) { invalid_space_attributes.merge({ customer: invalid_customer_attributes.merge({ create_flag: create_flag, code: code }) }) }
      it_behaves_like '[ログイン中][Owner/Admin][新規作成/所属][無効]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[削除予約済み][*][*]無効なパラメータ(両方)' do
      let!(:attributes) { invalid_space_attributes.merge({ customer: invalid_customer_attributes.merge({ create_flag: create_flag, code: code }) }) }
      it_behaves_like '[削除予約済み][*][*][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][ない][*]無効なパラメータ(両方)' do
      let!(:attributes) { invalid_space_attributes.merge({ customer: invalid_customer_attributes.merge({ create_flag: create_flag, code: code }) }) }
      it_behaves_like '[未ログイン][ない][*][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中][Member/ない][新規作成]無効なパラメータ(両方)' do
      let!(:attributes) { invalid_space_attributes.merge({ customer: invalid_customer_attributes.merge({ create_flag: create_flag, code: code }) }) }
      it_behaves_like '[ログイン中][Member/ない][新規作成][無効]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中][Member/ない][所属]無効なパラメータ(両方)' do
      let!(:attributes) { invalid_space_attributes.merge({ customer: invalid_customer_attributes.merge({ create_flag: create_flag, code: code }) }) }
      it_behaves_like '[ログイン中][Member/ない][所属][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中][*][未所属/未選択/不正値]無効なパラメータ(両方)' do
      let!(:attributes) { invalid_space_attributes.merge({ customer: invalid_customer_attributes.merge({ create_flag: create_flag, code: code }) }) }
      it_behaves_like '[ログイン中][*][未所属/未選択/不正値][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end

    shared_examples_for '[ログイン中][Owner/Admin]顧客を新規作成' do
      let!(:create_flag) { 'true' }
      let!(:code) { nil }
      it_behaves_like '[ログイン中][Owner/Admin][新規作成/所属]有効なパラメータ'
      it_behaves_like '[ログイン中][Owner/Admin][新規作成/所属]無効なパラメータ(顧客)'
      it_behaves_like '[ログイン中][Owner/Admin][新規作成/所属]無効なパラメータ(スペース)'
      it_behaves_like '[ログイン中][Owner/Admin][新規作成/所属]無効なパラメータ(両方)'
    end
    shared_examples_for '[削除予約済み][*]顧客を新規作成' do
      let!(:create_flag) { 'true' }
      let!(:code) { nil }
      it_behaves_like '[削除予約済み][*][*]有効なパラメータ'
      it_behaves_like '[削除予約済み][*][*]無効なパラメータ(顧客)'
      it_behaves_like '[削除予約済み][*][*]無効なパラメータ(スペース)'
      it_behaves_like '[削除予約済み][*][*]無効なパラメータ(両方)'
    end
    shared_examples_for '[未ログイン][ない]顧客を新規作成' do
      let!(:create_flag) { 'true' }
      let!(:code) { nil }
      it_behaves_like '[未ログイン][ない][*]有効なパラメータ'
      it_behaves_like '[未ログイン][ない][*]無効なパラメータ(顧客)'
      it_behaves_like '[未ログイン][ない][*]無効なパラメータ(スペース)'
      it_behaves_like '[未ログイン][ない][*]無効なパラメータ(両方)'
    end
    shared_examples_for '[ログイン中][Member/ない]顧客を新規作成' do
      let!(:create_flag) { 'true' }
      let!(:code) { nil }
      it_behaves_like '[ログイン中][Member/ない][新規作成]有効なパラメータ'
      it_behaves_like '[ログイン中][Member/ない][新規作成]無効なパラメータ(顧客)'
      it_behaves_like '[ログイン中][Member/ない][新規作成]無効なパラメータ(スペース)'
      it_behaves_like '[ログイン中][Member/ない][新規作成]無効なパラメータ(両方)'
    end
    shared_examples_for '[ログイン中][Owner/Admin]顧客を選択(所属)' do
      let!(:create_flag) { 'false' }
      let!(:code) { customer.code }
      it_behaves_like '[ログイン中][Owner/Admin][新規作成/所属]有効なパラメータ'
      # it_behaves_like '[ログイン中][Owner/Admin][新規作成/所属]無効なパラメータ(顧客)' # Tips: 有効なパラメータになる為
      it_behaves_like '[ログイン中][Owner/Admin][新規作成/所属]無効なパラメータ(スペース)'
      it_behaves_like '[ログイン中][Owner/Admin][新規作成/所属]無効なパラメータ(両方)'
    end
    shared_examples_for '[削除予約済み][*]顧客を選択(所属)' do
      let!(:create_flag) { 'false' }
      let!(:code) { customer.code }
      it_behaves_like '[削除予約済み][*][*]有効なパラメータ'
      it_behaves_like '[削除予約済み][*][*]無効なパラメータ(顧客)'
      it_behaves_like '[削除予約済み][*][*]無効なパラメータ(スペース)'
      it_behaves_like '[削除予約済み][*][*]無効なパラメータ(両方)'
    end
    shared_examples_for '[未ログイン][ない]顧客を選択(所属)' do
      let!(:create_flag) { 'false' }
      let!(:code) { customer.code }
      it_behaves_like '[未ログイン][ない][*]有効なパラメータ'
      it_behaves_like '[未ログイン][ない][*]無効なパラメータ(顧客)'
      it_behaves_like '[未ログイン][ない][*]無効なパラメータ(スペース)'
      it_behaves_like '[未ログイン][ない][*]無効なパラメータ(両方)'
    end
    shared_examples_for '[ログイン中][Member/ない]顧客を選択(所属)' do
      let!(:create_flag) { 'false' }
      let!(:code) { customer.code }
      it_behaves_like '[ログイン中][Member/ない][所属]有効なパラメータ'
      it_behaves_like '[ログイン中][Member/ない][所属]無効なパラメータ(顧客)'
      it_behaves_like '[ログイン中][Member/ない][所属]無効なパラメータ(スペース)'
      it_behaves_like '[ログイン中][Member/ない][所属]無効なパラメータ(両方)'
    end
    shared_examples_for '[ログイン中][*]顧客を選択(未所属)' do
      let!(:create_flag) { 'false' }
      let!(:code) { outside_customer.code }
      it_behaves_like '[ログイン中][*][未所属/未選択/不正値]有効なパラメータ'
      it_behaves_like '[ログイン中][*][未所属/未選択/不正値]無効なパラメータ(顧客)'
      it_behaves_like '[ログイン中][*][未所属/未選択/不正値]無効なパラメータ(スペース)'
      it_behaves_like '[ログイン中][*][未所属/未選択/不正値]無効なパラメータ(両方)'
    end
    shared_examples_for '[削除予約済み][*]顧客を選択(未所属)' do
      let!(:create_flag) { 'false' }
      let!(:code) { outside_customer.code }
      it_behaves_like '[削除予約済み][*][*]有効なパラメータ'
      it_behaves_like '[削除予約済み][*][*]無効なパラメータ(顧客)'
      it_behaves_like '[削除予約済み][*][*]無効なパラメータ(スペース)'
      it_behaves_like '[削除予約済み][*][*]無効なパラメータ(両方)'
    end
    shared_examples_for '[未ログイン][ない]顧客を選択(未所属)' do
      let!(:create_flag) { 'false' }
      let!(:code) { outside_customer.code }
      it_behaves_like '[未ログイン][ない][*]有効なパラメータ'
      it_behaves_like '[未ログイン][ない][*]無効なパラメータ(顧客)'
      it_behaves_like '[未ログイン][ない][*]無効なパラメータ(スペース)'
      it_behaves_like '[未ログイン][ない][*]無効なパラメータ(両方)'
    end
    shared_examples_for '[ログイン中][*]顧客が未選択' do
      let!(:create_flag) { '' }
      let!(:code) { nil }
      it_behaves_like '[ログイン中][*][未所属/未選択/不正値]有効なパラメータ'
      it_behaves_like '[ログイン中][*][未所属/未選択/不正値]無効なパラメータ(顧客)'
      it_behaves_like '[ログイン中][*][未所属/未選択/不正値]無効なパラメータ(スペース)'
      it_behaves_like '[ログイン中][*][未所属/未選択/不正値]無効なパラメータ(両方)'
    end
    shared_examples_for '[削除予約済み][*]顧客が未選択' do
      let!(:create_flag) { '' }
      let!(:code) { nil }
      it_behaves_like '[削除予約済み][*][*]有効なパラメータ'
      it_behaves_like '[削除予約済み][*][*]無効なパラメータ(顧客)'
      it_behaves_like '[削除予約済み][*][*]無効なパラメータ(スペース)'
      it_behaves_like '[削除予約済み][*][*]無効なパラメータ(両方)'
    end
    shared_examples_for '[未ログイン][ない]顧客が未選択' do
      let!(:create_flag) { '' }
      let!(:code) { nil }
      it_behaves_like '[未ログイン][ない][*]有効なパラメータ'
      it_behaves_like '[未ログイン][ない][*]無効なパラメータ(顧客)'
      it_behaves_like '[未ログイン][ない][*]無効なパラメータ(スペース)'
      it_behaves_like '[未ログイン][ない][*]無効なパラメータ(両方)'
    end
    shared_examples_for '[ログイン中][*]顧客が不正値' do
      let!(:create_flag) { 'not' }
      let!(:code) { nil }
      it_behaves_like '[ログイン中][*][未所属/未選択/不正値]有効なパラメータ'
      it_behaves_like '[ログイン中][*][未所属/未選択/不正値]無効なパラメータ(顧客)'
      it_behaves_like '[ログイン中][*][未所属/未選択/不正値]無効なパラメータ(スペース)'
      it_behaves_like '[ログイン中][*][未所属/未選択/不正値]無効なパラメータ(両方)'
    end
    shared_examples_for '[削除予約済み][*]顧客が不正値' do
      let!(:create_flag) { 'not' }
      let!(:code) { nil }
      it_behaves_like '[削除予約済み][*][*]有効なパラメータ'
      it_behaves_like '[削除予約済み][*][*]無効なパラメータ(顧客)'
      it_behaves_like '[削除予約済み][*][*]無効なパラメータ(スペース)'
      it_behaves_like '[削除予約済み][*][*]無効なパラメータ(両方)'
    end
    shared_examples_for '[未ログイン][ない]顧客が不正値' do
      let!(:create_flag) { 'not' }
      let!(:code) { nil }
      it_behaves_like '[未ログイン][ない][*]有効なパラメータ'
      it_behaves_like '[未ログイン][ない][*]無効なパラメータ(顧客)'
      it_behaves_like '[未ログイン][ない][*]無効なパラメータ(スペース)'
      it_behaves_like '[未ログイン][ない][*]無効なパラメータ(両方)'
    end

    shared_examples_for '[ログイン中]権限がOwner' do
      include_context '顧客・ユーザー紐付け', Time.current, :Owner
      it_behaves_like '[ログイン中][Owner/Admin]顧客を新規作成'
      it_behaves_like '[ログイン中][Owner/Admin]顧客を選択(所属)'
      it_behaves_like '[ログイン中][*]顧客を選択(未所属)'
      it_behaves_like '[ログイン中][*]顧客が未選択'
      it_behaves_like '[ログイン中][*]顧客が不正値'
    end
    shared_examples_for '[削除予約済み]権限がOwner' do
      include_context '顧客・ユーザー紐付け', Time.current, :Owner
      it_behaves_like '[削除予約済み][*]顧客を新規作成'
      it_behaves_like '[削除予約済み][*]顧客を選択(所属)'
      it_behaves_like '[削除予約済み][*]顧客を選択(未所属)'
      it_behaves_like '[削除予約済み][*]顧客が未選択'
      it_behaves_like '[削除予約済み][*]顧客が不正値'
    end
    shared_examples_for '[ログイン中]権限がAdmin' do
      include_context '顧客・ユーザー紐付け', Time.current, :Admin
      it_behaves_like '[ログイン中][Owner/Admin]顧客を新規作成'
      it_behaves_like '[ログイン中][Owner/Admin]顧客を選択(所属)'
      it_behaves_like '[ログイン中][*]顧客を選択(未所属)'
      it_behaves_like '[ログイン中][*]顧客が未選択'
      it_behaves_like '[ログイン中][*]顧客が不正値'
    end
    shared_examples_for '[削除予約済み]権限がAdmin' do
      include_context '顧客・ユーザー紐付け', Time.current, :Admin
      it_behaves_like '[削除予約済み][*]顧客を新規作成'
      it_behaves_like '[削除予約済み][*]顧客を選択(所属)'
      it_behaves_like '[削除予約済み][*]顧客を選択(未所属)'
      it_behaves_like '[削除予約済み][*]顧客が未選択'
      it_behaves_like '[削除予約済み][*]顧客が不正値'
    end
    shared_examples_for '[ログイン中]権限がMember' do
      include_context '顧客・ユーザー紐付け', Time.current, :Member
      it_behaves_like '[ログイン中][Member/ない]顧客を新規作成'
      it_behaves_like '[ログイン中][Member/ない]顧客を選択(所属)'
      it_behaves_like '[ログイン中][*]顧客を選択(未所属)'
      it_behaves_like '[ログイン中][*]顧客が未選択'
      it_behaves_like '[ログイン中][*]顧客が不正値'
    end
    shared_examples_for '[削除予約済み]権限がMember' do
      include_context '顧客・ユーザー紐付け', Time.current, :Member
      it_behaves_like '[削除予約済み][*]顧客を新規作成'
      it_behaves_like '[削除予約済み][*]顧客を選択(所属)'
      it_behaves_like '[削除予約済み][*]顧客を選択(未所属)'
      it_behaves_like '[削除予約済み][*]顧客が未選択'
      it_behaves_like '[削除予約済み][*]顧客が不正値'
    end
    shared_examples_for '[未ログイン]権限がない' do
      it_behaves_like '[未ログイン][ない]顧客を新規作成'
      it_behaves_like '[未ログイン][ない]顧客を選択(所属)'
      it_behaves_like '[未ログイン][ない]顧客を選択(未所属)'
      it_behaves_like '[未ログイン][ない]顧客が未選択'
      it_behaves_like '[未ログイン][ない]顧客が不正値'
    end
    shared_examples_for '[ログイン中]権限がない' do
      it_behaves_like '[ログイン中][Member/ない]顧客を新規作成'
      it_behaves_like '[ログイン中][Member/ない]顧客を選択(所属)'
      it_behaves_like '[ログイン中][*]顧客を選択(未所属)'
      it_behaves_like '[ログイン中][*]顧客が未選択'
      it_behaves_like '[ログイン中][*]顧客が不正値'
    end
    shared_examples_for '[削除予約済み]権限がない' do
      it_behaves_like '[削除予約済み][*]顧客を新規作成'
      it_behaves_like '[削除予約済み][*]顧客を選択(所属)'
      it_behaves_like '[削除予約済み][*]顧客を選択(未所属)'
      it_behaves_like '[削除予約済み][*]顧客が未選択'
      it_behaves_like '[削除予約済み][*]顧客が不正値'
    end

    context '未ログイン' do
      # it_behaves_like '[未ログイン]権限がOwner' # Tips: 未ログインの為、権限がない
      # it_behaves_like '[未ログイン]権限がAdmin' # Tips: 未ログインの為、権限がない
      # it_behaves_like '[未ログイン]権限がMember' # Tips: 未ログインの為、権限がない
      it_behaves_like '[未ログイン]権限がない'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中]権限がOwner'
      it_behaves_like '[ログイン中]権限がAdmin'
      it_behaves_like '[ログイン中]権限がMember'
      it_behaves_like '[ログイン中]権限がない'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[削除予約済み]権限がOwner'
      it_behaves_like '[削除予約済み]権限がAdmin'
      it_behaves_like '[削除予約済み]権限がMember'
      it_behaves_like '[削除予約済み]権限がない'
    end
  end
end
