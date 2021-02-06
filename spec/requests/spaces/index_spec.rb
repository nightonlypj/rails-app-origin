require 'rails_helper'

# TODO
RSpec.describe 'Spaces', type: :request do
=begin
  include_context '共通ヘッダー'

  # GET /spaces（ベースドメイン） スペース一覧
  # GET /spaces.json（ベースドメイン） スペース一覧API
  describe 'GET /index' do
    # テスト内容
    shared_examples_for 'ベースドメイン' do
      it '成功ステータス' do
        get spaces_path, headers: base_headers
        expect(response).to be_successful
      end
      it '(json)成功ステータス' do
        get spaces_path, headers: base_headers.merge(json_headers)
        expect(response).to be_successful
      end
    end
    shared_examples_for 'サブドメイン' do
      it 'スペース一覧（ベースドメイン）にリダイレクト' do
        get spaces_path, headers: @space_headers
        expect(response).to redirect_to("//#{Settings['base_domain']}#{spaces_path}")
      end
      it '(json)存在しないステータス' do
        get spaces_path, headers: @space_headers.merge(json_headers)
        expect(response).to be_not_found
      end
    end

    # 子テストケース
    shared_examples_for '存在するサブドメイン' do
      include_context 'リクエストスペース作成'
      it_behaves_like 'サブドメイン'
    end
    shared_examples_for '存在しないサブドメイン' do
      include_context '存在しないリクエストスペース'
      it_behaves_like 'サブドメイン'
    end

    # テストケース
    context '未ログイン' do
      it_behaves_like 'ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
  end

  # GET /spaces（ベースドメイン） スペース一覧：スペース一覧
  # GET /spaces.json（ベースドメイン） スペース一覧API：スペース一覧
  describe 'GET /index @spaces' do
    # テスト内容
    shared_examples_for 'ヘッダ情報' do
      it '(json)全件数が一致する' do
        get spaces_path, headers: base_headers.merge(json_headers)
        expect(JSON.parse(response.body)['total_count']).to eq(@create_spaces.count)
      end
      it '(json)1ページ、現在ページが一致する' do
        get spaces_path, headers: base_headers.merge(json_headers)
        expect(JSON.parse(response.body)['current_page']).to eq(1)
      end
      it '(json)2ページ、現在ページが一致する' do
        get spaces_path(page: 2), headers: base_headers.merge(json_headers)
        expect(JSON.parse(response.body)['current_page']).to eq(2)
      end
      it '(json)全ページ数が一致する' do
        get spaces_path, headers: base_headers.merge(json_headers)
        expect(JSON.parse(response.body)['total_pages']).to eq((@create_spaces.count - 1).div(Settings['default_spaces_limit']) + 1)
      end
      it '(json)最大表示件数が一致する' do
        get spaces_path, headers: base_headers.merge(json_headers)
        expect(JSON.parse(response.body)['limit_value']).to eq(Settings['default_spaces_limit'])
      end
    end

    shared_examples_for '2ページ目リンク表示' do
      it 'パスが含まれる' do
        get spaces_path, headers: base_headers
        expect(response.body).to include("\"#{spaces_path(page: 2)}\"")
      end
    end
    shared_examples_for '2ページ目リンク非表示' do
      it 'パスが含まれない' do
        get spaces_path, headers: base_headers
        expect(response.body).not_to include("\"#{spaces_path(page: 2)}\"")
      end
    end

    shared_examples_for '対象のリスト表示' do |page|
      it '名前が含まれる' do
        get spaces_path(page: page), headers: base_headers
        ((Settings['default_spaces_limit'] * (page - 1) + 1)..[@create_spaces.count, Settings['default_spaces_limit'] * page].min).each do |n|
          expect(response.body).to include(@create_spaces[@create_spaces.count - n].name)
        end
      end
      it 'パスが含まれる' do
        get spaces_path(page: page), headers: base_headers
        ((Settings['default_spaces_limit'] * (page - 1) + 1)..[@create_spaces.count, Settings['default_spaces_limit'] * page].min).each do |n|
          expect(response.body).to include("//#{@create_spaces[@create_spaces.count - n].subdomain}.#{Settings['base_domain']}")
        end
      end
      it '(json)名前が一致する' do
        get spaces_path(page: page), headers: base_headers.merge(json_headers)
        response_spaces = JSON.parse(response.body)['spaces']
        start = Settings['default_spaces_limit'] * (page - 1) + 1
        (start..[@create_spaces.count, Settings['default_spaces_limit'] * page].min).each do |n|
          expect(response_spaces[n - start]['name']).to eq(@create_spaces[@create_spaces.count - n].name)
        end
      end
      it '(json)サブドメインが一致する' do
        get spaces_path(page: page), headers: base_headers.merge(json_headers)
        response_spaces = JSON.parse(response.body)['spaces']
        start = Settings['default_spaces_limit'] * (page - 1) + 1
        (start..[@create_spaces.count, Settings['default_spaces_limit'] * page].min).each do |n|
          expect(response_spaces[n - start]['subdomain']).to eq(@create_spaces[@create_spaces.count - n].subdomain)
        end
      end
    end
    shared_examples_for 'ページ外のリスト非表示' do |page, outside_page|
      it '名前が含まれない' do
        get spaces_path(page: page), headers: base_headers
        ((Settings['default_spaces_limit'] * (outside_page - 1) + 1)..[@create_spaces.count, Settings['default_spaces_limit'] * outside_page].min).each do |n|
          expect(response.body).not_to include(@create_spaces[@create_spaces.count - n].name)
        end
      end
      it 'パスが含まれない' do
        get spaces_path(page: page), headers: base_headers
        ((Settings['default_spaces_limit'] * (outside_page - 1) + 1)..[@create_spaces.count, Settings['default_spaces_limit'] * outside_page].min).each do |n|
          expect(response.body).not_to include("//#{@create_spaces[@create_spaces.count - n].subdomain}.#{Settings['base_domain']}")
        end
      end
      it '(json)名前が含まれない' do
        get spaces_path(page: page), headers: base_headers.merge(json_headers)
        ((Settings['default_spaces_limit'] * (outside_page - 1) + 1)..[@create_spaces.count, Settings['default_spaces_limit'] * outside_page].min).each do |n|
          expect(response.body).not_to include(@create_spaces[@create_spaces.count - n].name)
        end
      end
      it '(json)サブドメインが含まれない' do
        get spaces_path(page: page), headers: base_headers.merge(json_headers)
        ((Settings['default_spaces_limit'] * (outside_page - 1) + 1)..[@create_spaces.count, Settings['default_spaces_limit'] * outside_page].min).each do |n|
          expect(response.body).not_to include("//#{@create_spaces[@create_spaces.count - n].subdomain}.#{Settings['base_domain']}")
        end
      end
    end

    shared_examples_for 'スペース作成リンク表示' do
      it 'パスが含まれる' do
        get spaces_path, headers: base_headers
        expect(response.body).to include("\"#{new_space_path}\"")
      end
    end

    shared_examples_for 'リダイレクト' do |page, redirect_page|
      it '最終ページにリダイレクト' do
        get spaces_path(customer_code: customer_code, page: page), headers: headers
        if redirect_page == 1
          expect(response).to redirect_to(spaces_path(customer_code: customer_code))
        else
          expect(response).to redirect_to(spaces_path(customer_code: customer_code, page: redirect_page))
        end
      end
      it '(json)リダイレクトしない' do
        get spaces_path(customer_code: customer_code, page: page, format: :json), headers: headers
        expect(response).to be_successful
      end
    end

    # 子テストケース
    shared_examples_for 'スペースが0件' do
      include_context 'スペース作成', 0
      it_behaves_like 'ヘッダ情報'
      it_behaves_like '2ページ目リンク非表示'
      it_behaves_like 'スペース作成リンク表示'
      it_behaves_like 'リダイレクト', 2, 1
    end
    shared_examples_for 'スペースが最大表示数と同じ' do
      include_context 'スペース作成', Settings['default_spaces_limit']
      it_behaves_like 'ヘッダ情報'
      it_behaves_like '2ページ目リンク非表示'
      it_behaves_like '対象のリスト表示', 1
      it_behaves_like 'スペース作成リンク表示'
      it_behaves_like 'リダイレクト', 2, 1
    end
    shared_examples_for 'スペースが最大表示数より多い' do
      include_context 'スペース作成', Settings['default_spaces_limit'] + 1
      it_behaves_like 'ヘッダ情報'
      it_behaves_like '2ページ目リンク表示'
      it_behaves_like '対象のリスト表示', 1
      it_behaves_like '対象のリスト表示', 2
      it_behaves_like 'ページ外のリスト非表示', 1, 2
      it_behaves_like 'ページ外のリスト非表示', 2, 1
      it_behaves_like 'スペース作成リンク表示'
      it_behaves_like 'リダイレクト', 3, 2
    end

    # テストケース
    context '未ログイン' do
      it_behaves_like 'スペースが0件'
      it_behaves_like 'スペースが最大表示数と同じ'
      it_behaves_like 'スペースが最大表示数より多い'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'スペースが0件'
      it_behaves_like 'スペースが最大表示数と同じ'
      it_behaves_like 'スペースが最大表示数より多い'
    end
  end
=end
end
