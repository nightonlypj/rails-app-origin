require 'rails_helper'

RSpec.describe 'Spaces', type: :request do
  # GET /spaces/public（ベースドメイン） 公開スペース一覧
  # GET /spaces/public.json（ベースドメイン） 公開スペース一覧API
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   ベースドメイン, 存在するサブドメイン, 存在しないサブドメイン → 事前にデータ作成
  describe 'GET /index_public' do
    include_context 'リクエストスペース作成'

    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get public_spaces_path, headers: headers
        expect(response).to be_successful
      end
      it '(json)成功ステータス' do
        get public_spaces_path(format: :json), headers: headers
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToBase' do |alert, notice, error|
      it 'ベースドメインにリダイレクト' do
        get public_spaces_path, headers: headers
        expect(response).to redirect_to("//#{Settings['base_domain']}#{public_spaces_path}")
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
      it '(json)存在しないエラー' do
        get public_spaces_path(format: :json), headers: headers
        expect(response).to be_not_found
        message = response.body.present? ? JSON.parse(response.body)['error'] : nil
        expect(message).to error.present? ? eq(I18n.t(error)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[*]ベースドメイン' do
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
      it_behaves_like '[*]ベースドメイン'
      it_behaves_like '[*]存在するサブドメイン'
      it_behaves_like '[*]存在しないサブドメイン'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[*]ベースドメイン'
      it_behaves_like '[*]存在するサブドメイン'
      it_behaves_like '[*]存在しないサブドメイン'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[*]ベースドメイン'
      it_behaves_like '[*]存在するサブドメイン'
      it_behaves_like '[*]存在しないサブドメイン'
    end
  end

  # 公開スペース
  # 前提条件
  #   ベースドメイン, ログイン中/削除予約済み
  # テストパターン
  #   ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   公開スペース: ない, 最大表示数と同じ, 最大表示数より多い → データ作成
  describe 'GET /index @spaces' do
    let!(:headers) { BASE_HEADER }
    include_context 'スペース作成', 1 # Tips: 非公開スペース

    # テスト内容
    shared_examples_for 'ページ情報' do |page|
      it '(json)全件数が一致する' do
        get public_spaces_path(page: page, format: :json), headers: headers
        expect(JSON.parse(response.body)['public_space']['total_count']).to eq(@create_spaces.count)
      end
      it '(json)現在ページが一致する' do
        get public_spaces_path(page: page, format: :json), headers: headers
        expect(JSON.parse(response.body)['public_space']['current_page']).to eq(page)
      end
      it '(json)全ページ数が一致する' do
        get public_spaces_path(page: page, format: :json), headers: headers
        expect(JSON.parse(response.body)['public_space']['total_pages']).to eq((@create_spaces.count - 1).div(Settings['default_spaces_limit']) + 1)
      end
      it '(json)最大表示件数が一致する' do
        get public_spaces_path(page: page, format: :json), headers: headers
        expect(JSON.parse(response.body)['public_space']['limit_value']).to eq(Settings['default_spaces_limit'])
      end
      it 'スペース作成のパスが含まれる' do
        get public_spaces_path(page: page), headers: headers
        expect(response.body).to include("\"#{new_space_path}\"")
      end
    end

    shared_examples_for 'ページネーション表示' do |page, link_page|
      it 'パスが含まれる' do
        get public_spaces_path(page: page), headers: headers
        if link_page == 1
          expect(response.body).to include("\"#{public_spaces_path}\"")
        else
          expect(response.body).to include("\"#{public_spaces_path(page: link_page)}\"")
        end
      end
    end
    shared_examples_for 'ページネーション非表示' do |page, link_page|
      it 'パスが含まれない' do
        get public_spaces_path(page: page), headers: headers
        if link_page == 1
          expect(response.body).not_to include("\"#{public_spaces_path}\"")
        else
          expect(response.body).not_to include("\"#{public_spaces_path(page: link_page)}\"")
        end
      end
    end

    shared_examples_for 'リスト表示' do |page|
      let!(:start_no) { Settings['default_spaces_limit'] * (page - 1) + 1 }
      let!(:end_no) { [@create_spaces.count, Settings['default_spaces_limit'] * page].min }
      it '(json)配列の件数が一致する' do
        get public_spaces_path(page: page, format: :json), headers: headers
        expect(JSON.parse(response.body)['public_spaces'].count).to eq(end_no - start_no + 1)
      end
      it 'スペーストップのパスが含まれる' do
        get public_spaces_path(page: page), headers: headers
        (start_no..end_no).each do |no|
          expect(response.body).to include("//#{@create_spaces[@create_spaces.count - no].subdomain}.#{Settings['base_domain']}")
        end
      end
      it '(json)サブドメインが含まれる' do
        get public_spaces_path(page: page, format: :json), headers: headers
        parse_response = JSON.parse(response.body)['public_spaces']
        (start_no..end_no).each do |no|
          expect(parse_response[no - start_no]['subdomain']).to eq(@create_spaces[@create_spaces.count - no].subdomain)
        end
      end
      it '画像URLが含まれる' do # Tips: ユニークではない為、正確ではない
        get public_spaces_path(page: page), headers: headers
        (start_no..end_no).each do |no|
          expect(response.body).to include("\"#{@create_spaces[@create_spaces.count - no].image_url(:small)}\"")
        end
      end
      it '(json)画像URLが一致する' do
        get public_spaces_path(page: page, format: :json), headers: headers
        parse_response = JSON.parse(response.body)['public_spaces']
        (start_no..end_no).each do |no|
          image_url = "https://#{Settings['base_domain']}#{@create_spaces[@create_spaces.count - no].image_url(:small)}"
          expect(parse_response[no - start_no]['image_url']).to eq(image_url)
        end
      end
      it 'スペース名が含まれる' do
        get public_spaces_path(page: page), headers: headers
        (start_no..end_no).each do |no|
          expect(response.body).to include(@create_spaces[@create_spaces.count - no].name)
        end
      end
      it '(json)スペース名が一致する' do
        get public_spaces_path(page: page, format: :json), headers: headers
        parse_response = JSON.parse(response.body)['public_spaces']
        (start_no..end_no).each do |no|
          expect(parse_response[no - start_no]['name']).to eq(@create_spaces[@create_spaces.count - no].name)
        end
      end
      it '目的が含まれる' do
        get public_spaces_path(page: page), headers: headers
        (start_no..end_no).each do |no|
          expect(response.body).to include(@create_spaces[@create_spaces.count - no].purpose)
        end
      end
      it '(json)目的が一致する' do
        get public_spaces_path(page: page, format: :json), headers: headers
        parse_response = JSON.parse(response.body)['public_spaces']
        (start_no..end_no).each do |no|
          expect(parse_response[no - start_no]['purpose']).to eq(@create_spaces[@create_spaces.count - no].purpose)
        end
      end
      it '作成日が含まれる' do
        get public_spaces_path(page: page), headers: headers
        (start_no..end_no).each do |no|
          expect(response.body).to include(I18n.l(@create_spaces[@create_spaces.count - no].created_at.to_date))
        end
      end
      it '(json)作成日時が一致する' do
        get public_spaces_path(page: page, format: :json), headers: headers
        parse_response = JSON.parse(response.body)['public_spaces']
        (start_no..end_no).each do |no|
          expect(parse_response[no - start_no]['created_at']).to eq(I18n.l(@create_spaces[@create_spaces.count - no].created_at, format: :json))
        end
      end
    end

    shared_examples_for 'リダイレクト' do |page, redirect_page|
      it '最終ページにリダイレクト' do
        get public_spaces_path(page: page), headers: headers
        if redirect_page == 1
          expect(response).to redirect_to(public_spaces_path)
        else
          expect(response).to redirect_to(public_spaces_path(page: redirect_page))
        end
      end
      it '(json)リダイレクトしない' do
        get public_spaces_path(page: page, format: :json), headers: headers
        expect(response).to be_successful
      end
    end

    # テストケース
    shared_examples_for '[ログイン中/削除予約済み]スペースがない' do
      include_context 'スペース作成', 0, true
      it_behaves_like 'ページ情報', 1
      it_behaves_like 'ページネーション非表示', 1, 2
      it_behaves_like 'リダイレクト', 2, 1
    end
    shared_examples_for '[ログイン中/削除予約済み]スペースが最大表示数と同じ' do
      include_context 'スペース作成', Settings['public_spaces_limit'], true
      it_behaves_like 'ページ情報', 1
      it_behaves_like 'ページネーション非表示', 1, 2
      it_behaves_like 'リスト表示', 1
      it_behaves_like 'リダイレクト', 2, 1
    end
    shared_examples_for '[ログイン中/削除予約済み]スペースが最大表示数より多い' do
      include_context 'スペース作成', Settings['public_spaces_limit'] + 1, true
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
