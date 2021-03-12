require 'rails_helper'

RSpec.describe 'Customers', type: :request do
  include_context 'リクエストスペース作成'

  # GET /customers/:customer_code（ベースドメイン） 顧客詳細
  # GET /customers/:customer_code.json（ベースドメイン） 顧客詳細API
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   権限: ある(Owner, Admin, Member), ない → データ作成
  #   顧客: 所属, 未所属, 存在しない, ない → 事前にデータ作成
  #   ベースドメイン, 存在するサブドメイン, 存在しないサブドメイン → 事前にデータ作成
  describe 'GET #show' do
    include_context '顧客作成（対象外）'

    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get customer_path(customer_code: customer_code), headers: headers
        expect(response).to be_successful
      end
      it '(json)成功ステータス' do
        get customer_path(customer_code: customer_code, format: :json), headers: headers
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToNot' do |error|
      it '存在しないステータス' do
        get customer_path(customer_code: customer_code), headers: headers
        expect(response).to be_not_found
      end
      it '(json)存在しないエラー' do
        get customer_path(customer_code: customer_code, format: :json), headers: headers
        expect(response).to be_not_found
        message = response.body.present? ? JSON.parse(response.body)['error'] : nil
        expect(message).to error.present? ? eq(I18n.t(error)) : be_nil
      end
    end
    shared_examples_for 'ToLogin' do |alert, notice, error|
      it 'ログインにリダイレクト' do
        get customer_path(customer_code: customer_code), headers: headers
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
      it '(json)認証エラー' do
        get customer_path(customer_code: customer_code, format: :json), headers: headers
        expect(response).to be_unauthorized
        message = response.body.present? ? JSON.parse(response.body)['error'] : nil
        expect(message).to error.present? ? eq(I18n.t(error)) : be_nil
      end
    end
    shared_examples_for 'ToBase' do |alert, notice, error|
      it 'ベースドメインにリダイレクト' do
        get customer_path(customer_code: customer_code), headers: headers
        expect(response).to redirect_to("//#{Settings['base_domain']}#{customer_path(customer_code: customer_code)}")
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
      it '(json)存在しないエラー' do
        get customer_path(customer_code: customer_code, format: :json), headers: headers
        expect(response).to be_not_found
        message = response.body.present? ? JSON.parse(response.body)['error'] : nil
        expect(message).to error.present? ? eq(I18n.t(error)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[ログイン中/削除予約済み][ある][所属]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[ログイン中/削除予約済み][ある][未所属/存在しない]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToNot', 'errors.messages.customer.code_error'
    end
    shared_examples_for '[未ログイン][ない][未所属/存在しない]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToLogin', 'devise.failure.unauthenticated', nil, 'devise.failure.unauthenticated'
    end
    shared_examples_for '[ログイン中/削除予約済み][ない][未所属/存在しない]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToNot', 'errors.messages.customer.code_error'
    end
    shared_examples_for '[*][*][*]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'ToBase', nil, nil, 'errors.messages.domain_error'
    end
    shared_examples_for '[*][*][*]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      it_behaves_like 'ToBase', nil, nil, 'errors.messages.domain_error'
    end

    shared_examples_for '[ログイン中/削除予約済み][ある]顧客に所属' do
      let!(:customer_code) { customer.code }
      it_behaves_like '[ログイン中/削除予約済み][ある][所属]ベースドメイン'
      it_behaves_like '[*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][ある]顧客に未所属' do
      let!(:customer_code) { outside_customer.code }
      it_behaves_like '[ログイン中/削除予約済み][ある][未所属/存在しない]ベースドメイン'
      it_behaves_like '[*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][ない]顧客に未所属' do
      let!(:customer_code) { outside_customer.code }
      it_behaves_like '[未ログイン][ない][未所属/存在しない]ベースドメイン'
      it_behaves_like '[*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][ない]顧客に未所属' do
      let!(:customer_code) { outside_customer.code }
      it_behaves_like '[ログイン中/削除予約済み][ない][未所属/存在しない]ベースドメイン'
      it_behaves_like '[*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][ある]顧客が存在しない' do
      let!(:customer_code) { NOT_CUSTOMER_CODE }
      it_behaves_like '[ログイン中/削除予約済み][ある][未所属/存在しない]ベースドメイン'
      it_behaves_like '[*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][ない]顧客が存在しない' do
      let!(:customer_code) { NOT_CUSTOMER_CODE }
      it_behaves_like '[未ログイン][ない][未所属/存在しない]ベースドメイン'
      it_behaves_like '[*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][ない]顧客が存在しない' do
      let!(:customer_code) { NOT_CUSTOMER_CODE }
      it_behaves_like '[ログイン中/削除予約済み][ない][未所属/存在しない]ベースドメイン'
      it_behaves_like '[*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*]存在しないサブドメイン'
    end

    shared_examples_for '[ログイン中/削除予約済み]権限がある' do |power|
      include_context '顧客・ユーザー紐付け', Time.current, power
      it_behaves_like '[ログイン中/削除予約済み][ある]顧客に所属'
      it_behaves_like '[ログイン中/削除予約済み][ある]顧客に未所属'
      it_behaves_like '[ログイン中/削除予約済み][ある]顧客が存在しない'
      # it_behaves_like '[ログイン中/削除予約済み][ある]顧客がない' # Tips: 先にRoutingErrorになる
    end
    shared_examples_for '[未ログイン]権限がない' do
      # it_behaves_like '[未ログイン][ない]顧客に所属' # Tips: 権限がないの為、顧客に所属がない
      it_behaves_like '[未ログイン][ない]顧客に未所属'
      it_behaves_like '[未ログイン][ない]顧客が存在しない'
      # it_behaves_like '[未ログイン][ない]顧客がない' # Tips: 先にRoutingErrorになる
    end
    shared_examples_for '[ログイン中/削除予約済み]権限がない' do
      # it_behaves_like '[ログイン中/削除予約済み][ない]顧客に所属' # Tips: 権限がないの為、顧客に所属がない
      it_behaves_like '[ログイン中/削除予約済み][ない]顧客に未所属'
      it_behaves_like '[ログイン中/削除予約済み][ない]顧客が存在しない'
      # it_behaves_like '[ログイン中/削除予約済み][ない]顧客がない' # Tips: 先にRoutingErrorになる
    end

    context '未ログイン' do
      # it_behaves_like '[未ログイン]権限がある', :Owner # Tips: 未ログインの為、権限がない
      # it_behaves_like '[未ログイン]権限がある', :Admin # Tips: 未ログインの為、権限がない
      # it_behaves_like '[未ログイン]権限がある', :Member # Tips: 未ログインの為、権限がない
      it_behaves_like '[未ログイン]権限がない'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中/削除予約済み]権限がある', :Owner
      it_behaves_like '[ログイン中/削除予約済み]権限がある', :Admin
      it_behaves_like '[ログイン中/削除予約済み]権限がある', :Member
      it_behaves_like '[ログイン中/削除予約済み]権限がない'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[ログイン中/削除予約済み]権限がある', :Owner
      it_behaves_like '[ログイン中/削除予約済み]権限がある', :Admin
      it_behaves_like '[ログイン中/削除予約済み]権限がある', :Member
      it_behaves_like '[ログイン中/削除予約済み]権限がない'
    end
  end

  # 顧客情報
  # 前提条件
  #   ベースドメイン, 顧客に所属, ログイン中/削除予約済み, Owner/Admin/Member
  # テストパターン
  #   ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   権限: ある(Owner, Admin, Member) → データ作成
  describe '@customer' do
    let!(:headers) { BASE_HEADER }
    let!(:customer_code) { customer.code }

    # テスト内容
    shared_examples_for '顧客情報表示' do
      it '顧客コードが含まれる' do
        get customer_path(customer_code: customer_code), headers: headers
        expect(response.body).to include(customer.code)
      end
      it '(json)顧客コードが一致する' do
        get customer_path(customer_code: customer_code, format: :json), headers: headers
        expect(JSON.parse(response.body)['customer']['code']).to eq(customer.code)
      end
      it '組織・団体名が含まれる' do
        get customer_path(customer_code: customer_code), headers: headers
        expect(response.body).to include(customer.name)
      end
      it '(json)組織・団体名が一致する' do
        get customer_path(customer_code: customer_code, format: :json), headers: headers
        expect(JSON.parse(response.body)['customer']['name']).to eq(customer.name)
      end
      it '作成日時が含まれる' do
        get customer_path(customer_code: customer_code), headers: headers
        expect(response.body).to include(I18n.l(customer.created_at))
      end
      it '(json)作成日時が一致する' do
        get customer_path(customer_code: customer_code, format: :json), headers: headers
        expect(JSON.parse(response.body)['customer']['created_at']).to eq(I18n.l(customer.created_at, format: :json))
      end
      it 'ユーザーの権限が含まれる' do
        get customer_path(customer_code: customer_code), headers: headers
        expect(response.body).to include(customer.member.first.power_i18n)
      end
      it '(json)ユーザーの権限が一致する' do
        get customer_path(customer_code: customer_code, format: :json), headers: headers
        expect(JSON.parse(response.body)['customer']['current_user']['power']).to eq(customer.member.first.power)
      end
      it 'メンバー数が含まれる' do
        get customer_path(customer_code: customer_code), headers: headers
        expect(response.body).to include("#{customer.member.count.to_s(:delimited)}名")
      end
      it '(json)メンバー数が一致する' do
        get customer_path(customer_code: customer_code, format: :json), headers: headers
        expect(JSON.parse(response.body)['customer']['member']['count']).to eq(customer.member.count)
      end
      it 'メンバー一覧のパスが含まれる' do
        get customer_path(customer_code: customer_code), headers: headers
        expect(response.body).to include("\"#{members_path(customer_code: customer.code)}\"")
      end
      it 'スペース数が含まれる' do
        get customer_path(customer_code: customer_code), headers: headers
        expect(response.body).to include("#{customer.space.count.to_s(:delimited)}名")
      end
      it '(json)スペース数が一致する' do
        get customer_path(customer_code: customer_code, format: :json), headers: headers
        expect(JSON.parse(response.body)['customer']['space']['count']).to eq(customer.space.count)
      end
      it '参加スペース一覧のパスが含まれる' do
        get customer_path(customer_code: customer_code), headers: headers
        expect(response.body).to include("\"#{spaces_path}\"")
      end
    end

    shared_examples_for '顧客情報変更表示' do
      it 'パスが含まれる' do
        get customer_path(customer_code: customer_code), headers: headers
        expect(response.body).to include("\"#{edit_customer_path(customer_code: customer.code)}\"")
      end
    end
    shared_examples_for '顧客情報変更非表示' do
      it 'パスが含まれない' do
        get customer_path(customer_code: customer_code), headers: headers
        expect(response.body).not_to include("\"#{edit_customer_path(customer_code: customer.code)}\"")
      end
    end

    shared_examples_for 'メンバー招待表示' do
      it 'パスが含まれる' do
        get customer_path(customer_code: customer_code), headers: headers
        expect(response.body).to include("\"#{new_member_path(customer_code: customer.code)}\"")
      end
    end
    shared_examples_for 'メンバー招待非表示' do
      it 'パスが含まれない' do
        get customer_path(customer_code: customer_code), headers: headers
        expect(response.body).not_to include("\"#{new_member_path(customer_code: customer.code)}\"")
      end
    end

    shared_examples_for 'スペース作成表示' do
      it 'パスが含まれる' do
        get customer_path(customer_code: customer_code), headers: headers
        expect(response.body).to include("\"#{new_space_path(customer_code: customer.code)}\"")
      end
    end
    shared_examples_for 'スペース作成非表示' do
      it 'パスが含まれない' do
        get customer_path(customer_code: customer_code), headers: headers
        expect(response.body).not_to include("\"#{new_space_path(customer_code: customer.code)}\"")
      end
    end

    # テストケース
    shared_examples_for '[*]権限がOwner' do
      include_context '顧客・ユーザー紐付け', Time.current, :Owner
      it_behaves_like '顧客情報表示'
      it_behaves_like '顧客情報変更表示'
      it_behaves_like 'メンバー招待表示'
      it_behaves_like 'スペース作成表示'
    end
    shared_examples_for '[*]権限がAdmin' do
      include_context '顧客・ユーザー紐付け', Time.current, :Admin
      it_behaves_like '顧客情報表示'
      it_behaves_like '顧客情報変更非表示'
      it_behaves_like 'メンバー招待表示'
      it_behaves_like 'スペース作成表示'
    end
    shared_examples_for '[*]権限がMember' do
      include_context '顧客・ユーザー紐付け', Time.current, :Member
      it_behaves_like '顧客情報表示'
      it_behaves_like '顧客情報変更非表示'
      it_behaves_like 'メンバー招待非表示'
      it_behaves_like 'スペース作成非表示'
    end

    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[*]権限がOwner'
      it_behaves_like '[*]権限がAdmin'
      it_behaves_like '[*]権限がMember'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[*]権限がOwner'
      it_behaves_like '[*]権限がAdmin'
      it_behaves_like '[*]権限がMember'
    end
  end
end
