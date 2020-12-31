require 'rails_helper'

RSpec.describe 'Members', type: :request do
  include_context 'リクエストスペース作成'

  # GET /members/:customer_code/:user_code/delete（ベースドメイン） メンバー解除
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   権限なし, Owner権限, Admin権限, Member権限 → データ作成
  #   所属顧客, 未所属顧客, 存在しない顧客, 顧客なし → 事前にデータ作成
  #   対象なし, 対象自分, 対象Owner, 対象Admin, 対象Member → 事前にデータ作成
  #   ベースドメイン, 存在するサブドメイン, 存在しないサブドメイン → 事前にデータ作成
  describe 'GET /delete' do
    include_context 'メンバー作成', 1, 1, 1, 0, 'ASC'
    include_context '対象外メンバー作成', 'ASC'

    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get delete_member_path(customer_code: customer_code, user_code: user_code), headers: headers
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToNG' do
      it '存在しないステータス' do
        get delete_member_path(customer_code: customer_code, user_code: user_code), headers: headers
        expect(response).to be_not_found
      end
    end
    shared_examples_for 'ToIndex' do |alert, notice|
      it '一覧にリダイレクト' do
        get delete_member_path(customer_code: customer_code, user_code: user_code), headers: headers
        expect(response).to redirect_to(members_path(customer_code: customer_code))
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToLogin' do |alert, notice|
      it 'ログインにリダイレクト' do
        get delete_member_path(customer_code: customer_code, user_code: user_code), headers: headers
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToBase' do |alert, notice|
      it 'ベースドメインにリダイレクト' do
        get delete_member_path(customer_code: customer_code, user_code: user_code), headers: headers
        expect(response).to redirect_to("//#{Settings['base_domain']}#{delete_member_path(customer_code: customer_code, user_code: user_code)}")
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[ログイン中/削除予約済み][Owner権限][所属顧客][対象自分]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToIndex', 'alert.member.own_destroy_power.owner', nil
    end
    shared_examples_for '[ログイン中/削除予約済み][Admin権限][所属顧客][対象自分]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToIndex', 'alert.member.own_destroy_power.admin', nil
    end
    shared_examples_for '[ログイン中/削除予約済み][Member権限][所属顧客][対象自分/Admin/Member]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToIndex', 'alert.member.not_destroy_power.admin', nil
    end
    shared_examples_for '[ログイン中][Owner権限][所属顧客][対象Owner]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[削除予約済み][Owner権限][所属顧客][対象Owner]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToIndex', 'alert.user.destroy_reserved', nil
    end
    shared_examples_for '[ログイン中/削除予約済み][Admin権限/Member][所属顧客][対象Owner]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToIndex', 'alert.member.not_destroy_power.owner', nil
    end
    shared_examples_for '[ログイン中][Owner権限/Admin][所属顧客][対象Admin/Member]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[削除予約済み][Owner権限/Admin][所属顧客][対象Admin/Member]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToIndex', 'alert.user.destroy_reserved', nil
    end
    shared_examples_for '[未ログイン][未所属顧客/存在しない顧客]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToLogin', 'devise.failure.unauthenticated', nil
    end
    shared_examples_for '[ログイン中/削除予約済み][未所属顧客/存在しない顧客]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToNG'
    end
    shared_examples_for '存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'ToBase', nil, nil
    end
    shared_examples_for '存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      it_behaves_like 'ToBase', nil, nil
    end

    shared_examples_for '[ログイン中/削除予約済み][Owner権限][所属顧客]対象自分' do
      let!(:user_code) { user.code }
      it_behaves_like '[ログイン中/削除予約済み][Owner権限][所属顧客][対象自分]ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][Admin権限][所属顧客]対象自分' do
      let!(:user_code) { user.code }
      it_behaves_like '[ログイン中/削除予約済み][Admin権限][所属顧客][対象自分]ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][Member権限][所属顧客]対象自分' do
      let!(:user_code) { user.code }
      it_behaves_like '[ログイン中/削除予約済み][Member権限][所属顧客][対象自分/Admin/Member]ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][未所属顧客]対象自分' do
      let!(:user_code) { user.code }
      it_behaves_like '[ログイン中/削除予約済み][未所属顧客/存在しない顧客]ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][存在しない顧客]対象自分' do
      let!(:user_code) { user.code }
      it_behaves_like '[ログイン中/削除予約済み][未所属顧客/存在しない顧客]ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中][Owner権限][所属顧客]対象Owner' do
      let!(:user_code) { @create_users[0].code }
      it_behaves_like '[ログイン中][Owner権限][所属顧客][対象Owner]ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
    shared_examples_for '[削除予約済み][Owner権限][所属顧客]対象Owner' do
      let!(:user_code) { @create_users[0].code }
      it_behaves_like '[削除予約済み][Owner権限][所属顧客][対象Owner]ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][Admin権限/Member][所属顧客]対象Owner' do
      let!(:user_code) { @create_users[0].code }
      it_behaves_like '[ログイン中/削除予約済み][Admin権限/Member][所属顧客][対象Owner]ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中][Owner権限/Admin][所属顧客]対象Admin' do
      let!(:user_code) { @create_users[1].code }
      it_behaves_like '[ログイン中][Owner権限/Admin][所属顧客][対象Admin/Member]ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
    shared_examples_for '[削除予約済み][Owner権限/Admin][所属顧客]対象Admin' do
      let!(:user_code) { @create_users[1].code }
      it_behaves_like '[削除予約済み][Owner権限/Admin][所属顧客][対象Admin/Member]ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][Member権限][所属顧客]対象Admin' do
      let!(:user_code) { @create_users[1].code }
      it_behaves_like '[ログイン中/削除予約済み][Member権限][所属顧客][対象自分/Admin/Member]ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中][Owner権限/Admin][所属顧客]対象Member' do
      let!(:user_code) { @create_users[2].code }
      it_behaves_like '[ログイン中][Owner権限/Admin][所属顧客][対象Admin/Member]ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
    shared_examples_for '[削除予約済み][Owner権限/Admin][所属顧客]対象Member' do
      let!(:user_code) { @create_users[2].code }
      it_behaves_like '[削除予約済み][Owner権限/Admin][所属顧客][対象Admin/Member]ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][Member権限][所属顧客]対象Member' do
      let!(:user_code) { @create_users[2].code }
      it_behaves_like '[ログイン中/削除予約済み][Member権限][所属顧客][対象自分/Admin/Member]ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][未所属顧客]対象Owner' do
      let!(:user_code) { @create_outside_users[0].code }
      it_behaves_like '[未ログイン][未所属顧客/存在しない顧客]ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][存在しない顧客]対象Owner' do
      let!(:user_code) { @create_outside_users[0].code }
      it_behaves_like '[未ログイン][未所属顧客/存在しない顧客]ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][未所属顧客]対象Owner' do
      let!(:user_code) { @create_outside_users[0].code }
      it_behaves_like '[ログイン中/削除予約済み][未所属顧客/存在しない顧客]ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][存在しない顧客]対象Owner' do
      let!(:user_code) { @create_outside_users[0].code }
      it_behaves_like '[ログイン中/削除予約済み][未所属顧客/存在しない顧客]ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][未所属顧客]対象Admin' do
      let!(:user_code) { @create_outside_users[1].code }
      it_behaves_like '[未ログイン][未所属顧客/存在しない顧客]ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][存在しない顧客]対象Admin' do
      let!(:user_code) { @create_outside_users[1].code }
      it_behaves_like '[未ログイン][未所属顧客/存在しない顧客]ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][未所属顧客]対象Admin' do
      let!(:user_code) { @create_outside_users[1].code }
      it_behaves_like '[ログイン中/削除予約済み][未所属顧客/存在しない顧客]ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][存在しない顧客]対象Admin' do
      let!(:user_code) { @create_outside_users[1].code }
      it_behaves_like '[ログイン中/削除予約済み][未所属顧客/存在しない顧客]ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][未所属顧客]対象Member' do
      let!(:user_code) { @create_outside_users[2].code }
      it_behaves_like '[未ログイン][未所属顧客/存在しない顧客]ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][存在しない顧客]対象Member' do
      let!(:user_code) { @create_outside_users[2].code }
      it_behaves_like '[未ログイン][未所属顧客/存在しない顧客]ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][未所属顧客]対象Member' do
      let!(:user_code) { @create_outside_users[2].code }
      it_behaves_like '[ログイン中/削除予約済み][未所属顧客/存在しない顧客]ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][存在しない顧客]対象Member' do
      let!(:user_code) { @create_outside_users[2].code }
      it_behaves_like '[ログイン中/削除予約済み][未所属顧客/存在しない顧客]ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
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
      it_behaves_like '[未ログイン][未所属顧客]対象Owner'
      it_behaves_like '[未ログイン][未所属顧客]対象Admin'
      it_behaves_like '[未ログイン][未所属顧客]対象Member'
    end
    shared_examples_for '[ログイン中/削除予約済み]未所属顧客' do
      let!(:customer_code) { outside_customer.code }
      # it_behaves_like '[ログイン中/削除予約済み][未所属顧客]対象なし' # Tips: 先にRoutingErrorになる
      it_behaves_like '[ログイン中/削除予約済み][未所属顧客]対象自分'
      it_behaves_like '[ログイン中/削除予約済み][未所属顧客]対象Owner'
      it_behaves_like '[ログイン中/削除予約済み][未所属顧客]対象Admin'
      it_behaves_like '[ログイン中/削除予約済み][未所属顧客]対象Member'
    end
    shared_examples_for '[未ログイン]存在しない顧客' do
      let!(:customer_code) { NOT_CUSTOMER_CODE }
      # it_behaves_like '[未ログイン][未所属顧客]対象なし' # Tips: 先にRoutingErrorになる
      # it_behaves_like '[未ログイン][未所属顧客]対象自分' # Tips: 未ログインの為、対象自分なし
      it_behaves_like '[未ログイン][存在しない顧客]対象Owner'
      it_behaves_like '[未ログイン][存在しない顧客]対象Admin'
      it_behaves_like '[未ログイン][存在しない顧客]対象Member'
    end
    shared_examples_for '[ログイン中/削除予約済み]存在しない顧客' do
      let!(:customer_code) { NOT_CUSTOMER_CODE }
      # it_behaves_like '[ログイン中/削除予約済み][存在しない顧客]対象なし' # Tips: 先にRoutingErrorになる
      it_behaves_like '[ログイン中/削除予約済み][存在しない顧客]対象自分'
      it_behaves_like '[ログイン中/削除予約済み][存在しない顧客]対象Owner'
      it_behaves_like '[ログイン中/削除予約済み][存在しない顧客]対象Admin'
      it_behaves_like '[ログイン中/削除予約済み][存在しない顧客]対象Member'
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
