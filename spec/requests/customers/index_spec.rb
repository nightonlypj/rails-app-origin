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

  # GET /customers（ベースドメイン） 所属一覧：所属一覧リスト
  # GET /customers.json（ベースドメイン） 所属一覧API：所属一覧リスト
  describe 'GET /index @customers' do
    let!(:headers) { base_headers }

    # テスト内容
    shared_examples_for 'ヘッダ情報' do
      it '(json)全件数が一致する' do
        get customers_path, headers: headers.merge(json_headers)
        expect(JSON.parse(response.body)['total_count']).to eq(@inside_customers.count)
      end
      it '(json)1ページ、現在ページが一致する' do
        get customers_path, headers: headers.merge(json_headers)
        expect(JSON.parse(response.body)['current_page']).to eq(1)
      end
      it '(json)2ページ、現在ページが一致する' do
        get customers_path(page: 2), headers: headers.merge(json_headers)
        expect(JSON.parse(response.body)['current_page']).to eq(2)
      end
      it '(json)全ページ数が一致する' do
        get customers_path, headers: headers.merge(json_headers)
        expect(JSON.parse(response.body)['total_pages']).to eq((@inside_customers.count - 1).div(Settings['default_customers_limit']) + 1)
      end
      it '(json)最大表示件数が一致する' do
        get customers_path, headers: headers.merge(json_headers)
        expect(JSON.parse(response.body)['limit_value']).to eq(Settings['default_customers_limit'])
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
      it '名前が含まれる' do
        get customers_path(page: page), headers: headers
        (start_no..end_no).each do |no|
          expect(response.body).to include(@inside_customers[no - 1].name)
        end
      end
      it '(json)名前が一致する' do
        get customers_path(page: page), headers: headers.merge(json_headers)
        response_customers = JSON.parse(response.body)['customers']
        (start_no..end_no).each do |no|
          expect(response_customers[no - start_no]['name']).to eq(@inside_customers[no - 1].name)
        end
      end
      it '(json)ユーザーの権限が一致する' do
        get customers_path(page: page), headers: headers.merge(json_headers)
        response_customers = JSON.parse(response.body)['customers']
        (start_no..end_no).each do |no|
          expect(response_customers[no - start_no]['current_user'][0]['power']).to eq(@inside_customers[no - 1].customer_user[0].power)
        end
      end
    end
    shared_examples_for 'ページ外のリスト非表示' do |page, outside_page|
      let!(:start_no) { Settings['default_customers_limit'] * (outside_page - 1) + 1 }
      let!(:end_no) { [@inside_customers.count, Settings['default_customers_limit'] * outside_page].min }
      it '名前が含まれない' do
        get customers_path(page: page), headers: headers
        (start_no..end_no).each do |no|
          expect(response.body).not_to include(@inside_customers[no - 1].name)
        end
      end
      it '(json)名前が含まれない' do
        get customers_path(page: page), headers: headers.merge(json_headers)
        response_customers = JSON.parse(response.body)['customers'].map { |response| [response['name'], response] }.to_h
        (start_no..end_no).each do |no|
          expect(response_customers[@inside_customers[no - 1].name]).to be_nil
        end
      end
    end
    shared_examples_for '対象外のリスト非表示' do |page|
      it '名前が含まれない' do
        get customers_path(page: page), headers: headers
        (1..@outside_customers.count).each do |no|
          expect(response.body).not_to include(@outside_customers[no - 1].name)
        end
      end
      it '(json)名前が含まれない' do
        get customers_path(page: page), headers: headers.merge(json_headers)
        response_customers = JSON.parse(response.body)['customers'].map { |response| [response['name'], response] }.to_h
        (1..@outside_customers.count).each do |no|
          expect(response_customers[@outside_customers[no - 1].name]).to be_nil
        end
      end
    end

    # テストケース
    shared_examples_for '所属する顧客が0件' do
      include_context '顧客作成', 3
      include_context 'メンバー作成', 0, 0, 0, 1, 1, 1
      include_context '所属顧客取得', 0
      include_context '未所属顧客取得', 3
      it_behaves_like 'ヘッダ情報'
      it_behaves_like '2ページ目リンク非表示'
      it_behaves_like '対象外のリスト非表示', 1
    end
    shared_examples_for '所属する顧客が最大表示数と同じ' do
      owner_count = (Settings['default_customers_limit'] / 3).ceil
      admin_count = owner_count
      member_count = Settings['default_customers_limit'] - owner_count - admin_count
      include_context '顧客作成', owner_count + admin_count + member_count + 3
      include_context 'メンバー作成', owner_count, admin_count, member_count, 1, 1, 1
      include_context '所属顧客取得', owner_count + admin_count + member_count
      include_context '未所属顧客取得', 3
      it_behaves_like 'ヘッダ情報'
      it_behaves_like '2ページ目リンク非表示'
      it_behaves_like '対象のリスト表示', 1
      it_behaves_like '対象外のリスト非表示', 1
    end
    shared_examples_for '所属する顧客が最大表示数より多い' do
      owner_count = (Settings['default_customers_limit'] / 3).ceil
      admin_count = owner_count
      member_count = Settings['default_customers_limit'] - owner_count - admin_count + 1
      include_context '顧客作成', owner_count + admin_count + member_count + 3
      include_context 'メンバー作成', owner_count, admin_count, member_count, 1, 1, 1
      include_context '所属顧客取得', owner_count + admin_count + member_count
      include_context '未所属顧客取得', 3
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
