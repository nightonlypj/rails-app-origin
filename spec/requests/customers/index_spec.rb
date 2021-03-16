require 'rails_helper'

RSpec.describe 'Customers', type: :request do
  include_context 'リクエストスペース作成'

  # GET /customers（ベースドメイン） 所属顧客一覧
  # GET /customers.json（ベースドメイン） 所属顧客一覧API
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   ベースドメイン, 存在するサブドメイン, 存在しないサブドメイン → 事前にデータ作成
  describe 'GET #index' do
    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get customers_path, headers: headers
        expect(response).to be_successful
      end
      it '(json)成功ステータス' do
        get customers_path(format: :json), headers: headers
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToLogin' do |alert, notice, error|
      it 'ログインにリダイレクト' do
        get customers_path, headers: headers
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
      it '(json)認証エラー' do
        get customers_path(format: :json), headers: headers
        expect(response).to be_unauthorized
        message = response.body.present? ? JSON.parse(response.body)['error'] : nil
        expect(message).to error.present? ? eq(I18n.t(error)) : be_nil
      end
    end
    shared_examples_for 'ToBase' do |alert, notice, error|
      it 'ベースドメインにリダイレクト' do
        get customers_path, headers: headers
        expect(response).to redirect_to("//#{Settings['base_domain']}#{customers_path}")
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
      it '(json)存在しないエラー' do
        get customers_path(format: :json), headers: headers
        expect(response).to be_not_found
        message = response.body.present? ? JSON.parse(response.body)['error'] : nil
        expect(message).to error.present? ? eq(I18n.t(error)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToLogin', 'devise.failure.unauthenticated', nil, 'devise.failure.unauthenticated'
    end
    shared_examples_for '[ログイン中/削除予約済み]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[*]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'ToBase', nil, nil, 'errors.messages.domain_error'
    end
    shared_examples_for '[*]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      it_behaves_like 'ToBase', nil, nil, 'errors.messages.domain_error'
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]ベースドメイン'
      it_behaves_like '[*]存在するサブドメイン'
      it_behaves_like '[*]存在しないサブドメイン'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中/削除予約済み]ベースドメイン'
      it_behaves_like '[*]存在するサブドメイン'
      it_behaves_like '[*]存在しないサブドメイン'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[ログイン中/削除予約済み]ベースドメイン'
      it_behaves_like '[*]存在するサブドメイン'
      it_behaves_like '[*]存在しないサブドメイン'
    end
  end

  # 顧客情報
  # 前提条件
  #   ベースドメイン, ログイン中/削除予約済み
  # テストパターン
  #   ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   所属する顧客: ない, 最大表示数と同じ, 最大表示数より多い → データ作成
  describe '@customers' do
    let!(:headers) { BASE_HEADER }

    # テスト内容
    shared_examples_for 'ページ情報' do |page|
      it '(json)全件数が一致する' do
        get customers_path(page: page, format: :json), headers: headers
        expect(JSON.parse(response.body)['customer']['total_count']).to eq(@create_customers.count)
      end
      it '(json)現在ページが一致する' do
        get customers_path(page: page, format: :json), headers: headers
        expect(JSON.parse(response.body)['customer']['current_page']).to eq(page)
      end
      it '(json)全ページ数が一致する' do
        get customers_path(page: page, format: :json), headers: headers
        expect(JSON.parse(response.body)['customer']['total_pages']).to eq((@create_customers.count - 1).div(Settings['default_customers_limit']) + 1)
      end
      it '(json)最大表示件数が一致する' do
        get customers_path(page: page, format: :json), headers: headers
        expect(JSON.parse(response.body)['customer']['limit_value']).to eq(Settings['default_customers_limit'])
      end
    end

    shared_examples_for 'ページネーション表示' do |page, link_page|
      it 'パスが含まれる' do
        get customers_path(page: page), headers: headers
        if link_page == 1
          expect(response.body).to include("\"#{customers_path}\"")
        else
          expect(response.body).to include("\"#{customers_path(page: link_page)}\"")
        end
      end
    end
    shared_examples_for 'ページネーション非表示' do |page, link_page|
      it 'パスが含まれない' do
        get customers_path(page: page), headers: headers
        if link_page == 1
          expect(response.body).not_to include("\"#{customers_path}\"")
        else
          expect(response.body).not_to include("\"#{customers_path(page: link_page)}\"")
        end
      end
    end

    shared_examples_for 'リスト表示' do |page|
      let!(:start_no) { Settings['default_customers_limit'] * (page - 1) + 1 }
      let!(:end_no) { [@create_customers.count, Settings['default_customers_limit'] * page].min }
      it '(json)配列の件数が一致する' do
        get customers_path(page: page, format: :json), headers: headers
        expect(JSON.parse(response.body)['customers'].count).to eq(end_no - start_no + 1)
      end
      it '顧客コードが含まれる' do
        get customers_path(page: page), headers: headers
        (start_no..end_no).each do |no|
          expect(response.body).to include(@create_customers[no - 1].code)
        end
      end
      it '(json)顧客コードが一致する' do
        get customers_path(page: page, format: :json), headers: headers
        parse_response = JSON.parse(response.body)['customers']
        (start_no..end_no).each do |no|
          expect(parse_response[no - start_no]['code']).to eq(@create_customers[no - 1].code)
        end
      end
      it '組織・団体名が含まれる' do
        get customers_path(page: page), headers: headers
        (start_no..end_no).each do |no|
          expect(response.body).to include(@create_customers[no - 1].name)
        end
      end
      it '(json)組織・団体名が一致する' do
        get customers_path(page: page, format: :json), headers: headers
        parse_response = JSON.parse(response.body)['customers']
        (start_no..end_no).each do |no|
          expect(parse_response[no - start_no]['name']).to eq(@create_customers[no - 1].name)
        end
      end
      it '顧客情報のパスが含まれる' do
        get customers_path(page: page), headers: headers
        (start_no..end_no).each do |no|
          expect(response.body).to include("\"#{customer_path(customer_code: @create_customers[no - 1].code)}\"")
        end
      end
      it '登録日が含まれる' do # Tips: ユニークではない為、正確ではない
        get customers_path(page: page), headers: headers
        (start_no..end_no).each do |no|
          expect(response.body).to include(I18n.l(@create_customers[no - 1].created_at.to_date))
        end
      end
      it '(json)登録日時が一致する' do
        get customers_path(page: page, format: :json), headers: headers
        parse_response = JSON.parse(response.body)['customers']
        (start_no..end_no).each do |no|
          expect(parse_response[no - start_no]['created_at']).to eq(I18n.l(@create_customers[no - 1].created_at, format: :json))
        end
      end
      it 'ユーザーの権限が含まれる' do # Tips: ユニークではない為、正確ではない
        get customers_path(page: page), headers: headers
        (start_no..end_no).each do |no|
          expect(response.body).to include(@create_customers[no - 1].member.first.power_i18n)
        end
      end
      it '(json)ユーザーの権限が一致する' do
        get customers_path(page: page, format: :json), headers: headers
        parse_response = JSON.parse(response.body)['customers']
        (start_no..end_no).each do |no|
          expect(parse_response[no - start_no]['current_user']['power']).to eq(@create_customers[no - 1].member.first.power)
        end
      end
    end

    shared_examples_for 'リダイレクト' do |page, redirect_page|
      it '最終ページにリダイレクト' do
        get customers_path(page: page), headers: headers
        if redirect_page == 1
          expect(response).to redirect_to(customers_path)
        else
          expect(response).to redirect_to(customers_path(page: redirect_page))
        end
      end
      it '(json)リダイレクトしない' do
        get customers_path(page: page, format: :json), headers: headers
        expect(response).to be_successful
      end
    end

    # テストケース
    shared_examples_for '[ログイン中/削除予約済み]所属する顧客がない' do
      include_context '顧客作成', 0, 0, 0
      it_behaves_like 'ページ情報', 1
      it_behaves_like 'ページネーション非表示', 1, 2
      it_behaves_like 'リダイレクト', 2, 1
    end
    shared_examples_for '[ログイン中/削除予約済み]所属する顧客が最大表示数と同じ' do
      include_context '顧客作成', Settings['test_customers_owner'], Settings['test_customers_admin'], Settings['test_customers_member']
      it_behaves_like 'ページ情報', 1
      it_behaves_like 'ページネーション非表示', 1, 2
      it_behaves_like 'リスト表示', 1
      it_behaves_like 'リダイレクト', 2, 1
    end
    shared_examples_for '[ログイン中/削除予約済み]所属する顧客が最大表示数より多い' do
      include_context '顧客作成', Settings['test_customers_owner'], Settings['test_customers_admin'], Settings['test_customers_member'] + 1
      it_behaves_like 'ページ情報', 1
      it_behaves_like 'ページ情報', 2
      it_behaves_like 'ページネーション表示', 1, 2
      it_behaves_like 'ページネーション表示', 2, 1
      it_behaves_like 'リスト表示', 1
      it_behaves_like 'リスト表示', 2
      it_behaves_like 'リダイレクト', 3, 2
    end

    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中/削除予約済み]所属する顧客がない'
      it_behaves_like '[ログイン中/削除予約済み]所属する顧客が最大表示数と同じ'
      it_behaves_like '[ログイン中/削除予約済み]所属する顧客が最大表示数より多い'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[ログイン中/削除予約済み]所属する顧客がない'
      it_behaves_like '[ログイン中/削除予約済み]所属する顧客が最大表示数と同じ'
      it_behaves_like '[ログイン中/削除予約済み]所属する顧客が最大表示数より多い'
    end
  end
end
