require 'rails_helper'

RSpec.describe 'Members', type: :request do
  # GET /members/:customer_code/:user_code/edit（ベースドメイン） メンバー権限変更
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   権限: Owner, Admin, Member, ない → データ作成
  #   顧客: 所属, 未所属, 存在しない, ない → 事前にデータ作成
  #   対象: ない, 自分, Owner, Admin, Member → 事前にデータ作成
  #   ベースドメイン, 存在するサブドメイン, 存在しないサブドメイン → 事前にデータ作成
  describe 'GET #edit' do
    include_context 'リクエストスペース作成'
    include_context 'メンバー作成', 1, 1, 1, 0, 'ASC'
    include_context 'メンバー作成（対象外）', 'ASC'

    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get edit_member_path(customer_code: customer_code, user_code: user_code), headers: headers
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToNot' do
      it '存在しないステータス' do
        get edit_member_path(customer_code: customer_code, user_code: user_code), headers: headers
        expect(response).to be_not_found
      end
    end
    shared_examples_for 'ToIndex' do |alert, notice|
      it '一覧にリダイレクト' do
        get edit_member_path(customer_code: customer_code, user_code: user_code), headers: headers
        expect(response).to redirect_to(members_path(customer_code: customer_code))
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToLogin' do |alert, notice|
      it 'ログインにリダイレクト' do
        get edit_member_path(customer_code: customer_code, user_code: user_code), headers: headers
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToBase' do |alert, notice|
      it 'ベースドメインにリダイレクト' do
        get edit_member_path(customer_code: customer_code, user_code: user_code), headers: headers
        expect(response).to redirect_to("//#{Settings['base_domain']}#{edit_member_path(customer_code: customer_code, user_code: user_code)}")
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[ログイン中/削除予約済み][Owner][所属][自分]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToIndex', 'alert.member.own_update_power.owner', nil
    end
    shared_examples_for '[ログイン中/削除予約済み][Admin][所属][自分]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToIndex', 'alert.member.own_update_power.admin', nil
    end
    shared_examples_for '[ログイン中/削除予約済み][Member][所属][自分/Admin/Member]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToIndex', 'alert.member.not_update_power.admin', nil
    end
    shared_examples_for '[ログイン中][Owner][所属][Owner]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[削除予約済み][Owner][所属][Owner]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToIndex', 'alert.user.destroy_reserved', nil
    end
    shared_examples_for '[ログイン中/削除予約済み][Admin/Member][所属][Owner]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToIndex', 'alert.member.not_update_power.owner', nil
    end
    shared_examples_for '[ログイン中][Owner/Admin][所属][Admin/Member]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[削除予約済み][Owner/Admin][所属][Admin/Member]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToIndex', 'alert.user.destroy_reserved', nil
    end
    shared_examples_for '[未ログイン][*][未所属/存在しない][*]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToLogin', 'devise.failure.unauthenticated', nil
    end
    shared_examples_for '[ログイン中/削除予約済み][*][未所属/存在しない][*]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToNot'
    end
    shared_examples_for '[*][*][*][*]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'ToBase', nil, nil
    end
    shared_examples_for '[*][*][*][*]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      it_behaves_like 'ToBase', nil, nil
    end

    shared_examples_for '[ログイン中/削除予約済み][Owner][所属]対象が自分' do
      let!(:user_code) { user.code }
      it_behaves_like '[ログイン中/削除予約済み][Owner][所属][自分]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][Admin][所属]対象が自分' do
      let!(:user_code) { user.code }
      it_behaves_like '[ログイン中/削除予約済み][Admin][所属][自分]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][Member][所属]対象が自分' do
      let!(:user_code) { user.code }
      it_behaves_like '[ログイン中/削除予約済み][Member][所属][自分/Admin/Member]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][*][未所属]対象が自分' do
      let!(:user_code) { user.code }
      it_behaves_like '[ログイン中/削除予約済み][*][未所属/存在しない][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][*][存在しない]対象が自分' do
      let!(:user_code) { user.code }
      it_behaves_like '[ログイン中/削除予約済み][*][未所属/存在しない][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中][Owner][所属]対象がOwner' do
      let!(:user_code) { @create_users[0].code }
      it_behaves_like '[ログイン中][Owner][所属][Owner]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[削除予約済み][Owner][所属]対象がOwner' do
      let!(:user_code) { @create_users[0].code }
      it_behaves_like '[削除予約済み][Owner][所属][Owner]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][Admin/Member][所属]対象がOwner' do
      let!(:user_code) { @create_users[0].code }
      it_behaves_like '[ログイン中/削除予約済み][Admin/Member][所属][Owner]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中][Owner/Admin][所属]対象がAdmin' do
      let!(:user_code) { @create_users[1].code }
      it_behaves_like '[ログイン中][Owner/Admin][所属][Admin/Member]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[削除予約済み][Owner/Admin][所属]対象がAdmin' do
      let!(:user_code) { @create_users[1].code }
      it_behaves_like '[削除予約済み][Owner/Admin][所属][Admin/Member]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][Member][所属]対象がAdmin' do
      let!(:user_code) { @create_users[1].code }
      it_behaves_like '[ログイン中/削除予約済み][Member][所属][自分/Admin/Member]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中][Owner/Admin][所属]対象がMember' do
      let!(:user_code) { @create_users[2].code }
      it_behaves_like '[ログイン中][Owner/Admin][所属][Admin/Member]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[削除予約済み][Owner/Admin][所属]対象がMember' do
      let!(:user_code) { @create_users[2].code }
      it_behaves_like '[削除予約済み][Owner/Admin][所属][Admin/Member]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][Member][所属]対象がMember' do
      let!(:user_code) { @create_users[2].code }
      it_behaves_like '[ログイン中/削除予約済み][Member][所属][自分/Admin/Member]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][*][未所属]対象がOwner' do
      let!(:user_code) { @create_outside_users[0].code }
      it_behaves_like '[未ログイン][*][未所属/存在しない][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][*][存在しない]対象がOwner' do
      let!(:user_code) { @create_outside_users[0].code }
      it_behaves_like '[未ログイン][*][未所属/存在しない][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][*][未所属]対象がOwner' do
      let!(:user_code) { @create_outside_users[0].code }
      it_behaves_like '[ログイン中/削除予約済み][*][未所属/存在しない][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][*][存在しない]対象がOwner' do
      let!(:user_code) { @create_outside_users[0].code }
      it_behaves_like '[ログイン中/削除予約済み][*][未所属/存在しない][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][*][未所属]対象がAdmin' do
      let!(:user_code) { @create_outside_users[1].code }
      it_behaves_like '[未ログイン][*][未所属/存在しない][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][*][存在しない]対象がAdmin' do
      let!(:user_code) { @create_outside_users[1].code }
      it_behaves_like '[未ログイン][*][未所属/存在しない][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][*][未所属]対象がAdmin' do
      let!(:user_code) { @create_outside_users[1].code }
      it_behaves_like '[ログイン中/削除予約済み][*][未所属/存在しない][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][*][存在しない]対象がAdmin' do
      let!(:user_code) { @create_outside_users[1].code }
      it_behaves_like '[ログイン中/削除予約済み][*][未所属/存在しない][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][*][未所属]対象がMember' do
      let!(:user_code) { @create_outside_users[2].code }
      it_behaves_like '[未ログイン][*][未所属/存在しない][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][*][存在しない]対象がMember' do
      let!(:user_code) { @create_outside_users[2].code }
      it_behaves_like '[未ログイン][*][未所属/存在しない][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][*][未所属]対象がMember' do
      let!(:user_code) { @create_outside_users[2].code }
      it_behaves_like '[ログイン中/削除予約済み][*][未所属/存在しない][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][*][存在しない]対象がMember' do
      let!(:user_code) { @create_outside_users[2].code }
      it_behaves_like '[ログイン中/削除予約済み][*][未所属/存在しない][*]ベースドメイン'
      it_behaves_like '[*][*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*][*]存在しないサブドメイン'
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
      it_behaves_like '[未ログイン][*][未所属]対象がOwner'
      it_behaves_like '[未ログイン][*][未所属]対象がAdmin'
      it_behaves_like '[未ログイン][*][未所属]対象がMember'
    end
    shared_examples_for '[ログイン中/削除予約済み][*]顧客に未所属' do
      let!(:customer_code) { outside_customer.code }
      # it_behaves_like '[ログイン中/削除予約済み][*][未所属]対象がない' # Tips: 先にRoutingErrorになる
      it_behaves_like '[ログイン中/削除予約済み][*][未所属]対象が自分'
      it_behaves_like '[ログイン中/削除予約済み][*][未所属]対象がOwner'
      it_behaves_like '[ログイン中/削除予約済み][*][未所属]対象がAdmin'
      it_behaves_like '[ログイン中/削除予約済み][*][未所属]対象がMember'
    end
    shared_examples_for '[未ログイン][*]顧客が存在しない' do
      let!(:customer_code) { NOT_CUSTOMER_CODE }
      # it_behaves_like '[未ログイン][*][存在しない]対象がない' # Tips: 先にRoutingErrorになる
      # it_behaves_like '[未ログイン][*][存在しない]対象が自分' # Tips: 未ログインの為、対象がない
      it_behaves_like '[未ログイン][*][存在しない]対象がOwner'
      it_behaves_like '[未ログイン][*][存在しない]対象がAdmin'
      it_behaves_like '[未ログイン][*][存在しない]対象がMember'
    end
    shared_examples_for '[ログイン中/削除予約済み][*]顧客が存在しない' do
      let!(:customer_code) { NOT_CUSTOMER_CODE }
      # it_behaves_like '[ログイン中/削除予約済み][*][存在しない]対象がない' # Tips: 先にRoutingErrorになる
      it_behaves_like '[ログイン中/削除予約済み][*][存在しない]対象が自分'
      it_behaves_like '[ログイン中/削除予約済み][*][存在しない]対象がOwner'
      it_behaves_like '[ログイン中/削除予約済み][*][存在しない]対象がAdmin'
      it_behaves_like '[ログイン中/削除予約済み][*][存在しない]対象がMember'
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
