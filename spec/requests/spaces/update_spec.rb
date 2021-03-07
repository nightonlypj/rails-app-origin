require 'rails_helper'

RSpec.describe 'Spaces', type: :request do
  # PUT(PATCH) /spaces/edit（サブドメイン） スペース情報変更(処理)
  # PUT(PATCH) /spaces/edit.json（サブドメイン） スペース情報変更API
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   権限: ある(Owner, Admin), ない(Member含む) → データ作成
  #   有効なパラメータ, 無効なパラメータ → 事前にデータ作成
  #   ベースドメイン, 存在するサブドメイン, 存在しないサブドメイン → 事前にデータ作成
  describe 'PUT /update' do
    include_context 'リクエストスペース作成'
    let!(:valid_attributes) { FactoryBot.attributes_for(:space) }
    let!(:invalid_attributes) { FactoryBot.attributes_for(:space, subdomain: nil) }

    # テスト内容
    shared_examples_for 'OK' do
      it 'スペース名が変更される' do
        put update_space_path, params: { space: attributes }, headers: headers
        expect(Space.find(@request_space.id).name).to eq(attributes[:name])
      end
    end
    shared_examples_for 'NG' do
      it 'スペース名が変更されない' do
        put update_space_path, params: { space: attributes }, headers: headers
        expect(Space.find(@request_space.id).name).to eq(@request_space.name)
      end
    end

    shared_examples_for 'ToOK' do |alert, notice|
      it 'スペーストップにリダイレクト' do
        put update_space_path, params: { space: attributes }, headers: headers
        expect(response).to redirect_to("//#{attributes[:subdomain]}.#{Settings['base_domain']}")
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
      it '(json)成功ステータス' do
        put update_space_path(format: :json), params: { space: attributes }, headers: headers
        expect(response).to be_ok
      end
    end
    shared_examples_for 'ToError' do
      it '成功ステータス' do # Tips: 再入力
        put update_space_path, params: { space: attributes }, headers: headers
        expect(response).to be_successful
      end
      it '(json)失敗レスポンス' do
        put update_space_path(format: :json), params: { space: attributes }, headers: headers
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['status']).to eq('NG')
        expect(JSON.parse(response.body)['error'].count).not_to eq(0)
      end
    end
    shared_examples_for 'ToNot' do |error|
      it '存在しないステータス' do
        put update_space_path, params: { space: attributes }, headers: headers
        expect(response).to be_not_found
      end
      it '(json)存在しないエラー' do
        put update_space_path(format: :json), params: { space: attributes }, headers: headers
        expect(response).to be_not_found
        message = response.body.present? ? JSON.parse(response.body)['error'] : nil
        expect(message).to error.present? ? eq(I18n.t(error)) : be_nil
      end
    end
    shared_examples_for 'ToTop' do |alert, notice, error|
      it 'スペーストップにリダイレクト' do
        put update_space_path, params: { space: attributes }, headers: headers
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
      it '(json)権限エラー' do
        put update_space_path(format: :json), params: { space: attributes }, headers: headers
        expect(response).to be_forbidden
        message = response.body.present? ? JSON.parse(response.body)['error'] : nil
        expect(message).to error.present? ? eq(I18n.t(error)) : be_nil
      end
    end
    shared_examples_for 'ToLogin' do |alert, notice, error|
      it 'ログインにリダイレクト' do
        put update_space_path, params: { space: attributes }, headers: headers
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
      it '(json)認証エラー' do
        put update_space_path(format: :json), params: { space: attributes }, headers: headers
        expect(response).to be_unauthorized
        message = response.body.present? ? JSON.parse(response.body)['error'] : nil
        expect(message).to error.present? ? eq(I18n.t(error)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[*][*][*]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToNot', 'errors.messages.domain_error'
    end
    shared_examples_for '[ログイン中][ある][有効]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'OK'
      it_behaves_like 'ToOK', nil, 'notice.space.update'
    end
    shared_examples_for '[削除予約済み][*][*]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', nil, 'notice.user.destroy_reserved', 'notice.user.destroy_reserved'
    end
    shared_examples_for '[ログイン中/削除予約済み][Member][*]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'alert.space.not_update_power', nil, 'alert.space.not_update_power'
    end
    shared_examples_for '[ログイン中/削除予約済み][ない][*]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'NG'
      it_behaves_like 'ToNot', nil
    end
    shared_examples_for '[未ログイン][ない][*]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'NG'
      it_behaves_like 'ToLogin', 'devise.failure.unauthenticated', nil, 'devise.failure.unauthenticated'
    end
    shared_examples_for '[ログイン中][ある][無効]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'NG'
      it_behaves_like 'ToError'
    end
    shared_examples_for '[*][*][*]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToNot', nil
    end

    shared_examples_for '[ログイン中][ある]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like '[*][*][*]ベースドメイン'
      it_behaves_like '[ログイン中][ある][有効]存在するサブドメイン'
      it_behaves_like '[*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[削除予約済み][ある]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like '[*][*][*]ベースドメイン'
      it_behaves_like '[削除予約済み][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][Member]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like '[*][*][*]ベースドメイン'
      it_behaves_like '[ログイン中/削除予約済み][Member][*]存在するサブドメイン'
      it_behaves_like '[*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][ない]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like '[*][*][*]ベースドメイン'
      it_behaves_like '[ログイン中/削除予約済み][ない][*]存在するサブドメイン'
      it_behaves_like '[*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][ない]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like '[*][*][*]ベースドメイン'
      it_behaves_like '[未ログイン][ない][*]存在するサブドメイン'
      it_behaves_like '[*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中][ある]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like '[*][*][*]ベースドメイン'
      it_behaves_like '[ログイン中][ある][無効]存在するサブドメイン'
      it_behaves_like '[*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[削除予約済み][ある]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like '[*][*][*]ベースドメイン'
      it_behaves_like '[削除予約済み][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][Member]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like '[*][*][*]ベースドメイン'
      it_behaves_like '[ログイン中/削除予約済み][Member][*]存在するサブドメイン'
      it_behaves_like '[*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][ない]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like '[*][*][*]ベースドメイン'
      it_behaves_like '[未ログイン][ない][*]存在するサブドメイン'
      it_behaves_like '[*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][ない]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like '[*][*][*]ベースドメイン'
      it_behaves_like '[ログイン中/削除予約済み][ない][*]存在するサブドメイン'
      it_behaves_like '[*][*][*]存在しないサブドメイン'
    end

    shared_examples_for '[ログイン中]権限がある' do |power|
      include_context '顧客・ユーザー紐付け', Time.current, power
      it_behaves_like '[ログイン中][ある]有効なパラメータ'
      it_behaves_like '[ログイン中][ある]無効なパラメータ'
    end
    shared_examples_for '[削除予約済み]権限がある' do |power|
      include_context '顧客・ユーザー紐付け', Time.current, power
      it_behaves_like '[削除予約済み][ある]有効なパラメータ'
      it_behaves_like '[削除予約済み][ある]無効なパラメータ'
    end
    shared_examples_for '[ログイン中]権限がMember' do
      include_context '顧客・ユーザー紐付け', Time.current, :Member
      it_behaves_like '[ログイン中/削除予約済み][Member]有効なパラメータ'
      it_behaves_like '[ログイン中/削除予約済み][Member]無効なパラメータ'
    end
    shared_examples_for '[削除予約済み]権限がMember' do
      include_context '顧客・ユーザー紐付け', Time.current, :Member
      it_behaves_like '[ログイン中/削除予約済み][Member]有効なパラメータ'
      it_behaves_like '[ログイン中/削除予約済み][Member]無効なパラメータ'
    end
    shared_examples_for '[未ログイン]権限がない' do
      it_behaves_like '[未ログイン][ない]有効なパラメータ'
      it_behaves_like '[未ログイン][ない]無効なパラメータ'
    end
    shared_examples_for '[ログイン中]権限がない' do
      it_behaves_like '[ログイン中/削除予約済み][ない]有効なパラメータ'
      it_behaves_like '[ログイン中/削除予約済み][ない]無効なパラメータ'
    end
    shared_examples_for '[削除予約済み]権限がない' do
      it_behaves_like '[ログイン中/削除予約済み][ない]有効なパラメータ'
      it_behaves_like '[ログイン中/削除予約済み][ない]無効なパラメータ'
    end

    context '未ログイン' do
      # it_behaves_like '[未ログイン]権限がある', :Owner # Tips: 未ログインの為、権限がない
      # it_behaves_like '[未ログイン]権限がある', :Admin # Tips: 未ログインの為、権限がない
      # it_behaves_like '[未ログイン]権限がMember' # Tips: 未ログインの為、権限がない
      it_behaves_like '[未ログイン]権限がない'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中]権限がある', :Owner
      it_behaves_like '[ログイン中]権限がある', :Admin
      it_behaves_like '[ログイン中]権限がMember'
      it_behaves_like '[ログイン中]権限がない'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[削除予約済み]権限がある', :Owner
      it_behaves_like '[削除予約済み]権限がある', :Admin
      it_behaves_like '[削除予約済み]権限がMember'
      it_behaves_like '[削除予約済み]権限がない'
    end
  end
end
