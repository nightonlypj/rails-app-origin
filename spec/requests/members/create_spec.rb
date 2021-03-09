require 'rails_helper'

RSpec.describe 'Members', type: :request do
  # POST /members/:customer_code（ベースドメイン） メンバー招待(処理)
  # POST /members/:customer_code.json（ベースドメイン） メンバー招待API
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   権限: Owner, Admin, Member, ない → データ作成
  #   顧客: 所属, 未所属, 存在しない, ない → 事前にデータ作成
  #   アカウント未登録, メンバー未登録, メンバー登録済み
  #   有効なパラメータ, 無効なパラメータ → 事前にデータ作成
  #   ベースドメイン, 存在するサブドメイン, 存在しないサブドメイン → 事前にデータ作成
  describe 'POST /create' do
    include_context 'リクエストスペース作成'
    include_context 'メンバー作成', 0, 0, 1, 0, 'ASC'
    include_context 'メンバー作成（対象外）', 'ASC'
    let!(:valid_member_attributes) { FactoryBot.attributes_for(:member, power: :Member) }
    let!(:invalid_member_attributes) { FactoryBot.attributes_for(:member, power: nil) }
    let!(:user_attributes) { FactoryBot.attributes_for(:user) }

    # テスト内容
    shared_examples_for 'OK' do
      it '作成される' do
        expect do
          post create_member_path(customer_code: customer_code), params: { member: attributes }, headers: headers
        end.to change(Member, :count).by(1) && change(User, :count).by(email == user_attributes[:email] ? 1 : 0)
      end
      it '(json)作成される' do
        expect do
          post create_member_path(customer_code: customer_code, format: :json), params: { member: attributes }, headers: headers
        end.to change(Member, :count).by(1) && change(User, :count).by(email == user_attributes[:email] ? 1 : 0)
      end
    end
    shared_examples_for 'NG' do
      it '作成されない' do
        expect do
          post create_member_path(customer_code: customer_code), params: { member: attributes }, headers: headers
        end.to change(Member, :count).by(0) && change(User, :count).by(0)
      end
      it '(json)作成されない' do
        expect do
          post create_member_path(customer_code: customer_code, format: :json), params: { member: attributes }, headers: headers
        end.to change(Member, :count).by(0) && change(User, :count).by(0)
      end
    end

    shared_examples_for 'ToIndexOK' do |alert, notice|
      it '一覧にリダイレクト' do
        post create_member_path(customer_code: customer_code), params: { member: attributes }, headers: headers
        expect(response).to redirect_to(members_path(customer_code: customer_code))
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
      it '(json)成功ステータス' do
        post create_member_path(customer_code: customer_code, format: :json), params: { member: attributes }, headers: headers
        expect(response).to be_successful
        expect(JSON.parse(response.body)['status']).to eq('OK')
        expect(JSON.parse(response.body)['notice']).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToIndexNG' do |alert, notice, error|
      it '一覧にリダイレクト' do
        post create_member_path(customer_code: customer_code), params: { member: attributes }, headers: headers
        expect(response).to redirect_to(members_path(customer_code: customer_code))
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
      it '(json)権限エラー' do
        post create_member_path(customer_code: customer_code, format: :json), params: { member: attributes }, headers: headers
        expect(response).to be_forbidden
        message = response.body.present? ? JSON.parse(response.body)['error'] : nil
        expect(message).to error.present? ? eq(I18n.t(error)) : be_nil
      end
    end
    shared_examples_for 'ToError' do
      it '成功ステータス' do # Tips: 再入力
        post create_member_path(customer_code: customer_code), params: { member: attributes }, headers: headers
        expect(response).to be_successful
      end
      it '(json)失敗レスポンス' do
        post create_member_path(customer_code: customer_code, format: :json), params: { member: attributes }, headers: headers
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['status']).to eq('NG')
        expect(JSON.parse(response.body)['error'].count).not_to eq(0)
      end
    end
    shared_examples_for 'ToNot' do |error|
      it '存在しないステータス' do
        post create_member_path(customer_code: customer_code), params: { member: attributes }, headers: headers
        expect(response).to be_not_found
      end
      it '(json)存在しないエラー' do
        post create_member_path(customer_code: customer_code, format: :json), params: { member: attributes }, headers: headers
        expect(response).to be_not_found
        message = response.body.present? ? JSON.parse(response.body)['error'] : nil
        expect(message).to error.present? ? eq(I18n.t(error)) : be_nil
      end
    end
    shared_examples_for 'ToLogin' do |alert, notice, error|
      it 'ログインにリダイレクト' do
        post create_member_path(customer_code: customer_code), params: { member: attributes }, headers: headers
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
      it '(json)認証エラー' do
        post create_member_path(customer_code: customer_code, format: :json), params: { member: attributes }, headers: headers
        expect(response).to be_unauthorized
        message = response.body.present? ? JSON.parse(response.body)['error'] : nil
        expect(message).to error.present? ? eq(I18n.t(error)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[未ログイン][ない][未所属/存在しない][*][*]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToLogin', 'devise.failure.unauthenticated', nil, 'devise.failure.unauthenticated'
    end
    shared_examples_for '[ログイン中][Owner/Admin][所属][アカウント/メンバー未登録][有効]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'OK'
      it_behaves_like 'ToIndexOK', nil, 'notice.member.create'
    end
    shared_examples_for '[ログイン中][Owner/Admin][所属][メンバー登録済み][*]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToError'
    end
    shared_examples_for '[削除予約済み][Owner/Admin][所属][*][*]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToIndexNG', 'alert.user.destroy_reserved', nil, 'alert.user.destroy_reserved'
    end
    shared_examples_for '[ログイン中][Member][所属][*][*]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToIndexNG', 'alert.member.not_create_power.admin', nil, 'alert.member.not_create_power.admin'
    end
    shared_examples_for '[ログイン中/削除予約済み][*][未所属/存在しない][*][*]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToNot', 'errors.messages.customer.code_error'
    end
    shared_examples_for '[ログイン中][Owner/Admin][所属][アカウント/メンバー未登録][無効]ベースドメイン' do
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

    shared_examples_for '[ログイン中][Owner/Admin][所属][アカウント/メンバー未登録]有効なパラメータ' do
      let!(:attributes) { valid_member_attributes.merge({ user: user_attributes.merge({ email: email }) }) }
      it_behaves_like '[ログイン中][Owner/Admin][所属][アカウント/メンバー未登録][有効]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[削除予約済み][Owner/Admin][所属][*]有効なパラメータ' do
      let!(:attributes) { valid_member_attributes.merge({ user: user_attributes.merge({ email: email }) }) }
      it_behaves_like '[削除予約済み][Owner/Admin][所属][*][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中][Member][所属][*]有効なパラメータ' do
      let!(:attributes) { valid_member_attributes.merge({ user: user_attributes.merge({ email: email }) }) }
      it_behaves_like '[ログイン中][Member][所属][*][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][ない][未所属/存在しない][*]有効なパラメータ' do
      let!(:attributes) { valid_member_attributes.merge({ user: user_attributes.merge({ email: email }) }) }
      it_behaves_like '[未ログイン][ない][未所属/存在しない][*][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][*][未所属/存在しない][*]有効なパラメータ' do
      let!(:attributes) { valid_member_attributes.merge({ user: user_attributes.merge({ email: email }) }) }
      it_behaves_like '[ログイン中/削除予約済み][*][未所属/存在しない][*][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中][Owner/Admin][所属][メンバー登録済み]有効なパラメータ' do
      let!(:attributes) { valid_member_attributes.merge({ user: user_attributes.merge({ email: email }) }) }
      it_behaves_like '[ログイン中][Owner/Admin][所属][メンバー登録済み][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中][Owner/Admin][所属][アカウント/メンバー未登録]無効なパラメータ' do
      let!(:attributes) { invalid_member_attributes.merge({ user: user_attributes.merge({ email: email }) }) }
      it_behaves_like '[ログイン中][Owner/Admin][所属][アカウント/メンバー未登録][無効]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[削除予約済み][Owner/Admin][所属][*]無効なパラメータ' do
      let!(:attributes) { invalid_member_attributes.merge({ user: user_attributes.merge({ email: email }) }) }
      it_behaves_like '[削除予約済み][Owner/Admin][所属][*][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中][Member][所属][*]無効なパラメータ' do
      let!(:attributes) { invalid_member_attributes.merge({ user: user_attributes.merge({ email: email }) }) }
      it_behaves_like '[ログイン中][Member][所属][*][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][ない][未所属/存在しない][*]無効なパラメータ' do
      let!(:attributes) { invalid_member_attributes.merge({ user: user_attributes.merge({ email: email }) }) }
      it_behaves_like '[未ログイン][ない][未所属/存在しない][*][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][*][未所属/存在しない][*]無効なパラメータ' do
      let!(:attributes) { invalid_member_attributes.merge({ user: user_attributes.merge({ email: email }) }) }
      it_behaves_like '[ログイン中/削除予約済み][*][未所属/存在しない][*][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中][Owner/Admin][所属][メンバー登録済み]無効なパラメータ' do
      let!(:attributes) { invalid_member_attributes.merge({ user: user_attributes.merge({ email: email }) }) }
      it_behaves_like '[ログイン中][Owner/Admin][所属][メンバー登録済み][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end

    shared_examples_for '[ログイン中][Owner/Admin][所属]アカウント未登録' do
      let!(:email) { user_attributes[:email] }
      it_behaves_like '[ログイン中][Owner/Admin][所属][アカウント/メンバー未登録]有効なパラメータ'
      it_behaves_like '[ログイン中][Owner/Admin][所属][アカウント/メンバー未登録]無効なパラメータ'
    end
    shared_examples_for '[削除予約済み][Owner/Admin][所属]アカウント未登録' do
      let!(:email) { user_attributes[:email] }
      it_behaves_like '[削除予約済み][Owner/Admin][所属][*]有効なパラメータ'
      it_behaves_like '[削除予約済み][Owner/Admin][所属][*]無効なパラメータ'
    end
    shared_examples_for '[ログイン中][Member][所属]アカウント未登録' do
      let!(:email) { user_attributes[:email] }
      it_behaves_like '[ログイン中][Member][所属][*]有効なパラメータ'
      it_behaves_like '[ログイン中][Member][所属][*]無効なパラメータ'
    end
    shared_examples_for '[未ログイン][ない][未所属/存在しない]アカウント未登録' do
      let!(:email) { user_attributes[:email] }
      it_behaves_like '[未ログイン][ない][未所属/存在しない][*]有効なパラメータ'
      it_behaves_like '[未ログイン][ない][未所属/存在しない][*]無効なパラメータ'
    end
    shared_examples_for '[ログイン中/削除予約済み][*][未所属/存在しない]アカウント未登録' do
      let!(:email) { user_attributes[:email] }
      it_behaves_like '[ログイン中/削除予約済み][*][未所属/存在しない][*]有効なパラメータ'
      it_behaves_like '[ログイン中/削除予約済み][*][未所属/存在しない][*]無効なパラメータ'
    end
    shared_examples_for '[ログイン中][Owner/Admin][所属]メンバー未登録' do
      let!(:email) { @create_outside_users[0].email }
      it_behaves_like '[ログイン中][Owner/Admin][所属][アカウント/メンバー未登録]有効なパラメータ'
      it_behaves_like '[ログイン中][Owner/Admin][所属][アカウント/メンバー未登録]無効なパラメータ'
    end
    shared_examples_for '[削除予約済み][Owner/Admin][所属]メンバー未登録' do
      let!(:email) { @create_outside_users[0].email }
      it_behaves_like '[削除予約済み][Owner/Admin][所属][*]有効なパラメータ'
      it_behaves_like '[削除予約済み][Owner/Admin][所属][*]無効なパラメータ'
    end
    shared_examples_for '[ログイン中][Member][所属]メンバー未登録' do
      let!(:email) { @create_outside_users[0].email }
      it_behaves_like '[ログイン中][Member][所属][*]有効なパラメータ'
      it_behaves_like '[ログイン中][Member][所属][*]無効なパラメータ'
    end
    shared_examples_for '[未ログイン][ない][未所属/存在しない]メンバー未登録' do
      let!(:email) { @create_outside_users[0].email }
      it_behaves_like '[未ログイン][ない][未所属/存在しない][*]有効なパラメータ'
      it_behaves_like '[未ログイン][ない][未所属/存在しない][*]無効なパラメータ'
    end
    shared_examples_for '[ログイン中/削除予約済み][*][未所属/存在しない]メンバー未登録' do
      let!(:email) { @create_outside_users[0].email }
      it_behaves_like '[ログイン中/削除予約済み][*][未所属/存在しない][*]有効なパラメータ'
      it_behaves_like '[ログイン中/削除予約済み][*][未所属/存在しない][*]無効なパラメータ'
    end
    shared_examples_for '[ログイン中][Owner/Admin][所属]メンバー登録済み' do
      let!(:email) { @create_users[0].email }
      it_behaves_like '[ログイン中][Owner/Admin][所属][メンバー登録済み]有効なパラメータ'
      it_behaves_like '[ログイン中][Owner/Admin][所属][メンバー登録済み]無効なパラメータ'
    end
    shared_examples_for '[削除予約済み][Owner/Admin][所属]メンバー登録済み' do
      let!(:email) { @create_users[0].email }
      it_behaves_like '[削除予約済み][Owner/Admin][所属][*]有効なパラメータ'
      it_behaves_like '[削除予約済み][Owner/Admin][所属][*]無効なパラメータ'
    end
    shared_examples_for '[ログイン中][Member][所属]メンバー登録済み' do
      let!(:email) { @create_users[0].email }
      it_behaves_like '[ログイン中][Member][所属][*]有効なパラメータ'
      it_behaves_like '[ログイン中][Member][所属][*]無効なパラメータ'
    end
    shared_examples_for '[未ログイン][ない][未所属/存在しない]メンバー登録済み' do
      let!(:email) { @create_users[0].email }
      it_behaves_like '[未ログイン][ない][未所属/存在しない][*]有効なパラメータ'
      it_behaves_like '[未ログイン][ない][未所属/存在しない][*]無効なパラメータ'
    end
    shared_examples_for '[ログイン中/削除予約済み][*][未所属/存在しない]メンバー登録済み' do
      let!(:email) { @create_users[0].email }
      it_behaves_like '[ログイン中/削除予約済み][*][未所属/存在しない][*]有効なパラメータ'
      it_behaves_like '[ログイン中/削除予約済み][*][未所属/存在しない][*]無効なパラメータ'
    end

    shared_examples_for '[ログイン中][Owner/Admin]顧客に所属' do
      let!(:customer_code) { customer.code }
      it_behaves_like '[ログイン中][Owner/Admin][所属]アカウント未登録'
      it_behaves_like '[ログイン中][Owner/Admin][所属]メンバー未登録'
      it_behaves_like '[ログイン中][Owner/Admin][所属]メンバー登録済み'
    end
    shared_examples_for '[削除予約済み][Owner/Admin]顧客に所属' do
      let!(:customer_code) { customer.code }
      it_behaves_like '[削除予約済み][Owner/Admin][所属]アカウント未登録'
      it_behaves_like '[削除予約済み][Owner/Admin][所属]メンバー未登録'
      it_behaves_like '[削除予約済み][Owner/Admin][所属]メンバー登録済み'
    end
    shared_examples_for '[ログイン中/削除予約済み][Member]顧客に所属' do
      let!(:customer_code) { customer.code }
      it_behaves_like '[ログイン中][Member][所属]アカウント未登録'
      it_behaves_like '[ログイン中][Member][所属]メンバー未登録'
      it_behaves_like '[ログイン中][Member][所属]メンバー登録済み'
    end
    shared_examples_for '[未ログイン][ない]顧客に未所属' do
      let!(:customer_code) { outside_customer.code }
      it_behaves_like '[未ログイン][ない][未所属/存在しない]アカウント未登録'
      it_behaves_like '[未ログイン][ない][未所属/存在しない]メンバー未登録'
      it_behaves_like '[未ログイン][ない][未所属/存在しない]メンバー登録済み'
    end
    shared_examples_for '[ログイン中/削除予約済み][*]顧客に未所属' do
      let!(:customer_code) { outside_customer.code }
      it_behaves_like '[ログイン中/削除予約済み][*][未所属/存在しない]アカウント未登録'
      it_behaves_like '[ログイン中/削除予約済み][*][未所属/存在しない]メンバー未登録'
      it_behaves_like '[ログイン中/削除予約済み][*][未所属/存在しない]メンバー登録済み'
    end
    shared_examples_for '[未ログイン][ない]顧客が存在しない' do
      let!(:customer_code) { NOT_CUSTOMER_CODE }
      it_behaves_like '[未ログイン][ない][未所属/存在しない]アカウント未登録'
      it_behaves_like '[未ログイン][ない][未所属/存在しない]メンバー未登録'
      it_behaves_like '[未ログイン][ない][未所属/存在しない]メンバー登録済み'
    end
    shared_examples_for '[ログイン中/削除予約済み][*]顧客が存在しない' do
      let!(:customer_code) { NOT_CUSTOMER_CODE }
      it_behaves_like '[ログイン中/削除予約済み][*][未所属/存在しない]アカウント未登録'
      it_behaves_like '[ログイン中/削除予約済み][*][未所属/存在しない]メンバー未登録'
      it_behaves_like '[ログイン中/削除予約済み][*][未所属/存在しない]メンバー登録済み'
    end

    shared_examples_for '[ログイン中]権限がOwner' do
      include_context '顧客・ユーザー紐付け', Time.current, :Owner
      it_behaves_like '[ログイン中][Owner/Admin]顧客に所属'
      it_behaves_like '[ログイン中/削除予約済み][*]顧客に未所属'
      it_behaves_like '[ログイン中/削除予約済み][*]顧客が存在しない'
      # it_behaves_like '[ログイン中/削除予約済み][*]顧客がない' # Tips: 先にRoutingErrorになる
    end
    shared_examples_for '[削除予約済み]権限がOwner' do
      include_context '顧客・ユーザー紐付け', Time.current, :Owner
      it_behaves_like '[削除予約済み][Owner/Admin]顧客に所属'
      it_behaves_like '[ログイン中/削除予約済み][*]顧客に未所属'
      it_behaves_like '[ログイン中/削除予約済み][*]顧客が存在しない'
      # it_behaves_like '[ログイン中/削除予約済み][*]顧客がない' # Tips: 先にRoutingErrorになる
    end
    shared_examples_for '[ログイン中]権限がAdmin' do
      include_context '顧客・ユーザー紐付け', Time.current, :Admin
      it_behaves_like '[ログイン中][Owner/Admin]顧客に所属'
      it_behaves_like '[ログイン中/削除予約済み][*]顧客に未所属'
      it_behaves_like '[ログイン中/削除予約済み][*]顧客が存在しない'
      # it_behaves_like '[ログイン中/削除予約済み][*]顧客がない' # Tips: 先にRoutingErrorになる
    end
    shared_examples_for '[削除予約済み]権限がAdmin' do
      include_context '顧客・ユーザー紐付け', Time.current, :Admin
      it_behaves_like '[削除予約済み][Owner/Admin]顧客に所属'
      it_behaves_like '[ログイン中/削除予約済み][*]顧客に未所属'
      it_behaves_like '[ログイン中/削除予約済み][*]顧客が存在しない'
      # it_behaves_like '[ログイン中/削除予約済み][*]顧客がない' # Tips: 先にRoutingErrorになる
    end
    shared_examples_for '[ログイン中/削除予約済み]権限がMember' do
      include_context '顧客・ユーザー紐付け', Time.current, :Member
      it_behaves_like '[ログイン中/削除予約済み][Member]顧客に所属'
      it_behaves_like '[ログイン中/削除予約済み][*]顧客に未所属'
      it_behaves_like '[ログイン中/削除予約済み][*]顧客が存在しない'
      # it_behaves_like '[ログイン中/削除予約済み][*]顧客がない' # Tips: 先にRoutingErrorになる
    end
    shared_examples_for '[未ログイン]権限がない' do
      # it_behaves_like '[未ログイン][ない]顧客に所属' # Tips: 権限がないの為、顧客に所属がない
      it_behaves_like '[未ログイン][ない]顧客に未所属'
      it_behaves_like '[未ログイン][ない]顧客が存在しない'
      # it_behaves_like '[未ログイン][ない]顧客がない' # Tips: 先にRoutingErrorになる
    end
    shared_examples_for '[ログイン中/削除予約済み]権限がない' do
      # it_behaves_like '[ログイン中/削除予約済み][ない]顧客に所属' # Tips: 権限がないの為、顧客に所属がない
      it_behaves_like '[ログイン中/削除予約済み][*]顧客に未所属'
      it_behaves_like '[ログイン中/削除予約済み][*]顧客が存在しない'
      # it_behaves_like '[ログイン中/削除予約済み][*]顧客がない' # Tips: 先にRoutingErrorになる
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
      it_behaves_like '[ログイン中/削除予約済み]権限がMember'
      it_behaves_like '[ログイン中/削除予約済み]権限がない'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[削除予約済み]権限がOwner'
      it_behaves_like '[削除予約済み]権限がAdmin'
      it_behaves_like '[ログイン中/削除予約済み]権限がMember'
      it_behaves_like '[ログイン中/削除予約済み]権限がない'
    end
  end
end
