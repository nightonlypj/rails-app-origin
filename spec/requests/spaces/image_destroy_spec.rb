require 'rails_helper'

RSpec.describe 'Spaces', type: :request do
  # DELETE /spaces/image（サブドメイン） スペース画像削除(処理)
  # DELETE /spaces/image.json（サブドメイン） スペース画像削除API
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   権限: Owner, Admin, Member, ない → データ作成
  #   ベースドメイン, 存在するサブドメイン, 存在しないサブドメイン → 事前にデータ作成
  describe 'DELETE /image_destroy' do
    include_context 'リクエストスペース作成'

    # テスト内容
    shared_examples_for 'OK' do
      it '画像が変更される' do
        delete destroy_space_image_path, headers: headers
        expect(Space.find(@request_space.id).image.url).to be_nil
      end
      it '(json)画像が変更される' do
        delete destroy_space_image_path(format: :json), headers: headers
        expect(Space.find(@request_space.id).image.url).to be_nil
      end
    end
    shared_examples_for 'NG' do
      it '画像が変更されない' do
        delete destroy_space_image_path, headers: headers
        expect(Space.find(@request_space.id).image.url).to eq(@request_space.image.url)
      end
      it '(json)画像が変更されない' do
        delete destroy_space_image_path(format: :json), headers: headers
        expect(Space.find(@request_space.id).image.url).to eq(@request_space.image.url)
      end
    end

    shared_examples_for 'ToEdit' do |alert, notice|
      it 'スペース情報変更にリダイレクト' do
        delete destroy_space_image_path, headers: headers
        expect(response).to redirect_to(edit_space_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
      it '(json)成功ステータス' do
        delete destroy_space_image_path(format: :json), headers: headers
        expect(response).to be_ok
        expect(JSON.parse(response.body)['status']).to eq('OK')
        expect(JSON.parse(response.body)['notice']).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToError' do
      it '成功ステータス' do # Tips: 再入力
        delete destroy_space_image_path, headers: headers
        expect(response).to be_successful
      end
      it '(json)失敗レスポンス' do
        delete destroy_space_image_path(format: :json), headers: headers
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['status']).to eq('NG')
        expect(JSON.parse(response.body)['error'].count).not_to eq(0)
      end
    end
    shared_examples_for 'ToNot' do |error|
      it '存在しないステータス' do
        delete destroy_space_image_path, headers: headers
        expect(response).to be_not_found
      end
      it '(json)存在しないエラー' do
        delete destroy_space_image_path(format: :json), headers: headers
        expect(response).to be_not_found
        message = response.body.present? ? JSON.parse(response.body)['error'] : nil
        expect(message).to error.present? ? eq(I18n.t(error)) : be_nil
      end
    end
    shared_examples_for 'ToTop' do |alert, notice, error|
      it 'スペーストップにリダイレクト' do
        delete destroy_space_image_path, headers: headers
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
      it '(json)権限エラー' do
        delete destroy_space_image_path(format: :json), headers: headers
        expect(response).to be_forbidden
        message = response.body.present? ? JSON.parse(response.body)['error'] : nil
        expect(message).to error.present? ? eq(I18n.t(error)) : be_nil
      end
    end
    shared_examples_for 'ToLogin' do |alert, notice, error|
      it 'ログインにリダイレクト' do
        delete destroy_space_image_path, headers: headers
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
      it '(json)認証エラー' do
        delete destroy_space_image_path(format: :json), headers: headers
        expect(response).to be_unauthorized
        message = response.body.present? ? JSON.parse(response.body)['error'] : nil
        expect(message).to error.present? ? eq(I18n.t(error)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[*][*]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToNot', 'errors.messages.domain_error'
    end
    shared_examples_for '[ログイン中][Owner/Admin]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'OK'
      it_behaves_like 'ToEdit', nil, 'notice.space.image_destroy'
    end
    shared_examples_for '[削除予約済み][Owner/Admin]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'alert.user.destroy_reserved', nil, 'alert.user.destroy_reserved'
    end
    shared_examples_for '[ログイン中/削除予約済み][Member]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'alert.space.not_update_power', nil, 'alert.space.not_update_power'
    end
    shared_examples_for '[ログイン中/削除予約済み][ない]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'NG'
      it_behaves_like 'ToNot', 'errors.messages.space.subdomain_error'
    end
    shared_examples_for '[未ログイン][ない]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'NG'
      it_behaves_like 'ToLogin', 'devise.failure.unauthenticated', nil, 'devise.failure.unauthenticated'
    end
    shared_examples_for '[*][*]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToNot', 'errors.messages.space.subdomain_error'
    end

    shared_examples_for '[ログイン中]権限がOwner' do
      include_context '顧客・ユーザー紐付け', Time.current, :Owner
      it_behaves_like '[*][*]ベースドメイン'
      it_behaves_like '[ログイン中][Owner/Admin]存在するサブドメイン'
      it_behaves_like '[*][*]存在しないサブドメイン'
    end
    shared_examples_for '[削除予約済み]権限がOwner' do
      include_context '顧客・ユーザー紐付け', Time.current, :Owner
      it_behaves_like '[*][*]ベースドメイン'
      it_behaves_like '[削除予約済み][Owner/Admin]存在するサブドメイン'
      it_behaves_like '[*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中]権限がAdmin' do
      include_context '顧客・ユーザー紐付け', Time.current, :Admin
      it_behaves_like '[*][*]ベースドメイン'
      it_behaves_like '[ログイン中][Owner/Admin]存在するサブドメイン'
      it_behaves_like '[*][*]存在しないサブドメイン'
    end
    shared_examples_for '[削除予約済み]権限がAdmin' do
      include_context '顧客・ユーザー紐付け', Time.current, :Admin
      it_behaves_like '[*][*]ベースドメイン'
      it_behaves_like '[削除予約済み][Owner/Admin]存在するサブドメイン'
      it_behaves_like '[*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み]権限がMember' do
      include_context '顧客・ユーザー紐付け', Time.current, :Member
      it_behaves_like '[*][*]ベースドメイン'
      it_behaves_like '[ログイン中/削除予約済み][Member]存在するサブドメイン'
      it_behaves_like '[*][*]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン]権限がない' do
      it_behaves_like '[*][*]ベースドメイン'
      it_behaves_like '[未ログイン][ない]存在するサブドメイン'
      it_behaves_like '[*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み]権限がない' do
      it_behaves_like '[*][*]ベースドメイン'
      it_behaves_like '[ログイン中/削除予約済み][ない]存在するサブドメイン'
      it_behaves_like '[*][*]存在しないサブドメイン'
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
