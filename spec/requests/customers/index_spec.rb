require 'rails_helper'

RSpec.describe '/customers', type: :request do
  include_context '共通ヘッダー'

  # GET /customers（ベースドメイン） 所属一覧
  # GET /customers.json（ベースドメイン） 所属一覧API
  describe 'GET /index' do
    include_context 'リクエストスペース作成'

    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get customers_path, headers: headers
        expect(response).to be_successful
      end
      it '(json)成功ステータス' do
        get customers_path, headers: headers.merge(json_headers)
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToLogin' do
      it 'ログインにリダイレクト' do
        get customers_path, headers: headers
        expect(response).to redirect_to(new_user_session_path)
      end
      it '(json)認証エラーステータス' do
        get customers_path, headers: headers.merge(json_headers)
        expect(response).to be_unauthorized
      end
    end
    shared_examples_for 'ToBase' do
      it 'ベースドメインにリダイレクト' do
        get customers_path, headers: headers
        expect(response).to redirect_to("//#{Settings['base_domain']}#{customers_path}")
      end
      it '(json)存在しないステータス' do
        get customers_path, headers: headers.merge(json_headers)
        expect(response).to be_not_found
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]ベースドメイン' do
      let!(:headers) { base_headers }
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '[ログイン中]ベースドメイン' do
      let!(:headers) { base_headers }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[未ログイン]存在するサブドメイン' do
      let!(:headers) { @space_headers }
      it_behaves_like 'ToBase'
    end
    shared_examples_for '[ログイン中]存在するサブドメイン' do
      let!(:headers) { @space_headers }
      it_behaves_like 'ToBase'
    end
    shared_examples_for '[未ログイン]存在しないサブドメイン' do
      let!(:headers) { not_space_headers }
      it_behaves_like 'ToBase'
    end
    shared_examples_for '[ログイン中]存在しないサブドメイン' do
      let!(:headers) { not_space_headers }
      it_behaves_like 'ToBase'
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]ベースドメイン'
      it_behaves_like '[未ログイン]存在するサブドメイン'
      it_behaves_like '[未ログイン]存在しないサブドメイン'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中]ベースドメイン'
      it_behaves_like '[ログイン中]存在するサブドメイン'
      it_behaves_like '[ログイン中]存在しないサブドメイン'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[ログイン中]ベースドメイン'
      it_behaves_like '[ログイン中]存在するサブドメイン'
      it_behaves_like '[ログイン中]存在しないサブドメイン'
    end
  end

  # GET /customers（ベースドメイン） 所属一覧：顧客情報
  # GET /customers.json（ベースドメイン） 所属一覧API：顧客情報
  describe 'GET /index @customers' do
    let!(:headers) { base_headers }
    include_context '対象外の顧客作成', 1, 1, 1

    # テスト内容
    shared_examples_for 'ヘッダ情報' do
      it '(json)全件数が一致する' do
        get customers_path, headers: headers.merge(json_headers)
        expect(JSON.parse(response.body)['customer']['total_count']).to eq(@inside_customers.count)
      end
      it '(json)1ページ、現在ページが一致する' do
        get customers_path, headers: headers.merge(json_headers)
        expect(JSON.parse(response.body)['customer']['current_page']).to eq(1)
      end
      it '(json)2ページ、現在ページが一致する' do
        get customers_path(page: 2), headers: headers.merge(json_headers)
        expect(JSON.parse(response.body)['customer']['current_page']).to eq(2)
      end
      it '(json)全ページ数が一致する' do
        get customers_path, headers: headers.merge(json_headers)
        expect(JSON.parse(response.body)['customer']['total_pages']).to eq((@inside_customers.count - 1).div(Settings['default_customers_limit']) + 1)
      end
      it '(json)最大表示件数が一致する' do
        get customers_path, headers: headers.merge(json_headers)
        expect(JSON.parse(response.body)['customer']['limit_value']).to eq(Settings['default_customers_limit'])
      end
    end

    shared_examples_for '2ページ目リンク表示' do
      it 'パスが含まれる' do
        get customers_path, headers: headers
        expect(response.body).to include("\"#{customers_path(page: 2)}\"")
      end
    end
    shared_examples_for '2ページ目リンク非表示' do
      it 'パスが含まれない' do
        get customers_path, headers: headers
        expect(response.body).not_to include("\"#{customers_path(page: 2)}\"")
      end
    end

    shared_examples_for '対象のリスト表示' do |page|
      let!(:start_no) { Settings['default_customers_limit'] * (page - 1) + 1 }
      let!(:end_no) { [@inside_customers.count, Settings['default_customers_limit'] * page].min }
      it '顧客コードが含まれる' do
        get customers_path(page: page), headers: headers
        (start_no..end_no).each do |no|
          expect(response.body).to include(@inside_customers[no - 1].code)
        end
      end
      it '顧客名が含まれる' do
        get customers_path(page: page), headers: headers
        (start_no..end_no).each do |no|
          expect(response.body).to include(@inside_customers[no - 1].name)
        end
      end
      it 'メンバー一覧のパスが含まれる' do
        get customers_path(page: page), headers: headers
        (start_no..end_no).each do |no|
          expect(response.body).to include("\"#{customer_users_path(@inside_customers[no - 1].code)}\"")
        end
      end
      it '(json)顧客コードが一致する' do
        get customers_path(page: page), headers: headers.merge(json_headers)
        parse_response = JSON.parse(response.body)['customers']
        (start_no..end_no).each do |no|
          expect(parse_response[no - start_no]['code']).to eq(@inside_customers[no - 1].code)
        end
      end
      it '(json)顧客名が一致する' do
        get customers_path(page: page), headers: headers.merge(json_headers)
        parse_response = JSON.parse(response.body)['customers']
        (start_no..end_no).each do |no|
          expect(parse_response[no - start_no]['name']).to eq(@inside_customers[no - 1].name)
        end
      end
      it '(json)ユーザーの権限が一致する' do
        get customers_path(page: page), headers: headers.merge(json_headers)
        parse_response = JSON.parse(response.body)['customers']
        (start_no..end_no).each do |no|
          expect(parse_response[no - start_no]['current_user']['power']).to eq(@inside_customers[no - 1].customer_user[0].power)
        end
      end
    end
    shared_examples_for 'ページ外のリスト非表示' do |page, outside_page|
      let!(:start_no) { Settings['default_customers_limit'] * (outside_page - 1) + 1 }
      let!(:end_no) { [@inside_customers.count, Settings['default_customers_limit'] * outside_page].min }
      it '顧客コードが含まれない' do
        get customers_path(page: page), headers: headers
        (start_no..end_no).each do |no|
          expect(response.body).not_to include(@inside_customers[no - 1].code)
        end
      end
      it '顧客名が含まれない' do
        get customers_path(page: page), headers: headers
        (start_no..end_no).each do |no|
          expect(response.body).not_to include(@inside_customers[no - 1].name)
        end
      end
      it 'メンバー一覧のパスが含まれない' do
        get customers_path(page: page), headers: headers
        (start_no..end_no).each do |no|
          expect(response.body).not_to include("\"#{customer_users_path(@inside_customers[no - 1].code)}\"")
        end
      end
      it '(json)顧客コードが含まれない' do
        get customers_path(page: page), headers: headers.merge(json_headers)
        hash_responses = JSON.parse(response.body)['customers'].map { |response| [response['code'], response] }.to_h
        (start_no..end_no).each do |no|
          expect(hash_responses[@inside_customers[no - 1].code]).to be_nil
        end
      end
      it '(json)顧客名が含まれない' do
        get customers_path(page: page), headers: headers.merge(json_headers)
        hash_responses = JSON.parse(response.body)['customers'].map { |response| [response['name'], response] }.to_h
        (start_no..end_no).each do |no|
          expect(hash_responses[@inside_customers[no - 1].name]).to be_nil
        end
      end
    end
    shared_examples_for '対象外のリスト非表示' do |page|
      it '顧客コードが含まれない' do
        get customers_path(page: page), headers: headers
        (1..@outside_customers.count).each do |no|
          expect(response.body).not_to include(@outside_customers[no - 1].code)
        end
      end
      it '顧客名が含まれない' do
        get customers_path(page: page), headers: headers
        (1..@outside_customers.count).each do |no|
          expect(response.body).not_to include(@outside_customers[no - 1].name)
        end
      end
      it 'メンバー一覧のパスが含まれない' do
        get customers_path(page: page), headers: headers
        (1..@outside_customers.count).each do |no|
          expect(response.body).not_to include("\"#{customer_users_path(@outside_customers[no - 1].code)}\"")
        end
      end
      it '(json)顧客コードが含まれない' do
        get customers_path(page: page), headers: headers.merge(json_headers)
        hash_responses = JSON.parse(response.body)['customers'].map { |response| [response['code'], response] }.to_h
        (1..@outside_customers.count).each do |no|
          expect(hash_responses[@outside_customers[no - 1].code]).to be_nil
        end
      end
      it '(json)顧客名が含まれない' do
        get customers_path(page: page), headers: headers.merge(json_headers)
        hash_responses = JSON.parse(response.body)['customers'].map { |response| [response['name'], response] }.to_h
        (1..@outside_customers.count).each do |no|
          expect(hash_responses[@outside_customers[no - 1].name]).to be_nil
        end
      end
    end

    # テストケース
    shared_examples_for '所属する顧客が0件' do
      include_context '対象の顧客作成', 0, 0, 0
      it_behaves_like 'ヘッダ情報'
      it_behaves_like '2ページ目リンク非表示'
      it_behaves_like '対象外のリスト非表示', 1
    end
    shared_examples_for '所属する顧客が最大表示数と同じ' do
      include_context '対象の顧客作成', Settings['test_customers_owner'], Settings['test_customers_admin'], Settings['test_customers_member']
      it_behaves_like 'ヘッダ情報'
      it_behaves_like '2ページ目リンク非表示'
      it_behaves_like '対象のリスト表示', 1
      it_behaves_like '対象外のリスト非表示', 1
    end
    shared_examples_for '所属する顧客が最大表示数より多い' do
      include_context '対象の顧客作成', Settings['test_customers_owner'], Settings['test_customers_admin'], Settings['test_customers_member'] + 1
      it_behaves_like 'ヘッダ情報'
      it_behaves_like '2ページ目リンク表示'
      it_behaves_like '対象のリスト表示', 1
      it_behaves_like '対象のリスト表示', 2
      it_behaves_like 'ページ外のリスト非表示', 1, 2
      it_behaves_like 'ページ外のリスト非表示', 2, 1
      it_behaves_like '対象外のリスト非表示', 1
      it_behaves_like '対象外のリスト非表示', 2
    end

    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '所属する顧客が0件'
      it_behaves_like '所属する顧客が最大表示数と同じ'
      it_behaves_like '所属する顧客が最大表示数より多い'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '所属する顧客が0件'
      it_behaves_like '所属する顧客が最大表示数と同じ'
      it_behaves_like '所属する顧客が最大表示数より多い'
    end
  end
end
