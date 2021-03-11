require 'rails_helper'

RSpec.describe 'Spaces', type: :request do
  # GET /spaces（ベースドメイン） 参加スペース一覧
  # GET /spaces.json（ベースドメイン） 参加スペース一覧API
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   ベースドメイン, 存在するサブドメイン, 存在しないサブドメイン → 事前にデータ作成
  describe 'GET #index' do
    include_context 'リクエストスペース作成'

    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get spaces_path, headers: headers
        expect(response).to be_successful
      end
      it '(json)成功ステータス' do
        get spaces_path(format: :json), headers: headers
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToLogin' do |alert, notice, error|
      it 'ログインにリダイレクト' do
        get spaces_path, headers: headers
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
      it '(json)認証エラー' do
        get spaces_path(format: :json), headers: headers
        expect(response).to be_unauthorized
        message = response.body.present? ? JSON.parse(response.body)['error'] : nil
        expect(message).to error.present? ? eq(I18n.t(error)) : be_nil
      end
    end
    shared_examples_for 'ToBase' do |alert, notice, error|
      it 'ベースドメインにリダイレクト' do
        get spaces_path, headers: headers
        expect(response).to redirect_to("//#{Settings['base_domain']}#{spaces_path}")
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
      it '(json)存在しないエラー' do
        get spaces_path(format: :json), headers: headers
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

  # 参加スペース
  # 前提条件
  #   ベースドメイン, ログイン中/削除予約済み
  # テストパターン
  #   ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   参加スペース: ない, 最大表示数と同じ, 最大表示数より多い → データ作成
  describe '@spaces' do
    let!(:headers) { BASE_HEADER }
    include_context 'スペース作成', 1 # Tips: 未所属
    include_context 'スペース作成', 1, true # Tips: 公開スペース

    # テスト内容
    shared_examples_for 'ページ情報' do |page|
      it '(json)全件数が一致する' do
        get spaces_path(page: page, format: :json), headers: headers
        expect(JSON.parse(response.body)['join_space']['total_count']).to eq(@create_spaces.count)
      end
      it '(json)現在ページが一致する' do
        get spaces_path(page: page, format: :json), headers: headers
        expect(JSON.parse(response.body)['join_space']['current_page']).to eq(page)
      end
      it '(json)全ページ数が一致する' do
        get spaces_path(page: page, format: :json), headers: headers
        expect(JSON.parse(response.body)['join_space']['total_pages']).to eq((@create_spaces.count - 1).div(Settings['default_spaces_limit']) + 1)
      end
      it '(json)最大表示件数が一致する' do
        get spaces_path(page: page, format: :json), headers: headers
        expect(JSON.parse(response.body)['join_space']['limit_value']).to eq(Settings['default_spaces_limit'])
      end
      it 'スペース作成のパスが含まれる' do
        get spaces_path(page: page), headers: headers
        expect(response.body).to include("\"#{new_space_path}\"")
      end
    end

    shared_examples_for 'ページネーション表示' do |page, link_page|
      it 'パスが含まれる' do
        get spaces_path(page: page), headers: headers
        if link_page == 1
          expect(response.body).to include("\"#{spaces_path}\"")
        else
          expect(response.body).to include("\"#{spaces_path(page: link_page)}\"")
        end
      end
    end
    shared_examples_for 'ページネーション非表示' do |page, link_page|
      it 'パスが含まれない' do
        get spaces_path(page: page), headers: headers
        if link_page == 1
          expect(response.body).not_to include("\"#{spaces_path}\"")
        else
          expect(response.body).not_to include("\"#{spaces_path(page: link_page)}\"")
        end
      end
    end

    shared_examples_for 'リスト表示' do |page|
      let!(:start_no) { Settings['default_spaces_limit'] * (page - 1) + 1 }
      let!(:end_no) { [@create_spaces.count, Settings['default_spaces_limit'] * page].min }
      it '(json)配列の件数が一致する' do
        get spaces_path(page: page, format: :json), headers: headers
        expect(JSON.parse(response.body)['join_spaces'].count).to eq(end_no - start_no + 1)
      end
      it 'スペーストップのパスが含まれる' do
        get spaces_path(page: page), headers: headers
        (start_no..end_no).each do |no|
          expect(response.body).to include("//#{@create_spaces[@create_spaces.count - no].subdomain}.#{Settings['base_domain']}")
        end
      end
      it '(json)サブドメインが含まれる' do
        get spaces_path(page: page, format: :json), headers: headers
        parse_response = JSON.parse(response.body)['join_spaces']
        (start_no..end_no).each do |no|
          expect(parse_response[no - start_no]['subdomain']).to eq(@create_spaces[@create_spaces.count - no].subdomain)
        end
      end
      it '画像URLが含まれる' do # Tips: ユニークではない為、正確ではない
        get spaces_path(page: page), headers: headers
        (start_no..end_no).each do |no|
          expect(response.body).to include("\"#{@create_spaces[@create_spaces.count - no].image_url(:small)}\"")
        end
      end
      it '(json)画像URLが一致する' do
        get spaces_path(page: page, format: :json), headers: headers
        parse_response = JSON.parse(response.body)['join_spaces']
        (start_no..end_no).each do |no|
          image_url = "https://#{Settings['base_domain']}#{@create_spaces[@create_spaces.count - no].image_url(:small)}"
          expect(parse_response[no - start_no]['image_url']).to eq(image_url)
        end
      end
      it 'スペース名が含まれる' do
        get spaces_path(page: page), headers: headers
        (start_no..end_no).each do |no|
          expect(response.body).to include(@create_spaces[@create_spaces.count - no].name)
        end
      end
      it '(json)スペース名が一致する' do
        get spaces_path(page: page, format: :json), headers: headers
        parse_response = JSON.parse(response.body)['join_spaces']
        (start_no..end_no).each do |no|
          expect(parse_response[no - start_no]['name']).to eq(@create_spaces[@create_spaces.count - no].name)
        end
      end
      it '(json)目的が一致する' do
        get spaces_path(page: page, format: :json), headers: headers
        parse_response = JSON.parse(response.body)['join_spaces']
        (start_no..end_no).each do |no|
          expect(parse_response[no - start_no]['purpose']).to eq(@create_spaces[@create_spaces.count - no].purpose)
        end
      end
      it '(json)公開スペースが一致する' do
        get spaces_path(page: page, format: :json), headers: headers
        parse_response = JSON.parse(response.body)['join_spaces']
        (start_no..end_no).each do |no|
          expect(parse_response[no - start_no]['public_flag']).to eq(@create_spaces[@create_spaces.count - no].public_flag)
        end
      end
      it '作成日が含まれる' do
        get spaces_path(page: page), headers: headers
        (start_no..end_no).each do |no|
          expect(response.body).to include(I18n.l(@create_spaces[@create_spaces.count - no].created_at.to_date))
        end
      end
      it '(json)作成日時が一致する' do
        get spaces_path(page: page, format: :json), headers: headers
        parse_response = JSON.parse(response.body)['join_spaces']
        (start_no..end_no).each do |no|
          expect(parse_response[no - start_no]['created_at']).to eq(I18n.l(@create_spaces[@create_spaces.count - no].created_at, format: :json))
        end
      end
      it '顧客詳細のパスが含まれる' do
        get spaces_path(page: page), headers: headers
        (start_no..end_no).each do |no|
          expect(response.body).to include("\"#{customer_path(customer_code: @create_spaces[@create_spaces.count - no].customer.code)}\"")
        end
      end
      it '顧客コードが含まれる' do # Tips: 顧客詳細のパスに含まれる為、正確ではない
        get spaces_path(page: page), headers: headers
        (start_no..end_no).each do |no|
          expect(response.body).to include(@create_spaces[@create_spaces.count - no].customer.code)
        end
      end
      it '(json)顧客コードが一致する' do
        get spaces_path(page: page, format: :json), headers: headers
        parse_response = JSON.parse(response.body)['join_spaces']
        (start_no..end_no).each do |no|
          expect(parse_response[no - start_no]['customer']['code']).to eq(@create_spaces[@create_spaces.count - no].customer.code)
        end
      end
      it '組織・団体名が含まれる' do
        get spaces_path(page: page), headers: headers
        (start_no..end_no).each do |no|
          expect(response.body).to include(@create_spaces[@create_spaces.count - no].customer.name)
        end
      end
      it '(json)組織・団体名が一致する' do
        get spaces_path(page: page, format: :json), headers: headers
        parse_response = JSON.parse(response.body)['join_spaces']
        (start_no..end_no).each do |no|
          expect(parse_response[no - start_no]['customer']['name']).to eq(@create_spaces[@create_spaces.count - no].customer.name)
        end
      end
      it 'スペース情報変更のパスが含まれる（Owner/Adminの場合）' do
        get spaces_path(page: page), headers: headers
        (start_no..end_no).each do |no|
          customer_id = @create_spaces[@create_spaces.count - no].customer_id
          if customer_id == member_owner.customer_id || customer_id == member_admin.customer_id
            expect(response.body).to include("\"//#{@create_spaces[@create_spaces.count - no].subdomain}.#{Settings['base_domain']}#{edit_space_path}\"")
          end
        end
      end
      it 'スペース情報変更のパスが含まれない（Owner/Admin以外の場合）' do
        get spaces_path(page: page), headers: headers
        (start_no..end_no).each do |no|
          customer_id = @create_spaces[@create_spaces.count - no].customer_id
          if customer_id != member_owner.customer_id && customer_id != member_admin.customer_id
            expect(response.body).not_to include("\"//#{@create_spaces[@create_spaces.count - no].subdomain}.#{Settings['base_domain']}#{edit_space_path}\"")
          end
        end
      end
    end

    shared_examples_for 'リダイレクト' do |page, redirect_page|
      it '最終ページにリダイレクト' do
        get spaces_path(page: page), headers: headers
        if redirect_page == 1
          expect(response).to redirect_to(spaces_path)
        else
          expect(response).to redirect_to(spaces_path(page: redirect_page))
        end
      end
      it '(json)リダイレクトしない' do
        get spaces_path(page: page, format: :json), headers: headers
        expect(response).to be_successful
      end
    end

    # テストケース
    shared_examples_for '[ログイン中/削除予約済み]スペースがない' do
      include_context 'スペース作成（3顧客）', 0, 0, 0
      it_behaves_like 'ページ情報', 1
      it_behaves_like 'ページネーション非表示', 1, 2
      it_behaves_like 'リダイレクト', 2, 1
    end
    shared_examples_for '[ログイン中/削除予約済み]スペースが最大表示数と同じ' do
      include_context 'スペース作成（3顧客）', Settings['test_spaces_owner'], Settings['test_spaces_admin'], Settings['test_spaces_member']
      include_context '顧客・ユーザー紐付け（3顧客・権限）'
      it_behaves_like 'ページ情報', 1
      it_behaves_like 'ページネーション非表示', 1, 2
      it_behaves_like 'リスト表示', 1
      it_behaves_like 'リダイレクト', 2, 1
    end
    shared_examples_for '[ログイン中/削除予約済み]スペースが最大表示数より多い' do
      include_context 'スペース作成（3顧客）', Settings['test_spaces_owner'], Settings['test_spaces_admin'], Settings['test_spaces_member'] + 1
      include_context '顧客・ユーザー紐付け（3顧客・権限）'
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
      it_behaves_like '[ログイン中/削除予約済み]スペースがない'
      it_behaves_like '[ログイン中/削除予約済み]スペースが最大表示数と同じ'
      it_behaves_like '[ログイン中/削除予約済み]スペースが最大表示数より多い'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[ログイン中/削除予約済み]スペースがない'
      it_behaves_like '[ログイン中/削除予約済み]スペースが最大表示数と同じ'
      it_behaves_like '[ログイン中/削除予約済み]スペースが最大表示数より多い'
    end
  end
end
