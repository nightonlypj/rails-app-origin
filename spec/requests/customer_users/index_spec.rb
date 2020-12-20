require 'rails_helper'

RSpec.describe '/customer_users', type: :request do
  include_context '共通ヘッダー'
  include_context 'リクエストスペース作成'

  # GET /customer_users/:customer_code（ベースドメイン） メンバー一覧
  # GET /customer_users/:customer_code.json（ベースドメイン） メンバー一覧API
  describe 'GET /index' do
    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get customer_users_path(customer_code: customer.code), headers: headers
        expect(response).to be_successful
      end
      it '(json)成功ステータス' do
        get customer_users_path(customer_code: customer.code), headers: headers.merge(json_headers)
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToNG' do
      it '存在しないステータス' do
        get customer_users_path(customer_code: customer.code), headers: headers
        expect(response).to be_not_found
      end
      it '(json)存在しないステータス' do
        get customer_users_path(customer_code: customer.code), headers: headers.merge(json_headers)
        expect(response).to be_not_found
      end
    end
    shared_examples_for 'ToLogin' do
      it 'ログインにリダイレクト' do
        get customer_users_path(customer_code: customer.code), headers: headers
        expect(response).to redirect_to(new_user_session_path)
      end
      it '(json)認証エラーステータス' do
        get customer_users_path(customer_code: customer.code), headers: headers.merge(json_headers)
        expect(response).to be_unauthorized
      end
    end
    shared_examples_for 'ToBase' do
      it 'ベースドメインにリダイレクト' do
        get customer_users_path(customer_code: customer.code), headers: headers
        expect(response).to redirect_to("//#{Settings['base_domain']}#{customer_users_path(customer_code: customer.code)}")
      end
      it '(json)存在しないステータス' do
        get customer_users_path(customer_code: customer.code), headers: headers.merge(json_headers)
        expect(response).to be_not_found
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]ベースドメイン' do
      let!(:headers) { base_headers }
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '[ログイン中][権限あり]ベースドメイン' do
      let!(:headers) { base_headers }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[ログイン中][権限なし]ベースドメイン' do
      let!(:headers) { base_headers }
      it_behaves_like 'ToNG'
    end
    shared_examples_for '存在するサブドメイン' do
      let!(:headers) { @space_headers }
      it_behaves_like 'ToBase'
    end
    shared_examples_for '存在しないサブドメイン' do
      let!(:headers) { not_space_headers }
      it_behaves_like 'ToBase'
    end

    shared_examples_for '権限あり' do |power|
      include_context '顧客・ログインユーザー紐付け', Time.current, power
      it_behaves_like '[ログイン中][権限あり]ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
    shared_examples_for '権限なし' do
      it_behaves_like '[ログイン中][権限なし]ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '権限あり', :Owner
      it_behaves_like '権限あり', :Admin
      it_behaves_like '権限あり', :Member
      it_behaves_like '権限なし'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '権限あり', :Owner
      it_behaves_like '権限あり', :Admin
      it_behaves_like '権限あり', :Member
      it_behaves_like '権限なし'
    end
  end

  # GET /customer_users/:customer_code（ベースドメイン） メンバー一覧：メンバー情報
  # GET /customer_users/:customer_code.json（ベースドメイン） メンバー一覧API：メンバー情報
  describe 'GET /index @customer @customer_users' do
    let!(:headers) { base_headers }
    include_context '対象外のメンバー作成', 1, 1, 1

    # テスト内容
    shared_examples_for '対象の顧客' do
      it '顧客名が含まれる' do
        get customer_users_path(customer_code: customer.code), headers: headers
        expect(response.body).to include(customer.name)
      end
      it '(json)顧客名が一致する' do
        get customer_users_path(customer_code: customer.code), headers: headers.merge(json_headers)
        expect(JSON.parse(response.body)['customer']['name']).to eq(customer.name)
      end
    end
    shared_examples_for '対象外の顧客' do
      it '顧客名が含まれない' do
        get customer_users_path(customer_code: customer.code), headers: headers
        expect(response.body).not_to include(other_customer.name)
      end
      it '(json)顧客名が一致しない' do
        get customer_users_path(customer_code: customer.code), headers: headers.merge(json_headers)
        expect(JSON.parse(response.body)['customer']['name']).not_to eq(other_customer.name)
      end
    end

    shared_examples_for '招待表示' do
      it 'パスが含まれる' do
        get customer_users_path(customer_code: customer.code), headers: headers
        expect(response.body).to include("\"#{new_customer_user_path(customer_code: customer.code)}\"")
      end
    end

    shared_examples_for 'ヘッダ情報' do
      it '(json)全件数が一致する' do
        get customer_users_path(customer_code: customer.code), headers: headers.merge(json_headers)
        expect(JSON.parse(response.body)['customer_user']['total_count']).to eq(@inside_customer_users.count)
      end
      it '(json)1ページ、現在ページが一致する' do
        get customer_users_path(customer_code: customer.code), headers: headers.merge(json_headers)
        expect(JSON.parse(response.body)['customer_user']['current_page']).to eq(1)
      end
      it '(json)2ページ、現在ページが一致する' do
        get customer_users_path(customer_code: customer.code, page: 2), headers: headers.merge(json_headers)
        expect(JSON.parse(response.body)['customer_user']['current_page']).to eq(2)
      end
      it '(json)全ページ数が一致する' do
        get customer_users_path(customer_code: customer.code), headers: headers.merge(json_headers)
        total_pages = (@inside_customer_users.count - 1).div(Settings['default_customer_users_limit']) + 1
        expect(JSON.parse(response.body)['customer_user']['total_pages']).to eq(total_pages)
      end
      it '(json)最大表示件数が一致する' do
        get customer_users_path(customer_code: customer.code), headers: headers.merge(json_headers)
        expect(JSON.parse(response.body)['customer_user']['limit_value']).to eq(Settings['default_customer_users_limit'])
      end
    end

    shared_examples_for '2ページ目リンク表示' do
      it 'パスが含まれる' do
        get customer_users_path(customer_code: customer.code), headers: headers
        expect(response.body).to include("\"#{customer_users_path(customer_code: customer.code, page: 2)}\"")
      end
    end
    shared_examples_for '2ページ目リンク非表示' do
      it 'パスが含まれない' do
        get customer_users_path(customer_code: customer.code), headers: headers
        expect(response.body).not_to include("\"#{customer_users_path(customer_code: customer.code, page: 2)}\"")
      end
    end

    shared_examples_for '対象のリスト表示' do |page|
      let!(:start_no) { Settings['default_customer_users_limit'] * (page - 1) + 1 }
      let!(:end_no) { [@inside_customer_users.count, Settings['default_customer_users_limit'] * page].min }
      it '表示名が含まれる' do
        get customer_users_path(customer_code: customer.code, page: page), headers: headers
        (start_no..end_no).each do |no|
          expect(response.body).to include(@inside_customer_users[no - 1].user.name)
        end
      end
      it 'メールアドレスが含まれる' do
        get customer_users_path(customer_code: customer.code, page: page), headers: headers
        (start_no..end_no).each do |no|
          expect(response.body).to include(@inside_customer_users[no - 1].user.email)
        end
      end
      it '権限が含まれる' do
        get customer_users_path(customer_code: customer.code, page: page), headers: headers
        (start_no..end_no).each do |no|
          expect(response.body).to include(@inside_customer_users[no - 1].power_i18n)
        end
      end
      it '変更のパスが含まれる' do
        get customer_users_path(customer_code: customer.code, page: page), headers: headers
        (start_no..end_no).each do |no|
          expect(response.body).to include("\"#{edit_customer_user_path(customer_code: customer.code, id: @inside_customer_users[no - 1].id)}\"")
        end
      end
      it '解除のパスが含まれる' do
        get customer_users_path(customer_code: customer.code, page: page), headers: headers
        (start_no..end_no).each do |no|
          expect(response.body).to include("\"#{delete_customer_user_path(customer_code: customer.code, id: @inside_customer_users[no - 1].id)}\"")
        end
      end
      it '(json)画像URLが一致する' do
        get customer_users_path(customer_code: customer.code, page: page), headers: headers.merge(json_headers)
        parse_response = JSON.parse(response.body)['customer_users']
        (start_no..end_no).each do |no|
          expect(parse_response[no - start_no]['image_url']).to eq("https://#{Settings['base_domain']}#{@inside_customer_users[no - 1].user.image_url(:small)}")
        end
      end
      it '(json)表示名が一致する' do
        get customer_users_path(customer_code: customer.code, page: page), headers: headers.merge(json_headers)
        parse_response = JSON.parse(response.body)['customer_users']
        (start_no..end_no).each do |no|
          expect(parse_response[no - start_no]['name']).to eq(@inside_customer_users[no - 1].user.name)
        end
      end
      it '(json)メールアドレスが一致する' do
        get customer_users_path(customer_code: customer.code, page: page), headers: headers.merge(json_headers)
        parse_response = JSON.parse(response.body)['customer_users']
        (start_no..end_no).each do |no|
          expect(parse_response[no - start_no]['email']).to eq(@inside_customer_users[no - 1].user.email)
        end
      end
      it '(json)権限が一致する' do
        get customer_users_path(customer_code: customer.code, page: page), headers: headers.merge(json_headers)
        parse_response = JSON.parse(response.body)['customer_users']
        (start_no..end_no).each do |no|
          expect(parse_response[no - start_no]['power']).to eq(@inside_customer_users[no - 1].power)
        end
      end
      it '(json)招待日が一致する' do
        get customer_users_path(customer_code: customer.code, page: page), headers: headers.merge(json_headers)
        parse_response = JSON.parse(response.body)['customer_users']
        (start_no..end_no).each do |no|
          if @inside_customer_users[no - 1].invitationed_at.present?
            expect(parse_response[no - start_no]['invitationed_at']).to eq(@inside_customer_users[no - 1].invitationed_at.strftime(TEST_JSON_TIME_FORMAT))
          else
            expect(parse_response[no - start_no]['invitationed_at']).to be_nil
          end
        end
      end
      it '(json)登録日が一致する' do
        get customer_users_path(customer_code: customer.code, page: page), headers: headers.merge(json_headers)
        parse_response = JSON.parse(response.body)['customer_users']
        (start_no..end_no).each do |no|
          if @inside_customer_users[no - 1].registrationed_at.present?
            expect(parse_response[no - start_no]['registrationed_at']).to eq(@inside_customer_users[no - 1].registrationed_at.strftime(TEST_JSON_TIME_FORMAT))
          else
            expect(parse_response[no - start_no]['registrationed_at']).to be_nil
          end
        end
      end
    end
    shared_examples_for 'ページ外のリスト非表示' do |page, outside_page|
      let!(:start_no) { Settings['default_customer_users_limit'] * (outside_page - 1) + 1 }
      let!(:end_no) { [@inside_customer_users.count, Settings['default_customer_users_limit'] * outside_page].min }
      it '表示名が含まれない' do
        get customer_users_path(customer_code: customer.code, page: page), headers: headers
        (start_no..end_no).each do |no|
          expect(response.body).not_to include(@inside_customer_users[no - 1].user.name) if @inside_customer_users[no - 1].user != user
        end
      end
      it 'メールアドレスが含まれない' do
        get customer_users_path(customer_code: customer.code, page: page), headers: headers
        (start_no..end_no).each do |no|
          expect(response.body).not_to include(@inside_customer_users[no - 1].user.email) if @inside_customer_users[no - 1].user != user
        end
      end
      it '変更のパスが含まれない' do
        get customer_users_path(customer_code: customer.code, page: page), headers: headers
        (start_no..end_no).each do |no|
          expect(response.body).not_to include("\"#{edit_customer_user_path(customer_code: customer.code, id: @inside_customer_users[no - 1].id)}\"")
        end
      end
      it '解除のパスが含まれない' do
        get customer_users_path(customer_code: customer.code, page: page), headers: headers
        (start_no..end_no).each do |no|
          expect(response.body).not_to include("\"#{delete_customer_user_path(customer_code: customer.code, id: @inside_customer_users[no - 1].id)}\"")
        end
      end
      it '(json)表示名が含まれない' do
        get customer_users_path(customer_code: customer.code, page: page), headers: headers.merge(json_headers)
        hash_responses = JSON.parse(response.body)['customer_users'].map { |response| [response['name'], response] }.to_h
        (start_no..end_no).each do |no|
          expect(hash_responses[@inside_customer_users[no - 1].user.name]).to be_nil
        end
      end
      it '(json)メールアドレスが含まれない' do
        get customer_users_path(customer_code: customer.code, page: page), headers: headers.merge(json_headers)
        hash_responses = JSON.parse(response.body)['customer_users'].map { |response| [response['email'], response] }.to_h
        (start_no..end_no).each do |no|
          expect(hash_responses[@inside_customer_users[no - 1].user.email]).to be_nil
        end
      end
    end
    shared_examples_for '対象外のリスト非表示' do |page|
      it '表示名が含まれない' do
        get customer_users_path(customer_code: customer.code, page: page), headers: headers
        (1..@outside_customer_users.count).each do |no|
          expect(response.body).not_to include(@outside_customer_users[no - 1].user.name)
        end
      end
      it 'メールアドレスが含まれない' do
        get customer_users_path(customer_code: customer.code, page: page), headers: headers
        (1..@outside_customer_users.count).each do |no|
          expect(response.body).not_to include(@outside_customer_users[no - 1].user.email)
        end
      end
      it '変更のパスが含まれない' do
        get customer_users_path(customer_code: customer.code, page: page), headers: headers
        (1..@outside_customer_users.count).each do |no|
          expect(response.body).not_to include("\"#{edit_customer_user_path(customer_code: customer.code, id: @outside_customer_users[no - 1].id)}\"")
        end
      end
      it '解除のパスが含まれない' do
        get customer_users_path(customer_code: customer.code, page: page), headers: headers
        (1..@outside_customer_users.count).each do |no|
          expect(response.body).not_to include("\"#{delete_customer_user_path(customer_code: customer.code, id: @outside_customer_users[no - 1].id)}\"")
        end
      end
      it '(json)表示名が含まれない' do
        get customer_users_path(customer_code: customer.code, page: page), headers: headers.merge(json_headers)
        hash_responses = JSON.parse(response.body)['customer_users'].map { |response| [response['name'], response] }.to_h
        (1..@outside_customer_users.count).each do |no|
          expect(hash_responses[@outside_customer_users[no - 1].user.name]).to be_nil
        end
      end
      it '(json)メールアドレスが含まれない' do
        get customer_users_path(customer_code: customer.code, page: page), headers: headers.merge(json_headers)
        hash_responses = JSON.parse(response.body)['customer_users'].map { |response| [response['email'], response] }.to_h
        (1..@outside_customer_users.count).each do |no|
          expect(hash_responses[@outside_customer_users[no - 1].user.email]).to be_nil
        end
      end
    end

    # テストケース
    shared_examples_for '所属メンバーが最大表示数と同じ' do
      include_context '対象のメンバー作成', Settings['test_customers_owner'], Settings['test_customers_admin'], Settings['test_customers_member'], 1
      it_behaves_like 'ヘッダ情報'
      it_behaves_like '2ページ目リンク非表示'
      it_behaves_like '対象のリスト表示', 1
      it_behaves_like '対象外のリスト非表示', 1
    end
    shared_examples_for '所属メンバーが最大表示数より多い' do
      include_context '対象のメンバー作成', Settings['test_customers_owner'], Settings['test_customers_admin'], Settings['test_customers_member'] + 1, 1
      it_behaves_like 'ヘッダ情報'
      it_behaves_like '2ページ目リンク表示'
      it_behaves_like '対象のリスト表示', 1
      it_behaves_like '対象のリスト表示', 2
      it_behaves_like 'ページ外のリスト非表示', 1, 2
      it_behaves_like 'ページ外のリスト非表示', 2, 1
      it_behaves_like '対象外のリスト非表示', 1
      it_behaves_like '対象外のリスト非表示', 2
    end

    shared_examples_for '権限あり' do |power|
      include_context '顧客・ログインユーザー紐付け', Time.current, power
      it_behaves_like '対象の顧客'
      it_behaves_like '対象外の顧客'
      it_behaves_like '招待表示'
      it_behaves_like '所属メンバーが最大表示数と同じ'
      it_behaves_like '所属メンバーが最大表示数より多い'
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
