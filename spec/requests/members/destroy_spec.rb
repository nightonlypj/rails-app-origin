require 'rails_helper'

RSpec.describe 'Members', type: :request do
  # DELETE /members/:customer_code/:user_code（ベースドメイン） メンバー解除(処理)
  # DELETE /members/:customer_code/:user_code.json（ベースドメイン） メンバー解除API
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   権限: Owner, Admin, Member, ない → データ作成
  #   顧客: 所属, 未所属, 存在しない, ない → 事前にデータ作成
  #   対象: ない, 自分, Owner, Admin, Member → 事前にデータ作成
  #   ベースドメイン, 存在するサブドメイン, 存在しないサブドメイン → 事前にデータ作成
  describe 'DELETE /destroy' do
    include_context 'リクエストスペース作成'
    include_context 'メンバー作成', 1, 1, 1, 0, 'ASC'
    include_context 'メンバー作成（対象外）', 'ASC'

    # テスト内容
    shared_examples_for 'OK' do
      it 'メンバーが削除される' do
        expect do
          delete destroy_member_path(customer_code: customer_code, user_code: user_code), headers: headers
        end.to change(Member, :count).by(-1)
      end
      it '(json)メンバーが削除される' do
        expect do
          delete destroy_member_path(customer_code: customer_code, user_code: user_code, format: :json), headers: headers
        end.to change(Member, :count).by(-1)
      end
    end
    shared_examples_for 'NG' do
      it 'メンバーが削除されない（対象が存在する場合）' do
        if target_member.present?
          expect do
            delete destroy_member_path(customer_code: customer_code, user_code: user_code), headers: headers
          end.to change(Member, :count).by(0)
        end
      end
      it '(json)メンバーが削除されない（対象が存在する場合）' do
        if target_member.present?
          expect do
            delete destroy_member_path(customer_code: customer_code, user_code: user_code, format: :json), headers: headers
          end.to change(Member, :count).by(0)
        end
      end
    end

    shared_examples_for 'ToNot' do |error|
      it '存在しないステータス' do
        delete destroy_member_path(customer_code: customer_code, user_code: user_code), headers: headers
        expect(response).to be_not_found
      end
      it '(json)存在しないエラー' do
        delete destroy_member_path(customer_code: customer_code, user_code: user_code, format: :json), headers: headers
        expect(response).to be_not_found
        message = response.body.present? ? JSON.parse(response.body)['error'] : nil
        expect(message).to error.present? ? eq(I18n.t(error)) : be_nil
      end
    end
    shared_examples_for 'ToIndexOK' do |alert, notice|
      it '一覧にリダイレクト' do
        delete destroy_member_path(customer_code: customer_code, user_code: user_code), headers: headers
        expect(response).to redirect_to(members_path(customer_code: customer_code))
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
      it '(json)成功レスポンス' do
        delete destroy_member_path(customer_code: customer_code, user_code: user_code, format: :json), headers: headers
        expect(response).to be_ok
        expect(JSON.parse(response.body)['status']).to eq('OK')
        expect(JSON.parse(response.body)['notice']).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToIndexNG' do |alert, notice, error|
      it '一覧にリダイレクト' do
        delete destroy_member_path(customer_code: customer_code, user_code: user_code), headers: headers
        expect(response).to redirect_to(members_path(customer_code: customer_code))
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
      it '(json)権限エラー' do
        delete destroy_member_path(customer_code: customer_code, user_code: user_code, format: :json), headers: headers
        expect(response).to be_forbidden
        message = response.body.present? ? JSON.parse(response.body)['error'] : nil
        expect(message).to error.present? ? eq(I18n.t(error)) : be_nil
      end
    end
    shared_examples_for 'ToLogin' do |alert, notice, error|
      it 'ログインにリダイレクト' do
        delete destroy_member_path(customer_code: customer_code, user_code: user_code), headers: headers
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
      it '(json)認証エラー' do
        delete destroy_member_path(customer_code: customer_code, user_code: user_code, format: :json), headers: headers
        expect(response).to be_unauthorized
        message = response.body.present? ? JSON.parse(response.body)['error'] : nil
        expect(message).to error.present? ? eq(I18n.t(error)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[ログイン中/削除予約済み][Owner][所属][自分]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToIndexNG', 'alert.member.own_destroy_power.owner', nil, 'alert.member.own_destroy_power.owner'
    end
    shared_examples_for '[ログイン中/削除予約済み][Admin][所属][自分]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToIndexNG', 'alert.member.own_destroy_power.admin', nil, 'alert.member.own_destroy_power.admin'
    end
    shared_examples_for '[ログイン中/削除予約済み][Member][所属][自分/Admin/Member]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToIndexNG', 'alert.member.not_destroy_power.admin', nil, 'alert.member.not_destroy_power.admin'
    end
    shared_examples_for '[ログイン中][Owner][所属][Owner]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'OK'
      it_behaves_like 'ToIndexOK', nil, 'notice.member.destroy', 'notice.member.destroy'
    end
    shared_examples_for '[削除予約済み][Owner][所属][Owner]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToIndexNG', 'alert.user.destroy_reserved', nil, 'alert.user.destroy_reserved'
    end
    shared_examples_for '[ログイン中/削除予約済み][Admin/Member][所属][Owner]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToIndexNG', 'alert.member.not_destroy_power.owner', nil, 'alert.member.not_destroy_power.owner'
    end
    shared_examples_for '[ログイン中][Owner/Admin][所属][Admin/Member]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'OK'
      it_behaves_like 'ToIndexOK', nil, 'notice.member.destroy', 'notice.member.destroy'
    end
    shared_examples_for '[削除予約済み][Owner/Admin][所属][Admin/Member]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToIndexNG', 'alert.user.destroy_reserved', nil, 'alert.user.destroy_reserved'
    end
    shared_examples_for '[未ログイン][*][未所属/存在しない][*]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToLogin', 'devise.failure.unauthenticated', nil, 'devise.failure.unauthenticated'
    end
    shared_examples_for '[ログイン中/削除予約済み][*][未所属/存在しない][自分]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      # it_behaves_like 'NG' # Tips: 権限がない為、紐付かない
      it_behaves_like 'ToNot', 'errors.messages.customer.code_error'
    end
    shared_examples_for '[ログイン中/削除予約済み][*][未所属/存在しない][Owner/Admin/Member]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToNot', 'errors.messages.customer.code_error'
    end
    shared_examples_for '[*][*][*][自分]存在するサブドメイン' do
      let!(:headers) { @space_header }
      # it_behaves_like 'NG' # Tips: 権限がない為、紐付かない
      it_behaves_like 'ToNot', 'errors.messages.domain_error'
    end
    shared_examples_for '[*][*][*][Owner/Admin/Member]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'NG'
      it_behaves_like 'ToNot', 'errors.messages.domain_error'
    end
    shared_examples_for '[*][*][*][自分]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      # it_behaves_like 'NG' # Tips: 権限がない為、紐付かない
      it_behaves_like 'ToNot', 'errors.messages.domain_error'
    end
    shared_examples_for '[*][*][*][Owner/Admin/Member]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToNot', 'errors.messages.domain_error'
    end

    shared_examples_for '[ログイン中/削除予約済み][Owner][所属]対象が自分' do
      let!(:user_code) { user.code }
      let!(:target_member) { member }
      it_behaves_like '[ログイン中/削除予約済み][Owner][所属][自分]ベースドメイン'
      it_behaves_like '[*][*][*][Owner/Admin/Member]存在するサブドメイン'
      it_behaves_like '[*][*][*][Owner/Admin/Member]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][Admin][所属]対象が自分' do
      let!(:user_code) { user.code }
      let!(:target_member) { member }
      it_behaves_like '[ログイン中/削除予約済み][Admin][所属][自分]ベースドメイン'
      it_behaves_like '[*][*][*][Owner/Admin/Member]存在するサブドメイン'
      it_behaves_like '[*][*][*][Owner/Admin/Member]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][Member][所属]対象が自分' do
      let!(:user_code) { user.code }
      let!(:target_member) { member }
      it_behaves_like '[ログイン中/削除予約済み][Member][所属][自分/Admin/Member]ベースドメイン'
      it_behaves_like '[*][*][*][Owner/Admin/Member]存在するサブドメイン'
      it_behaves_like '[*][*][*][Owner/Admin/Member]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][*][未所属/存在しない]対象が自分' do
      let!(:user_code) { user.code }
      let!(:target_member) { nil } # Tips: 権限がない為、紐付かない
      it_behaves_like '[ログイン中/削除予約済み][*][未所属/存在しない][自分]ベースドメイン'
      it_behaves_like '[*][*][*][自分]存在するサブドメイン'
      it_behaves_like '[*][*][*][自分]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中][Owner][所属]対象がOwner' do
      let!(:user_code) { @create_users[0].code }
      let!(:target_member) { @create_members[0] }
      it_behaves_like '[ログイン中][Owner][所属][Owner]ベースドメイン'
      it_behaves_like '[*][*][*][Owner/Admin/Member]存在するサブドメイン'
      it_behaves_like '[*][*][*][Owner/Admin/Member]存在しないサブドメイン'
    end
    shared_examples_for '[削除予約済み][Owner][所属]対象がOwner' do
      let!(:user_code) { @create_users[0].code }
      let!(:target_member) { @create_members[0] }
      it_behaves_like '[削除予約済み][Owner][所属][Owner]ベースドメイン'
      it_behaves_like '[*][*][*][Owner/Admin/Member]存在するサブドメイン'
      it_behaves_like '[*][*][*][Owner/Admin/Member]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][Admin/Member][所属]対象がOwner' do
      let!(:user_code) { @create_users[0].code }
      let!(:target_member) { @create_members[0] }
      it_behaves_like '[ログイン中/削除予約済み][Admin/Member][所属][Owner]ベースドメイン'
      it_behaves_like '[*][*][*][Owner/Admin/Member]存在するサブドメイン'
      it_behaves_like '[*][*][*][Owner/Admin/Member]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中][Owner/Admin][所属]対象がAdmin' do
      let!(:user_code) { @create_users[1].code }
      let!(:target_member) { @create_members[1] }
      it_behaves_like '[ログイン中][Owner/Admin][所属][Admin/Member]ベースドメイン'
      it_behaves_like '[*][*][*][Owner/Admin/Member]存在するサブドメイン'
      it_behaves_like '[*][*][*][Owner/Admin/Member]存在しないサブドメイン'
    end
    shared_examples_for '[削除予約済み][Owner/Admin][所属]対象がAdmin' do
      let!(:user_code) { @create_users[1].code }
      let!(:target_member) { @create_members[1] }
      it_behaves_like '[削除予約済み][Owner/Admin][所属][Admin/Member]ベースドメイン'
      it_behaves_like '[*][*][*][Owner/Admin/Member]存在するサブドメイン'
      it_behaves_like '[*][*][*][Owner/Admin/Member]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][Member][所属]対象がAdmin' do
      let!(:user_code) { @create_users[1].code }
      let!(:target_member) { @create_members[1] }
      it_behaves_like '[ログイン中/削除予約済み][Member][所属][自分/Admin/Member]ベースドメイン'
      it_behaves_like '[*][*][*][Owner/Admin/Member]存在するサブドメイン'
      it_behaves_like '[*][*][*][Owner/Admin/Member]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中][Owner/Admin][所属]対象がMember' do
      let!(:user_code) { @create_users[2].code }
      let!(:target_member) { @create_members[2] }
      it_behaves_like '[ログイン中][Owner/Admin][所属][Admin/Member]ベースドメイン'
      it_behaves_like '[*][*][*][Owner/Admin/Member]存在するサブドメイン'
      it_behaves_like '[*][*][*][Owner/Admin/Member]存在しないサブドメイン'
    end
    shared_examples_for '[削除予約済み][Owner/Admin][所属]対象がMember' do
      let!(:user_code) { @create_users[2].code }
      let!(:target_member) { @create_members[2] }
      it_behaves_like '[削除予約済み][Owner/Admin][所属][Admin/Member]ベースドメイン'
      it_behaves_like '[*][*][*][Owner/Admin/Member]存在するサブドメイン'
      it_behaves_like '[*][*][*][Owner/Admin/Member]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][Member][所属]対象がMember' do
      let!(:user_code) { @create_users[2].code }
      let!(:target_member) { @create_members[2] }
      it_behaves_like '[ログイン中/削除予約済み][Member][所属][自分/Admin/Member]ベースドメイン'
      it_behaves_like '[*][*][*][Owner/Admin/Member]存在するサブドメイン'
      it_behaves_like '[*][*][*][Owner/Admin/Member]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][*][未所属/存在しない]対象がOwner' do
      let!(:user_code) { @create_outside_users[0].code }
      let!(:target_member) { @create_outside_members[0] }
      it_behaves_like '[未ログイン][*][未所属/存在しない][*]ベースドメイン'
      it_behaves_like '[*][*][*][Owner/Admin/Member]存在するサブドメイン'
      it_behaves_like '[*][*][*][Owner/Admin/Member]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][*][未所属/存在しない]対象がOwner' do
      let!(:user_code) { @create_outside_users[0].code }
      let!(:target_member) { @create_outside_members[0] }
      it_behaves_like '[ログイン中/削除予約済み][*][未所属/存在しない][Owner/Admin/Member]ベースドメイン'
      it_behaves_like '[*][*][*][Owner/Admin/Member]存在するサブドメイン'
      it_behaves_like '[*][*][*][Owner/Admin/Member]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][*][未所属/存在しない]対象がAdmin' do
      let!(:user_code) { @create_outside_users[1].code }
      let!(:target_member) { @create_outside_members[1] }
      it_behaves_like '[未ログイン][*][未所属/存在しない][*]ベースドメイン'
      it_behaves_like '[*][*][*][Owner/Admin/Member]存在するサブドメイン'
      it_behaves_like '[*][*][*][Owner/Admin/Member]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][*][未所属/存在しない]対象がAdmin' do
      let!(:user_code) { @create_outside_users[1].code }
      let!(:target_member) { @create_outside_members[1] }
      it_behaves_like '[ログイン中/削除予約済み][*][未所属/存在しない][Owner/Admin/Member]ベースドメイン'
      it_behaves_like '[*][*][*][Owner/Admin/Member]存在するサブドメイン'
      it_behaves_like '[*][*][*][Owner/Admin/Member]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][*][未所属/存在しない]対象がMember' do
      let!(:user_code) { @create_outside_users[2].code }
      let!(:target_member) { @create_outside_members[2] }
      it_behaves_like '[未ログイン][*][未所属/存在しない][*]ベースドメイン'
      it_behaves_like '[*][*][*][Owner/Admin/Member]存在するサブドメイン'
      it_behaves_like '[*][*][*][Owner/Admin/Member]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][*][未所属/存在しない]対象がMember' do
      let!(:user_code) { @create_outside_users[2].code }
      let!(:target_member) { @create_outside_members[2] }
      it_behaves_like '[ログイン中/削除予約済み][*][未所属/存在しない][Owner/Admin/Member]ベースドメイン'
      it_behaves_like '[*][*][*][Owner/Admin/Member]存在するサブドメイン'
      it_behaves_like '[*][*][*][Owner/Admin/Member]存在しないサブドメイン'
    end

    shared_examples_for '[ログイン中][Owner]顧客に所属' do
      let!(:customer_code) { customer.code }
      # it_behaves_like '[ログイン中][Owner][所属]対象がない' # Tips: 先にRoutingErrorになる
      it_behaves_like '[ログイン中/削除予約済み][Owner][所属]対象が自分'
      it_behaves_like '[ログイン中][Owner][所属]対象がOwner'
      it_behaves_like '[ログイン中][Owner/Admin][所属]対象がAdmin'
      it_behaves_like '[ログイン中][Owner/Admin][所属]対象がMember'
    end
    shared_examples_for '[削除予約済み][Owner]顧客に所属' do
      let!(:customer_code) { customer.code }
      # it_behaves_like '[削除予約済み][Owner][所属]対象がない' # Tips: 先にRoutingErrorになる
      it_behaves_like '[ログイン中/削除予約済み][Owner][所属]対象が自分'
      it_behaves_like '[削除予約済み][Owner][所属]対象がOwner'
      it_behaves_like '[削除予約済み][Owner/Admin][所属]対象がAdmin'
      it_behaves_like '[削除予約済み][Owner/Admin][所属]対象がMember'
    end
    shared_examples_for '[ログイン中][Admin]顧客に所属' do
      let!(:customer_code) { customer.code }
      # it_behaves_like '[ログイン中][Admin][所属]対象がない' # Tips: 先にRoutingErrorになる
      it_behaves_like '[ログイン中/削除予約済み][Admin][所属]対象が自分'
      it_behaves_like '[ログイン中/削除予約済み][Admin/Member][所属]対象がOwner'
      it_behaves_like '[ログイン中][Owner/Admin][所属]対象がAdmin'
      it_behaves_like '[ログイン中][Owner/Admin][所属]対象がMember'
    end
    shared_examples_for '[削除予約済み][Admin]顧客に所属' do
      let!(:customer_code) { customer.code }
      # it_behaves_like '[削除予約済み][Admin][所属]対象がない' # Tips: 先にRoutingErrorになる
      it_behaves_like '[ログイン中/削除予約済み][Admin][所属]対象が自分'
      it_behaves_like '[ログイン中/削除予約済み][Admin/Member][所属]対象がOwner'
      it_behaves_like '[削除予約済み][Owner/Admin][所属]対象がAdmin'
      it_behaves_like '[削除予約済み][Owner/Admin][所属]対象がMember'
    end
    shared_examples_for '[ログイン中/削除予約済み][Member]顧客に所属' do
      let!(:customer_code) { customer.code }
      # it_behaves_like '[ログイン中/削除予約済み][Member][所属]対象がない' # Tips: 先にRoutingErrorになる
      it_behaves_like '[ログイン中/削除予約済み][Member][所属]対象が自分'
      it_behaves_like '[ログイン中/削除予約済み][Admin/Member][所属]対象がOwner'
      it_behaves_like '[ログイン中/削除予約済み][Member][所属]対象がAdmin'
      it_behaves_like '[ログイン中/削除予約済み][Member][所属]対象がMember'
    end
    shared_examples_for '[未ログイン][*]顧客に未所属' do
      let!(:customer_code) { outside_customer.code }
      # it_behaves_like '[未ログイン][*][未所属]対象がない' # Tips: 先にRoutingErrorになる
      # it_behaves_like '[未ログイン][*][未所属]対象が自分' # Tips: 未ログインの為、対象がない
      it_behaves_like '[未ログイン][*][未所属/存在しない]対象がOwner'
      it_behaves_like '[未ログイン][*][未所属/存在しない]対象がAdmin'
      it_behaves_like '[未ログイン][*][未所属/存在しない]対象がMember'
    end
    shared_examples_for '[ログイン中/削除予約済み][*]顧客に未所属' do
      let!(:customer_code) { outside_customer.code }
      # it_behaves_like '[ログイン中/削除予約済み][*][未所属]対象がない' # Tips: 先にRoutingErrorになる
      it_behaves_like '[ログイン中/削除予約済み][*][未所属/存在しない]対象が自分'
      it_behaves_like '[ログイン中/削除予約済み][*][未所属/存在しない]対象がOwner'
      it_behaves_like '[ログイン中/削除予約済み][*][未所属/存在しない]対象がAdmin'
      it_behaves_like '[ログイン中/削除予約済み][*][未所属/存在しない]対象がMember'
    end
    shared_examples_for '[未ログイン][*]顧客が存在しない' do
      let!(:customer_code) { NOT_CUSTOMER_CODE }
      # it_behaves_like '[未ログイン][*][存在しない]対象がない' # Tips: 先にRoutingErrorになる
      # it_behaves_like '[未ログイン][*][存在しない]対象が自分' # Tips: 未ログインの為、対象がない
      it_behaves_like '[未ログイン][*][未所属/存在しない]対象がOwner'
      it_behaves_like '[未ログイン][*][未所属/存在しない]対象がAdmin'
      it_behaves_like '[未ログイン][*][未所属/存在しない]対象がMember'
    end
    shared_examples_for '[ログイン中/削除予約済み][*]顧客が存在しない' do
      let!(:customer_code) { NOT_CUSTOMER_CODE }
      # it_behaves_like '[ログイン中/削除予約済み][*][存在しない]対象がない' # Tips: 先にRoutingErrorになる
      it_behaves_like '[ログイン中/削除予約済み][*][未所属/存在しない]対象が自分'
      it_behaves_like '[ログイン中/削除予約済み][*][未所属/存在しない]対象がOwner'
      it_behaves_like '[ログイン中/削除予約済み][*][未所属/存在しない]対象がAdmin'
      it_behaves_like '[ログイン中/削除予約済み][*][未所属/存在しない]対象がMember'
    end

    shared_examples_for '[ログイン中]権限がOwner' do
      include_context '顧客・ユーザー紐付け', Time.current, :Owner
      it_behaves_like '[ログイン中][Owner]顧客に所属'
      it_behaves_like '[ログイン中/削除予約済み][*]顧客に未所属'
      it_behaves_like '[ログイン中/削除予約済み][*]顧客が存在しない'
      # it_behaves_like '[ログイン中][Owner]顧客がない' # Tips: 先にRoutingErrorになる
    end
    shared_examples_for '[削除予約済み]権限がOwner' do
      include_context '顧客・ユーザー紐付け', Time.current, :Owner
      it_behaves_like '[削除予約済み][Owner]顧客に所属'
      it_behaves_like '[ログイン中/削除予約済み][*]顧客に未所属'
      it_behaves_like '[ログイン中/削除予約済み][*]顧客が存在しない'
      # it_behaves_like '[削除予約済み][Owner]顧客がない' # Tips: 先にRoutingErrorになる
    end
    shared_examples_for '[ログイン中]権限がAdmin' do
      include_context '顧客・ユーザー紐付け', Time.current, :Admin
      it_behaves_like '[ログイン中][Admin]顧客に所属'
      it_behaves_like '[ログイン中/削除予約済み][*]顧客に未所属'
      it_behaves_like '[ログイン中/削除予約済み][*]顧客が存在しない'
      # it_behaves_like '[ログイン中][Admin]顧客がない' # Tips: 先にRoutingErrorになる
    end
    shared_examples_for '[削除予約済み]権限がAdmin' do
      include_context '顧客・ユーザー紐付け', Time.current, :Admin
      it_behaves_like '[削除予約済み][Admin]顧客に所属'
      it_behaves_like '[ログイン中/削除予約済み][*]顧客に未所属'
      it_behaves_like '[ログイン中/削除予約済み][*]顧客が存在しない'
      # it_behaves_like '[削除予約済み][Admin]顧客がない' # Tips: 先にRoutingErrorになる
    end
    shared_examples_for '[ログイン中/削除予約済み]権限がMember' do
      include_context '顧客・ユーザー紐付け', Time.current, :Member
      it_behaves_like '[ログイン中/削除予約済み][Member]顧客に所属'
      it_behaves_like '[ログイン中/削除予約済み][*]顧客に未所属'
      it_behaves_like '[ログイン中/削除予約済み][*]顧客が存在しない'
      # it_behaves_like '[ログイン中/削除予約済み][Member]顧客がない' # Tips: 先にRoutingErrorになる
    end
    shared_examples_for '[未ログイン]権限がない' do
      # it_behaves_like '[未ログイン][ない]顧客に所属' # Tips: 権限がないの為、顧客に所属がない
      it_behaves_like '[未ログイン][*]顧客に未所属'
      it_behaves_like '[未ログイン][*]顧客が存在しない'
      # it_behaves_like '[未ログイン][ない]顧客がない' # Tips: 先にRoutingErrorになる
    end
    shared_examples_for '[ログイン中/削除予約済み]権限がない' do
      # it_behaves_like '[ログイン中/削除予約済み][ない]顧客に所属' # Tips: 権限がないの為、顧客に所属がない
      it_behaves_like '[ログイン中/削除予約済み][*]顧客に未所属'
      it_behaves_like '[ログイン中/削除予約済み][*]顧客が存在しない'
      # it_behaves_like '[ログイン中/削除予約済み][ない]顧客がない' # Tips: 先にRoutingErrorになる
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
