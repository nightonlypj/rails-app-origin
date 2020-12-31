require 'rails_helper'

RSpec.describe 'Members', type: :request do
  include_context 'リクエストスペース作成'

  # GET /members/:customer_code（ベースドメイン） メンバー一覧
  # GET /members/:customer_code.json（ベースドメイン） メンバー一覧API
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   権限なし, Owner権限, Admin権限, Member権限 → データ作成
  #   所属顧客, 未所属顧客, 存在しない顧客, 顧客なし → 事前にデータ作成
  #   ベースドメイン, 存在するサブドメイン, 存在しないサブドメイン → 事前にデータ作成
  describe 'GET /index' do
    let!(:outside_customer) { FactoryBot.create(:customer) }

    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get members_path(customer_code: customer_code), headers: headers
        expect(response).to be_successful
      end
      it '(json)成功ステータス' do
        get members_path(customer_code: customer_code, format: :json), headers: headers
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToNG' do |error|
      it '存在しないステータス' do
        get members_path(customer_code: customer_code), headers: headers
        expect(response).to be_not_found
      end
      it '(json)存在しないエラー' do
        get members_path(customer_code: customer_code, format: :json), headers: headers
        expect(response).to be_not_found
        expect(JSON.parse(response.body)['error']).to error.present? ? eq(I18n.t(error)) : be_nil
      end
    end
    shared_examples_for 'ToLogin' do |alert, notice, error|
      it 'ログインにリダイレクト' do
        get members_path(customer_code: customer_code), headers: headers
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
      it '(json)認証エラー' do
        get members_path(customer_code: customer_code, format: :json), headers: headers
        expect(response).to be_unauthorized
        expect(JSON.parse(response.body)['error']).to error.present? ? eq(I18n.t(error)) : be_nil
      end
    end
    shared_examples_for 'ToBase' do |alert, notice, error|
      it 'ベースドメインにリダイレクト' do
        get members_path(customer_code: customer_code), headers: headers
        expect(response).to redirect_to("//#{Settings['base_domain']}#{members_path(customer_code: customer_code)}")
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
      it '(json)存在しないエラー' do
        get members_path(customer_code: customer_code, format: :json), headers: headers
        expect(response).to be_not_found
        expect(JSON.parse(response.body)['error']).to error.present? ? eq(I18n.t(error)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[ログイン中][権限あり][所属顧客]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[未ログイン][権限なし][未所属/存在しない顧客]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToLogin', 'devise.failure.unauthenticated', nil, 'devise.failure.unauthenticated'
    end
    shared_examples_for '[ログイン中][権限なし][未所属/存在しない顧客]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToNG', 'errors.messages.customer_code_error'
    end
    shared_examples_for '[ログイン中][権限あり][未所属/存在しない顧客]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToNG', 'errors.messages.customer_code_error'
    end
    shared_examples_for '存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'ToBase', nil, nil, 'errors.messages.domain_error'
    end
    shared_examples_for '存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      it_behaves_like 'ToBase', nil, nil, 'errors.messages.domain_error'
    end

    shared_examples_for '[ログイン中][権限あり]所属顧客' do
      let!(:customer_code) { customer.code }
      it_behaves_like '[ログイン中][権限あり][所属顧客]ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][権限なし]未所属顧客' do
      let!(:customer_code) { outside_customer.code }
      it_behaves_like '[未ログイン][権限なし][未所属/存在しない顧客]ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中][権限なし]未所属顧客' do
      let!(:customer_code) { outside_customer.code }
      it_behaves_like '[ログイン中][権限なし][未所属/存在しない顧客]ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中][権限あり]未所属顧客' do
      let!(:customer_code) { outside_customer.code }
      it_behaves_like '[ログイン中][権限あり][未所属/存在しない顧客]ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][権限なし]存在しない顧客' do
      let!(:customer_code) { NOT_CUSTOMER_CODE }
      it_behaves_like '[未ログイン][権限なし][未所属/存在しない顧客]ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中][権限なし]存在しない顧客' do
      let!(:customer_code) { NOT_CUSTOMER_CODE }
      it_behaves_like '[ログイン中][権限なし][未所属/存在しない顧客]ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中][権限あり]存在しない顧客' do
      let!(:customer_code) { NOT_CUSTOMER_CODE }
      it_behaves_like '[ログイン中][権限あり][未所属/存在しない顧客]ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end

    shared_examples_for '[未ログイン]権限なし' do
      # it_behaves_like '[未ログイン][権限なし]所属顧客' # Tips: 権限なしの為、所属顧客なし
      it_behaves_like '[未ログイン][権限なし]未所属顧客'
      it_behaves_like '[未ログイン][権限なし]存在しない顧客'
      # it_behaves_like '[未ログイン][権限なし]顧客なし' # Tips: 先にRoutingErrorになる
    end
    shared_examples_for '[ログイン中]権限なし' do
      # it_behaves_like '[ログイン中][権限なし]所属顧客' # Tips: 権限なしの為、所属顧客なし
      it_behaves_like '[ログイン中][権限なし]未所属顧客'
      it_behaves_like '[ログイン中][権限なし]存在しない顧客'
      # it_behaves_like '[ログイン中][権限なし]顧客なし' # Tips: 先にRoutingErrorになる
    end
    shared_examples_for '[ログイン中]権限あり' do |power|
      include_context '顧客・ユーザー紐付け', Time.current, power
      it_behaves_like '[ログイン中][権限あり]所属顧客'
      it_behaves_like '[ログイン中][権限あり]未所属顧客'
      it_behaves_like '[ログイン中][権限あり]存在しない顧客'
      # it_behaves_like '[ログイン中][権限あり]顧客なし' # Tips: 先にRoutingErrorになる
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]権限なし'
      # it_behaves_like '[未ログイン]権限あり', :Owner # Tips: 未ログインの為、権限なし
      # it_behaves_like '[未ログイン]権限あり', :Admin # Tips: 未ログインの為、権限なし
      # it_behaves_like '[未ログイン]権限あり', :Member # Tips: 未ログインの為、権限なし
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中]権限なし'
      it_behaves_like '[ログイン中]権限あり', :Owner
      it_behaves_like '[ログイン中]権限あり', :Admin
      it_behaves_like '[ログイン中]権限あり', :Member
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[ログイン中]権限なし'
      it_behaves_like '[ログイン中]権限あり', :Owner
      it_behaves_like '[ログイン中]権限あり', :Admin
      it_behaves_like '[ログイン中]権限あり', :Member
    end
  end

  # GET /members/:customer_code（ベースドメイン） メンバー一覧：メンバー情報
  # GET /members/:customer_code.json（ベースドメイン） メンバー一覧API：メンバー情報
  # 前提条件
  #   ベースドメイン, 所属顧客, ログイン中, 権限あり
  # テストパターン
  #   ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   Owner権限, Admin権限, Member権限 → データ作成
  #   所属メンバーが最大表示数と同じ, 最大表示数より多い → データ作成
  describe 'GET /index @customer @members' do
    let!(:headers) { BASE_HEADER }
    let!(:customer_code) { customer.code }

    # テスト内容
    shared_examples_for 'ページ情報' do |page|
      it '顧客名が含まれる' do
        get members_path(customer_code: customer_code, page: page), headers: headers
        expect(response.body).to include(customer.name)
      end
      it '(json)顧客名が一致する' do
        get members_path(customer_code: customer_code, page: page, format: :json), headers: headers
        expect(JSON.parse(response.body)['customer']['name']).to eq(customer.name)
      end
      it '(json)全件数が一致する' do
        get members_path(customer_code: customer_code, page: page, format: :json), headers: headers
        expect(JSON.parse(response.body)['member']['total_count']).to eq(@create_members.count)
      end
      it '(json)現在ページが一致する' do
        get members_path(customer_code: customer_code, page: page, format: :json), headers: headers
        expect(JSON.parse(response.body)['member']['current_page']).to eq(page)
      end
      it '(json)全ページ数が一致する' do
        get members_path(customer_code: customer_code, page: page, format: :json), headers: headers
        total_pages = (@create_members.count - 1).div(Settings['default_members_limit']) + 1
        expect(JSON.parse(response.body)['member']['total_pages']).to eq(total_pages)
      end
      it '(json)最大表示件数が一致する' do
        get members_path(customer_code: customer_code, page: page, format: :json), headers: headers
        expect(JSON.parse(response.body)['member']['limit_value']).to eq(Settings['default_members_limit'])
      end
      it '招待のパスが含まれる' do
        get members_path(customer_code: customer_code, page: page), headers: headers
        expect(response.body).to include("\"#{new_member_path(customer_code: customer_code)}\"")
      end
    end

    shared_examples_for 'ページネーション表示' do |page, link_page|
      it 'パスが含まれる' do
        get members_path(customer_code: customer_code, page: page), headers: headers
        if link_page == 1
          expect(response.body).to include("\"#{members_path(customer_code: customer_code)}\"")
        else
          expect(response.body).to include("\"#{members_path(customer_code: customer_code, page: link_page)}\"")
        end
      end
    end
    shared_examples_for 'ページネーション非表示' do |page, link_page|
      it 'パスが含まれない' do
        get members_path(customer_code: customer_code, page: page), headers: headers
        if link_page == 1
          expect(response.body).not_to include("\"#{members_path(customer_code: customer_code)}\"")
        else
          expect(response.body).not_to include("\"#{members_path(customer_code: customer_code, page: link_page)}\"")
        end
      end
    end

    shared_examples_for 'リスト表示' do |page|
      let!(:start_no) { Settings['default_members_limit'] * (page - 1) + 1 }
      let!(:end_no) { [@create_members.count, Settings['default_members_limit'] * page].min }
      it '(json)配列の件数が一致する' do
        get members_path(customer_code: customer_code, page: page, format: :json), headers: headers
        expect(JSON.parse(response.body)['members'].count).to eq(end_no - start_no + 1)
      end
      it '(json)ユーザーコードが一致する' do
        get members_path(customer_code: customer_code, page: page, format: :json), headers: headers
        parse_response = JSON.parse(response.body)['members']
        (start_no..end_no).each do |no|
          expect(parse_response[no - start_no]['code']).to eq(@create_members[no - 1].user.code)
        end
      end
      it '画像URLが含まれる' do # Tips: ユニークではない為、正確ではない
        get members_path(customer_code: customer_code, page: page), headers: headers
        (start_no..end_no).each do |no|
          expect(response.body).to include("\"#{@create_members[no - 1].user.image_url(:small)}\"")
        end
      end
      it '(json)画像URLが一致する' do
        get members_path(customer_code: customer_code, page: page, format: :json), headers: headers
        parse_response = JSON.parse(response.body)['members']
        (start_no..end_no).each do |no|
          expect(parse_response[no - start_no]['image_url']).to eq("https://#{Settings['base_domain']}#{@create_members[no - 1].user.image_url(:small)}")
        end
      end
      it '表示名が含まれる' do
        get members_path(customer_code: customer_code, page: page), headers: headers
        (start_no..end_no).each do |no|
          expect(response.body).to include(@create_members[no - 1].user.name)
        end
      end
      it '(json)表示名が一致する' do
        get members_path(customer_code: customer_code, page: page, format: :json), headers: headers
        parse_response = JSON.parse(response.body)['members']
        (start_no..end_no).each do |no|
          expect(parse_response[no - start_no]['name']).to eq(@create_members[no - 1].user.name)
        end
      end
      it 'メールアドレスが含まれる' do
        get members_path(customer_code: customer_code, page: page), headers: headers
        (start_no..end_no).each do |no|
          expect(response.body).to include(@create_members[no - 1].user.email)
        end
      end
      it '(json)メールアドレスが一致する' do
        get members_path(customer_code: customer_code, page: page, format: :json), headers: headers
        parse_response = JSON.parse(response.body)['members']
        (start_no..end_no).each do |no|
          expect(parse_response[no - start_no]['email']).to eq(@create_members[no - 1].user.email)
        end
      end
      it '権限が含まれる' do # Tips: ユニークではない為、正確ではない
        get members_path(customer_code: customer_code, page: page), headers: headers
        (start_no..end_no).each do |no|
          expect(response.body).to include(@create_members[no - 1].power_i18n)
        end
      end
      it '(json)権限が一致する' do
        get members_path(customer_code: customer_code, page: page, format: :json), headers: headers
        parse_response = JSON.parse(response.body)['members']
        (start_no..end_no).each do |no|
          expect(parse_response[no - start_no]['power']).to eq(@create_members[no - 1].power)
        end
      end
      it '招待日が含まれる' do # Tips: ユニークではない為、正確ではない
        get members_path(customer_code: customer_code, page: page), headers: headers
        (start_no..end_no).each do |no|
          if @create_members[no - 1].invitationed_at.present?
            expect(response.body).to include(I18n.l(@create_members[no - 1].invitationed_at.to_date))
          else
            expect(response.body).to include(I18n.t('blank_word.member.invitationed_at'))
          end
        end
      end
      it '(json)招待日が一致する' do
        get members_path(customer_code: customer_code, page: page, format: :json), headers: headers
        parse_response = JSON.parse(response.body)['members']
        (start_no..end_no).each do |no|
          if @create_members[no - 1].invitationed_at.present?
            expect(parse_response[no - start_no]['invitationed_at']).to eq(@create_members[no - 1].invitationed_at.strftime(JSON_TIME_FORMAT))
          else
            expect(parse_response[no - start_no]['invitationed_at']).to be_nil
          end
        end
      end
      it '登録日が含まれる' do # Tips: ユニークではない為、正確ではない
        get members_path(customer_code: customer_code, page: page), headers: headers
        (start_no..end_no).each do |no|
          if @create_members[no - 1].registrationed_at.present?
            expect(response.body).to include(I18n.l(@create_members[no - 1].registrationed_at.to_date))
          else
            expect(response.body).to include(I18n.t('blank_word.member.registrationed_at'))
          end
        end
      end
      it '(json)登録日が一致する' do
        get members_path(customer_code: customer_code, page: page, format: :json), headers: headers
        parse_response = JSON.parse(response.body)['members']
        (start_no..end_no).each do |no|
          if @create_members[no - 1].registrationed_at.present?
            expect(parse_response[no - start_no]['registrationed_at']).to eq(@create_members[no - 1].registrationed_at.strftime(JSON_TIME_FORMAT))
          else
            expect(parse_response[no - start_no]['registrationed_at']).to be_nil
          end
        end
      end
    end

    shared_examples_for 'リストリンク表示' do |page, power|
      let!(:start_no) { Settings['default_members_limit'] * (page - 1) + 1 }
      let!(:end_no) { [@create_members.count, Settings['default_members_limit'] * page].min }
      it '変更のパスが含まれる' do
        get members_path(customer_code: customer_code, page: page), headers: headers
        (start_no..end_no).each do |no|
          if (power == :Owner) || (power == :Admin && @create_members[no - 1].power != :Owner)
            edit_path = edit_member_path(customer_code: customer_code, user_code: @create_members[no - 1].user.code)
            expect(response.body).to include("\"#{edit_path}\"")
          end
        end
      end
      it '解除のパスが含まれる' do
        get members_path(customer_code: customer_code, page: page), headers: headers
        (start_no..end_no).each do |no|
          if (power == :Owner) || (power == :Admin && @create_members[no - 1].power != :Owner)
            delete_path = delete_member_path(customer_code: customer_code, user_code: @create_members[no - 1].user.code)
            expect(response.body).to include("\"#{delete_path}\"")
          end
        end
      end
    end
    shared_examples_for 'リストリンク非表示' do |page, power|
      let!(:start_no) { Settings['default_members_limit'] * (page - 1) + 1 }
      let!(:end_no) { [@create_members.count, Settings['default_members_limit'] * page].min }
      it '変更のパスが含まれない' do
        get members_path(customer_code: customer_code, page: page), headers: headers
        (start_no..end_no).each do |no|
          unless (power == :Owner) || (power == :Admin && @create_members[no - 1].power != :Owner)
            edit_path = edit_member_path(customer_code: customer_code, user_code: @create_members[no - 1].user.code)
            expect(response.body).not_to include("\"#{edit_path}\"")
          end
        end
      end
      it '解除のパスが含まれない' do
        get members_path(customer_code: customer_code, page: page), headers: headers
        (start_no..end_no).each do |no|
          unless (power == :Owner) || (power == :Admin && @create_members[no - 1].power != :Owner)
            delete_path = delete_member_path(customer_code: customer_code, user_code: @create_members[no - 1].user.code)
            expect(response.body).not_to include("\"#{delete_path}\"")
          end
        end
      end
    end

    # テストケース
    shared_examples_for '所属メンバーが最大表示数と同じ' do |power|
      include_context 'メンバー作成', Settings['test_customers_owner'], Settings['test_customers_admin'], Settings['test_customers_member'], 1
      it_behaves_like 'ページ情報', 1
      it_behaves_like 'ページネーション非表示', 1, 2
      it_behaves_like 'リスト表示', 1
      it_behaves_like 'リストリンク表示', 1, power
      it_behaves_like 'リストリンク非表示', 1, power
    end
    shared_examples_for '所属メンバーが最大表示数より多い' do |power|
      include_context 'メンバー作成', Settings['test_customers_owner'], Settings['test_customers_admin'], Settings['test_customers_member'] + 1, 1
      it_behaves_like 'ページ情報', 1
      it_behaves_like 'ページ情報', 2
      it_behaves_like 'ページネーション表示', 1, 2
      it_behaves_like 'ページネーション表示', 2, 1
      it_behaves_like 'リスト表示', 1
      it_behaves_like 'リスト表示', 2
      it_behaves_like 'リストリンク表示', 1, power
      it_behaves_like 'リストリンク表示', 2, power
      it_behaves_like 'リストリンク非表示', 1, power
      it_behaves_like 'リストリンク非表示', 2, power
    end

    shared_examples_for '権限あり' do |power|
      include_context '顧客・ユーザー紐付け', Time.current, power
      # it_behaves_like '所属メンバーが0件' # Tips: 自分が所属している為、1件以上
      it_behaves_like '所属メンバーが最大表示数と同じ', power
      it_behaves_like '所属メンバーが最大表示数より多い', power
    end

    context 'ログイン中' do
      include_context 'ログイン処理'
      include_context '画像登録処理'
      it_behaves_like '権限あり', :Owner
      it_behaves_like '権限あり', :Admin
      it_behaves_like '権限あり', :Member
      include_context '画像削除処理'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      include_context '画像登録処理'
      it_behaves_like '権限あり', :Owner
      it_behaves_like '権限あり', :Admin
      it_behaves_like '権限あり', :Member
      include_context '画像削除処理'
    end
  end
end
