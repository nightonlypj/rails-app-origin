require 'rails_helper'

RSpec.describe 'Members', type: :request do
  include_context 'リクエストスペース作成'

  # PATCH/PUT /members/:customer_code/:user_code（ベースドメイン） メンバー権限変更(処理)
  # PATCH/PUT /members/:customer_code/:user_code.json（ベースドメイン） メンバー権限変更API
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   権限なし, Owner権限, Admin権限, Member権限 → データ作成
  #   所属顧客, 未所属顧客, 存在しない顧客, 顧客なし → 事前にデータ作成
  #   対象なし, 対象自分, 対象Owner, 対象Admin, 対象Member → 事前にデータ作成
  #   ベースドメイン, 存在するサブドメイン, 存在しないサブドメイン → 事前にデータ作成
  describe 'PATCH /destroy' do
    include_context 'メンバー作成', 1, 1, 1, 0, 'ASC'
    include_context '対象外メンバー作成', 'ASC'

    # テスト内容
    shared_examples_for 'OK' do
      it 'メンバーが削除される' do
        expect do
          delete member_path(customer_code: customer_code, user_code: user_code), headers: headers
        end.to change(Member, :count).by(-1)
      end
      it '(json)メンバーが削除される' do
        expect do
          delete member_path(customer_code: customer_code, user_code: user_code, format: :json), headers: headers
        end.to change(Member, :count).by(-1)
      end
    end
    shared_examples_for 'NG' do
      it 'メンバーが削除されない' do
        if target_member.present?
          expect do
            delete member_path(customer_code: customer_code, user_code: user_code), headers: headers
          end.to change(Member, :count).by(0)
        end
      end
      it '(json)メンバーが削除されない' do
        if target_member.present?
          expect do
            delete member_path(customer_code: customer_code, user_code: user_code, format: :json), headers: headers
          end.to change(Member, :count).by(0)
        end
      end
    end

    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        delete member_path(customer_code: customer_code, user_code: user_code), headers: headers
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToNG' do |error|
      it '存在しないステータス' do
        delete member_path(customer_code: customer_code, user_code: user_code), headers: headers
        expect(response).to be_not_found
      end
      it '(json)存在しないエラー' do
        delete member_path(customer_code: customer_code, user_code: user_code, format: :json), headers: headers
        expect(response).to be_not_found
        expect(JSON.parse(response.body)['error']).to error.present? ? eq(I18n.t(error)) : be_nil
      end
    end
    shared_examples_for 'ToIndexOK' do |alert, notice|
      it '一覧にリダイレクト' do
        delete member_path(customer_code: customer_code, user_code: user_code), headers: headers
        expect(response).to redirect_to(members_path(customer_code: customer_code))
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
      it '(json)成功レスポンス' do
        delete member_path(customer_code: customer_code, user_code: user_code, format: :json), headers: headers
        expect(response).to be_ok
        expect(JSON.parse(response.body)['status']).to eq('OK')
        expect(JSON.parse(response.body)['notice']).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToIndexNG' do |alert, notice, error|
      it '一覧にリダイレクト' do
        delete member_path(customer_code: customer_code, user_code: user_code), headers: headers
        expect(response).to redirect_to(members_path(customer_code: customer_code))
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
      it '(json)権限エラー' do
        delete member_path(customer_code: customer_code, user_code: user_code, format: :json), headers: headers
        expect(response).to be_forbidden
        expect(JSON.parse(response.body)['error']).to error.present? ? eq(I18n.t(error)) : be_nil
      end
    end
    shared_examples_for 'ToLogin' do |alert, notice, error|
      it 'ログインにリダイレクト' do
        delete member_path(customer_code: customer_code, user_code: user_code), headers: headers
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
      it '(json)認証エラー' do
        delete member_path(customer_code: customer_code, user_code: user_code, format: :json), headers: headers
        expect(response).to be_unauthorized
        expect(JSON.parse(response.body)['error']).to error.present? ? eq(I18n.t(error)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[ログイン中/削除予約済み][Owner権限][所属顧客][対象自分]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToIndexNG', 'alert.member.own_destroy_power.owner', nil, 'alert.member.own_destroy_power.owner'
    end
    shared_examples_for '[ログイン中/削除予約済み][Admin権限][所属顧客][対象自分]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToIndexNG', 'alert.member.own_destroy_power.admin', nil, 'alert.member.own_destroy_power.admin'
    end
    shared_examples_for '[ログイン中/削除予約済み][Member権限][所属顧客][対象自分/Admin/Member]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToIndexNG', 'alert.member.not_destroy_power.admin', nil, 'alert.member.not_destroy_power.admin'
    end
    shared_examples_for '[ログイン中][Owner権限][所属顧客][対象Owner]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'OK'
      it_behaves_like 'ToIndexOK', nil, 'notice.member.destroy', 'notice.member.destroy'
    end
    shared_examples_for '[削除予約済み][Owner権限][所属顧客][対象Owner]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToIndexNG', 'alert.user.destroy_reserved', nil, 'alert.user.destroy_reserved'
    end
    shared_examples_for '[ログイン中/削除予約済み][Admin権限/Member][所属顧客][対象Owner]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToIndexNG', 'alert.member.not_destroy_power.owner', nil, 'alert.member.not_destroy_power.owner'
    end
    shared_examples_for '[ログイン中][Owner権限/Admin][所属顧客][対象Admin/Member]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'OK'
      it_behaves_like 'ToIndexOK', nil, 'notice.member.destroy', 'notice.member.destroy'
    end
    shared_examples_for '[削除予約済み][Owner権限/Admin][所属顧客][対象Admin/Member]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToIndexNG', 'alert.user.destroy_reserved', nil, 'alert.user.destroy_reserved'
    end
    shared_examples_for '[未ログイン][未所属顧客/存在しない顧客]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToLogin', 'devise.failure.unauthenticated', nil, 'devise.failure.unauthenticated'
    end
    shared_examples_for '[ログイン中/削除予約済み][未所属顧客/存在しない顧客][対象自分]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      # it_behaves_like 'NG' # Tips: 権限がない為、紐付かない
      it_behaves_like 'ToNG', 'errors.messages.customer_code_error'
    end
    shared_examples_for '[ログイン中/削除予約済み][未所属顧客/存在しない顧客][対象Owner/Admin/Member]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 'errors.messages.customer_code_error'
    end
    shared_examples_for '[対象自分]存在するサブドメイン' do
      let!(:headers) { @space_header }
      # it_behaves_like 'NG' # Tips: 権限がない為、紐付かない
      it_behaves_like 'ToNG', 'errors.messages.domain_error'
    end
    shared_examples_for '[対象Owner/Admin/Member]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 'errors.messages.domain_error'
    end
    shared_examples_for '[対象自分]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      # it_behaves_like 'NG' # Tips: 権限がない為、紐付かない
      it_behaves_like 'ToNG', 'errors.messages.domain_error'
    end
    shared_examples_for '[対象Owner/Admin/Member]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG', 'errors.messages.domain_error'
    end

    shared_examples_for '[ログイン中/削除予約済み][Owner権限][所属顧客]対象自分' do
      let!(:user_code) { user.code }
      let!(:target_member) { member }
      it_behaves_like '[ログイン中/削除予約済み][Owner権限][所属顧客][対象自分]ベースドメイン'
      it_behaves_like '[対象Owner/Admin/Member]存在するサブドメイン'
      it_behaves_like '[対象Owner/Admin/Member]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][Admin権限][所属顧客]対象自分' do
      let!(:user_code) { user.code }
      let!(:target_member) { member }
      it_behaves_like '[ログイン中/削除予約済み][Admin権限][所属顧客][対象自分]ベースドメイン'
      it_behaves_like '[対象Owner/Admin/Member]存在するサブドメイン'
      it_behaves_like '[対象Owner/Admin/Member]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][Member権限][所属顧客]対象自分' do
      let!(:user_code) { user.code }
      let!(:target_member) { member }
      it_behaves_like '[ログイン中/削除予約済み][Member権限][所属顧客][対象自分/Admin/Member]ベースドメイン'
      it_behaves_like '[対象Owner/Admin/Member]存在するサブドメイン'
      it_behaves_like '[対象Owner/Admin/Member]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][未所属顧客/存在しない顧客]対象自分' do
      let!(:user_code) { user.code }
      let!(:target_member) { nil } # Tips: 権限がない為、紐付かない
      it_behaves_like '[ログイン中/削除予約済み][未所属顧客/存在しない顧客][対象自分]ベースドメイン'
      it_behaves_like '[対象自分]存在するサブドメイン'
      it_behaves_like '[対象自分]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中][Owner権限][所属顧客]対象Owner' do
      let!(:user_code) { @create_users[0].code }
      let!(:target_member) { @create_members[0] }
      it_behaves_like '[ログイン中][Owner権限][所属顧客][対象Owner]ベースドメイン'
      it_behaves_like '[対象Owner/Admin/Member]存在するサブドメイン'
      it_behaves_like '[対象Owner/Admin/Member]存在しないサブドメイン'
    end
    shared_examples_for '[削除予約済み][Owner権限][所属顧客]対象Owner' do
      let!(:user_code) { @create_users[0].code }
      let!(:target_member) { @create_members[0] }
      it_behaves_like '[削除予約済み][Owner権限][所属顧客][対象Owner]ベースドメイン'
      it_behaves_like '[対象Owner/Admin/Member]存在するサブドメイン'
      it_behaves_like '[対象Owner/Admin/Member]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][Admin権限/Member][所属顧客]対象Owner' do
      let!(:user_code) { @create_users[0].code }
      let!(:target_member) { @create_members[0] }
      it_behaves_like '[ログイン中/削除予約済み][Admin権限/Member][所属顧客][対象Owner]ベースドメイン'
      it_behaves_like '[対象Owner/Admin/Member]存在するサブドメイン'
      it_behaves_like '[対象Owner/Admin/Member]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中][Owner権限/Admin][所属顧客]対象Admin' do
      let!(:user_code) { @create_users[1].code }
      let!(:target_member) { @create_members[1] }
      it_behaves_like '[ログイン中][Owner権限/Admin][所属顧客][対象Admin/Member]ベースドメイン'
      it_behaves_like '[対象Owner/Admin/Member]存在するサブドメイン'
      it_behaves_like '[対象Owner/Admin/Member]存在しないサブドメイン'
    end
    shared_examples_for '[削除予約済み][Owner権限/Admin][所属顧客]対象Admin' do
      let!(:user_code) { @create_users[1].code }
      let!(:target_member) { @create_members[1] }
      it_behaves_like '[削除予約済み][Owner権限/Admin][所属顧客][対象Admin/Member]ベースドメイン'
      it_behaves_like '[対象Owner/Admin/Member]存在するサブドメイン'
      it_behaves_like '[対象Owner/Admin/Member]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][Member権限][所属顧客]対象Admin' do
      let!(:user_code) { @create_users[1].code }
      let!(:target_member) { @create_members[1] }
      it_behaves_like '[ログイン中/削除予約済み][Member権限][所属顧客][対象自分/Admin/Member]ベースドメイン'
      it_behaves_like '[対象Owner/Admin/Member]存在するサブドメイン'
      it_behaves_like '[対象Owner/Admin/Member]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中][Owner権限/Admin][所属顧客]対象Member' do
      let!(:user_code) { @create_users[2].code }
      let!(:target_member) { @create_members[2] }
      it_behaves_like '[ログイン中][Owner権限/Admin][所属顧客][対象Admin/Member]ベースドメイン'
      it_behaves_like '[対象Owner/Admin/Member]存在するサブドメイン'
      it_behaves_like '[対象Owner/Admin/Member]存在しないサブドメイン'
    end
    shared_examples_for '[削除予約済み][Owner権限/Admin][所属顧客]対象Member' do
      let!(:user_code) { @create_users[2].code }
      let!(:target_member) { @create_members[2] }
      it_behaves_like '[削除予約済み][Owner権限/Admin][所属顧客][対象Admin/Member]ベースドメイン'
      it_behaves_like '[対象Owner/Admin/Member]存在するサブドメイン'
      it_behaves_like '[対象Owner/Admin/Member]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][Member権限][所属顧客]対象Member' do
      let!(:user_code) { @create_users[2].code }
      let!(:target_member) { @create_members[2] }
      it_behaves_like '[ログイン中/削除予約済み][Member権限][所属顧客][対象自分/Admin/Member]ベースドメイン'
      it_behaves_like '[対象Owner/Admin/Member]存在するサブドメイン'
      it_behaves_like '[対象Owner/Admin/Member]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][未所属顧客/存在しない顧客]対象Owner' do
      let!(:user_code) { @create_outside_users[0].code }
      let!(:target_member) { @create_outside_members[0] }
      it_behaves_like '[未ログイン][未所属顧客/存在しない顧客]ベースドメイン'
      it_behaves_like '[対象Owner/Admin/Member]存在するサブドメイン'
      it_behaves_like '[対象Owner/Admin/Member]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][未所属顧客/存在しない顧客]対象Owner' do
      let!(:user_code) { @create_outside_users[0].code }
      let!(:target_member) { @create_outside_members[0] }
      it_behaves_like '[ログイン中/削除予約済み][未所属顧客/存在しない顧客][対象Owner/Admin/Member]ベースドメイン'
      it_behaves_like '[対象Owner/Admin/Member]存在するサブドメイン'
      it_behaves_like '[対象Owner/Admin/Member]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][未所属顧客/存在しない顧客]対象Admin' do
      let!(:user_code) { @create_outside_users[1].code }
      let!(:target_member) { @create_outside_members[1] }
      it_behaves_like '[未ログイン][未所属顧客/存在しない顧客]ベースドメイン'
      it_behaves_like '[対象Owner/Admin/Member]存在するサブドメイン'
      it_behaves_like '[対象Owner/Admin/Member]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][未所属顧客/存在しない顧客]対象Admin' do
      let!(:user_code) { @create_outside_users[1].code }
      let!(:target_member) { @create_outside_members[1] }
      it_behaves_like '[ログイン中/削除予約済み][未所属顧客/存在しない顧客][対象Owner/Admin/Member]ベースドメイン'
      it_behaves_like '[対象Owner/Admin/Member]存在するサブドメイン'
      it_behaves_like '[対象Owner/Admin/Member]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][未所属顧客/存在しない顧客]対象Member' do
      let!(:user_code) { @create_outside_users[2].code }
      let!(:target_member) { @create_outside_members[2] }
      it_behaves_like '[未ログイン][未所属顧客/存在しない顧客]ベースドメイン'
      it_behaves_like '[対象Owner/Admin/Member]存在するサブドメイン'
      it_behaves_like '[対象Owner/Admin/Member]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][未所属顧客/存在しない顧客]対象Member' do
      let!(:user_code) { @create_outside_users[2].code }
      let!(:target_member) { @create_outside_members[2] }
      it_behaves_like '[ログイン中/削除予約済み][未所属顧客/存在しない顧客][対象Owner/Admin/Member]ベースドメイン'
      it_behaves_like '[対象Owner/Admin/Member]存在するサブドメイン'
      it_behaves_like '[対象Owner/Admin/Member]存在しないサブドメイン'
    end

    shared_examples_for '[ログイン中][Owner権限]所属顧客' do
      let!(:customer_code) { customer.code }
      # it_behaves_like '[ログイン中][Owner権限][所属顧客]対象なし' # Tips: 先にRoutingErrorになる
      it_behaves_like '[ログイン中/削除予約済み][Owner権限][所属顧客]対象自分'
      it_behaves_like '[ログイン中][Owner権限][所属顧客]対象Owner'
      it_behaves_like '[ログイン中][Owner権限/Admin][所属顧客]対象Admin'
      it_behaves_like '[ログイン中][Owner権限/Admin][所属顧客]対象Member'
    end
    shared_examples_for '[削除予約済み][Owner権限]所属顧客' do
      let!(:customer_code) { customer.code }
      # it_behaves_like '[削除予約済み][Owner権限][所属顧客]対象なし' # Tips: 先にRoutingErrorになる
      it_behaves_like '[ログイン中/削除予約済み][Owner権限][所属顧客]対象自分'
      it_behaves_like '[削除予約済み][Owner権限][所属顧客]対象Owner'
      it_behaves_like '[削除予約済み][Owner権限/Admin][所属顧客]対象Admin'
      it_behaves_like '[削除予約済み][Owner権限/Admin][所属顧客]対象Member'
    end
    shared_examples_for '[ログイン中][Admin権限]所属顧客' do
      let!(:customer_code) { customer.code }
      # it_behaves_like '[ログイン中][Admin権限][所属顧客]対象なし' # Tips: 先にRoutingErrorになる
      it_behaves_like '[ログイン中/削除予約済み][Admin権限][所属顧客]対象自分'
      it_behaves_like '[ログイン中/削除予約済み][Admin権限/Member][所属顧客]対象Owner'
      it_behaves_like '[ログイン中][Owner権限/Admin][所属顧客]対象Admin'
      it_behaves_like '[ログイン中][Owner権限/Admin][所属顧客]対象Member'
    end
    shared_examples_for '[削除予約済み][Admin権限]所属顧客' do
      let!(:customer_code) { customer.code }
      # it_behaves_like '[削除予約済み][Admin権限][所属顧客]対象なし' # Tips: 先にRoutingErrorになる
      it_behaves_like '[ログイン中/削除予約済み][Admin権限][所属顧客]対象自分'
      it_behaves_like '[ログイン中/削除予約済み][Admin権限/Member][所属顧客]対象Owner'
      it_behaves_like '[削除予約済み][Owner権限/Admin][所属顧客]対象Admin'
      it_behaves_like '[削除予約済み][Owner権限/Admin][所属顧客]対象Member'
    end
    shared_examples_for '[ログイン中/削除予約済み][Member権限]所属顧客' do
      let!(:customer_code) { customer.code }
      # it_behaves_like '[ログイン中/削除予約済み][Member権限][所属顧客]対象なし' # Tips: 先にRoutingErrorになる
      it_behaves_like '[ログイン中/削除予約済み][Member権限][所属顧客]対象自分'
      it_behaves_like '[ログイン中/削除予約済み][Admin権限/Member][所属顧客]対象Owner'
      it_behaves_like '[ログイン中/削除予約済み][Member権限][所属顧客]対象Admin'
      it_behaves_like '[ログイン中/削除予約済み][Member権限][所属顧客]対象Member'
    end
    shared_examples_for '[未ログイン]未所属顧客' do
      let!(:customer_code) { outside_customer.code }
      # it_behaves_like '[未ログイン][未所属顧客]対象なし' # Tips: 先にRoutingErrorになる
      # it_behaves_like '[未ログイン][未所属顧客]対象自分' # Tips: 未ログインの為、対象自分なし
      it_behaves_like '[未ログイン][未所属顧客/存在しない顧客]対象Owner'
      it_behaves_like '[未ログイン][未所属顧客/存在しない顧客]対象Admin'
      it_behaves_like '[未ログイン][未所属顧客/存在しない顧客]対象Member'
    end
    shared_examples_for '[ログイン中/削除予約済み]未所属顧客' do
      let!(:customer_code) { outside_customer.code }
      # it_behaves_like '[ログイン中/削除予約済み][未所属顧客]対象なし' # Tips: 先にRoutingErrorになる
      it_behaves_like '[ログイン中/削除予約済み][未所属顧客/存在しない顧客]対象自分'
      it_behaves_like '[ログイン中/削除予約済み][未所属顧客/存在しない顧客]対象Owner'
      it_behaves_like '[ログイン中/削除予約済み][未所属顧客/存在しない顧客]対象Admin'
      it_behaves_like '[ログイン中/削除予約済み][未所属顧客/存在しない顧客]対象Member'
    end
    shared_examples_for '[未ログイン]存在しない顧客' do
      let!(:customer_code) { NOT_CUSTOMER_CODE }
      # it_behaves_like '[未ログイン][存在しない顧客]対象なし' # Tips: 先にRoutingErrorになる
      # it_behaves_like '[未ログイン][存在しない顧客]対象自分' # Tips: 未ログインの為、対象自分なし
      it_behaves_like '[未ログイン][未所属顧客/存在しない顧客]対象Owner'
      it_behaves_like '[未ログイン][未所属顧客/存在しない顧客]対象Admin'
      it_behaves_like '[未ログイン][未所属顧客/存在しない顧客]対象Member'
    end
    shared_examples_for '[ログイン中/削除予約済み]存在しない顧客' do
      let!(:customer_code) { NOT_CUSTOMER_CODE }
      # it_behaves_like '[ログイン中/削除予約済み][存在しない顧客]対象なし' # Tips: 先にRoutingErrorになる
      it_behaves_like '[ログイン中/削除予約済み][未所属顧客/存在しない顧客]対象自分'
      it_behaves_like '[ログイン中/削除予約済み][未所属顧客/存在しない顧客]対象Owner'
      it_behaves_like '[ログイン中/削除予約済み][未所属顧客/存在しない顧客]対象Admin'
      it_behaves_like '[ログイン中/削除予約済み][未所属顧客/存在しない顧客]対象Member'
    end

    shared_examples_for '[未ログイン]権限なし' do
      # it_behaves_like '[未ログイン][権限なし]所属顧客' # Tips: 権限なしの為、所属顧客なし
      it_behaves_like '[未ログイン]未所属顧客'
      it_behaves_like '[未ログイン]存在しない顧客'
      # it_behaves_like '[未ログイン][権限なし]顧客なし' # Tips: 先にRoutingErrorになる
    end
    shared_examples_for '[ログイン中/削除予約済み]権限なし' do
      # it_behaves_like '[ログイン中/削除予約済み][権限なし]所属顧客' # Tips: 権限なしの為、所属顧客なし
      it_behaves_like '[ログイン中/削除予約済み]未所属顧客'
      it_behaves_like '[ログイン中/削除予約済み]存在しない顧客'
      # it_behaves_like '[ログイン中/削除予約済み][権限なし]顧客なし' # Tips: 先にRoutingErrorになる
    end
    shared_examples_for '[ログイン中]Owner権限' do
      include_context '顧客・ユーザー紐付け', Time.current, :Owner
      it_behaves_like '[ログイン中][Owner権限]所属顧客'
      it_behaves_like '[ログイン中/削除予約済み]未所属顧客'
      it_behaves_like '[ログイン中/削除予約済み]存在しない顧客'
      # it_behaves_like '[ログイン中][Owner権限]顧客なし' # Tips: 先にRoutingErrorになる
    end
    shared_examples_for '[削除予約済み]Owner権限' do
      include_context '顧客・ユーザー紐付け', Time.current, :Owner
      it_behaves_like '[削除予約済み][Owner権限]所属顧客'
      it_behaves_like '[ログイン中/削除予約済み]未所属顧客'
      it_behaves_like '[ログイン中/削除予約済み]存在しない顧客'
      # it_behaves_like '[削除予約済み][Owner権限]顧客なし' # Tips: 先にRoutingErrorになる
    end
    shared_examples_for '[ログイン中]Admin権限' do
      include_context '顧客・ユーザー紐付け', Time.current, :Admin
      it_behaves_like '[ログイン中][Admin権限]所属顧客'
      it_behaves_like '[ログイン中/削除予約済み]未所属顧客'
      it_behaves_like '[ログイン中/削除予約済み]存在しない顧客'
      # it_behaves_like '[ログイン中][Admin権限]顧客なし' # Tips: 先にRoutingErrorになる
    end
    shared_examples_for '[削除予約済み]Admin権限' do
      include_context '顧客・ユーザー紐付け', Time.current, :Admin
      it_behaves_like '[削除予約済み][Admin権限]所属顧客'
      it_behaves_like '[ログイン中/削除予約済み]未所属顧客'
      it_behaves_like '[ログイン中/削除予約済み]存在しない顧客'
      # it_behaves_like '[削除予約済み][Admin権限]顧客なし' # Tips: 先にRoutingErrorになる
    end
    shared_examples_for '[ログイン中/削除予約済み]Member権限' do
      include_context '顧客・ユーザー紐付け', Time.current, :Member
      it_behaves_like '[ログイン中/削除予約済み][Member権限]所属顧客'
      it_behaves_like '[ログイン中/削除予約済み]未所属顧客'
      it_behaves_like '[ログイン中/削除予約済み]存在しない顧客'
      # it_behaves_like '[ログイン中/削除予約済み][Member権限]顧客なし' # Tips: 先にRoutingErrorになる
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]権限なし'
      # it_behaves_like '[未ログイン]Owner権限' # Tips: 未ログインの為、権限なし
      # it_behaves_like '[未ログイン]Admin権限' # Tips: 未ログインの為、権限なし
      # it_behaves_like '[未ログイン]Member権限' # Tips: 未ログインの為、権限なし
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中/削除予約済み]権限なし'
      it_behaves_like '[ログイン中]Owner権限'
      it_behaves_like '[ログイン中]Admin権限'
      it_behaves_like '[ログイン中/削除予約済み]Member権限'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[ログイン中/削除予約済み]権限なし'
      it_behaves_like '[削除予約済み]Owner権限'
      it_behaves_like '[削除予約済み]Admin権限'
      it_behaves_like '[ログイン中/削除予約済み]Member権限'
    end
  end
end
