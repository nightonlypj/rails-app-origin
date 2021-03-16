require 'rails_helper'

RSpec.describe 'Customers', type: :request do
  # PUT(PATCH) /customers/:customer_code/edit（ベースドメイン） 顧客情報変更(処理)
  # PUT(PATCH) /customers/:customer_code/edit.json（ベースドメイン） 顧客情報変更API
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   権限: Owner, Admin, Member, ない → データ作成
  #   顧客: 所属, 未所属, 存在しない, ない → 事前にデータ作成
  #   有効なパラメータ, 無効なパラメータ → 事前にデータ作成
  #   ベースドメイン, 存在するサブドメイン, 存在しないサブドメイン → 事前にデータ作成
  describe 'PUT #update' do
    include_context 'リクエストスペース作成'
    include_context '顧客作成（対象外）'
    let!(:valid_attributes) { FactoryBot.attributes_for(:customer) }
    let!(:invalid_attributes) { FactoryBot.attributes_for(:customer, name: nil) }

    # テスト内容
    shared_examples_for 'OK' do
      it '組織・団体名が変更される' do
        put update_customer_path(customer_code: customer_code), params: { customer: attributes }, headers: headers
        expect(Customer.find(customer.id).name).to eq(attributes[:name])
      end
      it '(json)組織・団体名が変更される' do
        put update_customer_path(customer_code: customer_code, format: :json), params: { customer: attributes }, headers: headers
        expect(Customer.find(customer.id).name).to eq(attributes[:name])
      end
    end
    shared_examples_for 'NG' do
      it '組織・団体名が変更されない' do
        put update_customer_path(customer_code: customer_code), params: { customer: attributes }, headers: headers
        expect(Customer.find(customer.id).name).to eq(customer.name)
      end
      it '(json)組織・団体名が変更されない' do
        put update_customer_path(customer_code: customer_code, format: :json), params: { customer: attributes }, headers: headers
        expect(Customer.find(customer.id).name).to eq(customer.name)
      end
    end

    shared_examples_for 'ToOK' do |alert, notice|
      it '顧客情報にリダイレクト' do
        put update_customer_path(customer_code: customer_code), params: { customer: attributes }, headers: headers
        expect(response).to redirect_to(customer_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
      it '(json)成功ステータス' do
        put update_customer_path(customer_code: customer_code, format: :json), params: { customer: attributes }, headers: headers
        expect(response).to be_ok
        expect(JSON.parse(response.body)['status']).to eq('OK')
        expect(JSON.parse(response.body)['notice']).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToError' do
      it '成功ステータス' do # Tips: 再入力
        put update_customer_path(customer_code: customer_code), params: { customer: attributes }, headers: headers
        expect(response).to be_successful
      end
      it '(json)失敗レスポンス' do
        put update_customer_path(customer_code: customer_code, format: :json), params: { customer: attributes }, headers: headers
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['status']).to eq('NG')
        expect(JSON.parse(response.body)['error'].count).not_to eq(0)
      end
    end
    shared_examples_for 'ToNot' do |error|
      it '存在しないステータス' do
        put update_customer_path(customer_code: customer_code), params: { customer: attributes }, headers: headers
        expect(response).to be_not_found
      end
      it '(json)存在しないエラー' do
        put update_customer_path(customer_code: customer_code, format: :json), params: { customer: attributes }, headers: headers
        expect(response).to be_not_found
        message = response.body.present? ? JSON.parse(response.body)['error'] : nil
        expect(message).to error.present? ? eq(I18n.t(error)) : be_nil
      end
    end
    shared_examples_for 'ToTop' do |alert, notice, error|
      it 'トップページにリダイレクト' do
        put update_customer_path(customer_code: customer_code), params: { customer: attributes }, headers: headers
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
      it '(json)権限エラー' do
        put update_customer_path(customer_code: customer_code, format: :json), params: { customer: attributes }, headers: headers
        expect(response).to be_forbidden
        message = response.body.present? ? JSON.parse(response.body)['error'] : nil
        expect(message).to error.present? ? eq(I18n.t(error)) : be_nil
      end
    end
    shared_examples_for 'ToLogin' do |alert, notice, error|
      it 'ログインにリダイレクト' do
        put update_customer_path(customer_code: customer_code), params: { customer: attributes }, headers: headers
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
      it '(json)認証エラー' do
        put update_customer_path(customer_code: customer_code, format: :json), params: { customer: attributes }, headers: headers
        expect(response).to be_unauthorized
        message = response.body.present? ? JSON.parse(response.body)['error'] : nil
        expect(message).to error.present? ? eq(I18n.t(error)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[ログイン中][Owner][所属][有効]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'OK'
      it_behaves_like 'ToOK', nil, 'notice.customer.update'
    end
    shared_examples_for '[ログイン中][Owner][所属][無効]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToError'
    end
    shared_examples_for '[削除予約済み][Owner][所属][*]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'alert.user.destroy_reserved', nil, 'alert.user.destroy_reserved'
    end
    shared_examples_for '[ログイン中/削除予約済み][Admin/Member/ない][所属][*]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'alert.customer.not_update_power', nil, 'alert.customer.not_update_power'
    end
    shared_examples_for '[未ログイン][ない][未所属/存在しない][*]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToLogin', 'devise.failure.unauthenticated', nil, 'devise.failure.unauthenticated'
    end
    shared_examples_for '[ログイン中/削除予約済み][*][未所属/存在しない][*]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToNot', 'errors.messages.customer.code_error'
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

    shared_examples_for '[ログイン中][Owner][所属]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like '[ログイン中][Owner][所属][有効]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[削除予約済み][Owner][所属]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like '[削除予約済み][Owner][所属][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][Admin/Member/ない][所属]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like '[ログイン中/削除予約済み][Admin/Member/ない][所属][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][ない][未所属/存在しない]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like '[未ログイン][ない][未所属/存在しない][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][*][未所属/存在しない]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like '[ログイン中/削除予約済み][*][未所属/存在しない][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中][Owner][所属]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like '[ログイン中][Owner][所属][無効]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[削除予約済み][Owner][所属]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like '[削除予約済み][Owner][所属][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][Admin/Member/ない][所属]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like '[ログイン中/削除予約済み][Admin/Member/ない][所属][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][ない][未所属/存在しない]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like '[未ログイン][ない][未所属/存在しない][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][*][未所属/存在しない]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like '[ログイン中/削除予約済み][*][未所属/存在しない][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end

    shared_examples_for '[ログイン中][Owner]顧客に所属' do
      let!(:customer_code) { customer.code }
      it_behaves_like '[ログイン中][Owner][所属]有効なパラメータ'
      it_behaves_like '[ログイン中][Owner][所属]無効なパラメータ'
    end
    shared_examples_for '[削除予約済み][Owner]顧客に所属' do
      let!(:customer_code) { customer.code }
      it_behaves_like '[削除予約済み][Owner][所属]有効なパラメータ'
      it_behaves_like '[削除予約済み][Owner][所属]無効なパラメータ'
    end
    shared_examples_for '[ログイン中/削除予約済み][Admin/Member]顧客に所属' do
      let!(:customer_code) { customer.code }
      it_behaves_like '[ログイン中/削除予約済み][Admin/Member/ない][所属]有効なパラメータ'
      it_behaves_like '[ログイン中/削除予約済み][Admin/Member/ない][所属]無効なパラメータ'
    end
    shared_examples_for '[未ログイン][ない]顧客に未所属' do
      let!(:customer_code) { outside_customer.code }
      it_behaves_like '[未ログイン][ない][未所属/存在しない]有効なパラメータ'
      it_behaves_like '[未ログイン][ない][未所属/存在しない]無効なパラメータ'
    end
    shared_examples_for '[ログイン中/削除予約済み][*]顧客に未所属' do
      let!(:customer_code) { outside_customer.code }
      it_behaves_like '[ログイン中/削除予約済み][*][未所属/存在しない]有効なパラメータ'
      it_behaves_like '[ログイン中/削除予約済み][*][未所属/存在しない]無効なパラメータ'
    end
    shared_examples_for '[未ログイン][ない]顧客が存在しない' do
      let!(:customer_code) { NOT_CUSTOMER_CODE }
      it_behaves_like '[未ログイン][ない][未所属/存在しない]有効なパラメータ'
      it_behaves_like '[未ログイン][ない][未所属/存在しない]無効なパラメータ'
    end
    shared_examples_for '[ログイン中/削除予約済み][*]顧客が存在しない' do
      let!(:customer_code) { NOT_CUSTOMER_CODE }
      it_behaves_like '[ログイン中/削除予約済み][*][未所属/存在しない]有効なパラメータ'
      it_behaves_like '[ログイン中/削除予約済み][*][未所属/存在しない]無効なパラメータ'
    end

    shared_examples_for '[ログイン中]権限がOwner' do
      include_context '顧客・ユーザー紐付け', Time.current, :Owner
      it_behaves_like '[ログイン中][Owner]顧客に所属'
      it_behaves_like '[ログイン中/削除予約済み][*]顧客に未所属'
      it_behaves_like '[ログイン中/削除予約済み][*]顧客が存在しない'
      # it_behaves_like '[ログイン中/削除予約済み][*]顧客がない' # Tips: 先にRoutingErrorになる
    end
    shared_examples_for '[削除予約済み]権限がOwner' do
      include_context '顧客・ユーザー紐付け', Time.current, :Owner
      it_behaves_like '[削除予約済み][Owner]顧客に所属'
      it_behaves_like '[ログイン中/削除予約済み][*]顧客に未所属'
      it_behaves_like '[ログイン中/削除予約済み][*]顧客が存在しない'
      # it_behaves_like '[ログイン中/削除予約済み][*]顧客がない' # Tips: 先にRoutingErrorになる
    end
    shared_examples_for '[ログイン中/削除予約済み]権限がAdmin' do
      include_context '顧客・ユーザー紐付け', Time.current, :Admin
      it_behaves_like '[ログイン中/削除予約済み][Admin/Member]顧客に所属'
      it_behaves_like '[ログイン中/削除予約済み][*]顧客に未所属'
      it_behaves_like '[ログイン中/削除予約済み][*]顧客が存在しない'
      # it_behaves_like '[ログイン中/削除予約済み][*]顧客がない' # Tips: 先にRoutingErrorになる
    end
    shared_examples_for '[ログイン中/削除予約済み]権限がMember' do
      include_context '顧客・ユーザー紐付け', Time.current, :Member
      it_behaves_like '[ログイン中/削除予約済み][Admin/Member]顧客に所属'
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
      it_behaves_like '[ログイン中/削除予約済み]権限がAdmin'
      it_behaves_like '[ログイン中/削除予約済み]権限がMember'
      it_behaves_like '[ログイン中/削除予約済み]権限がない'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[削除予約済み]権限がOwner'
      it_behaves_like '[ログイン中/削除予約済み]権限がAdmin'
      it_behaves_like '[ログイン中/削除予約済み]権限がMember'
      it_behaves_like '[ログイン中/削除予約済み]権限がない'
    end
  end
end
