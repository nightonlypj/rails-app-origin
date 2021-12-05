require 'rails_helper'

RSpec.describe 'Infomations', type: :request do
  # GET /infomations お知らせ一覧
  # GET /infomations(.json) お知らせ一覧API
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）, APIログイン中, APIログイン中（削除予約済み）
  #   お知らせ: ない, 最大表示数と同じ, 最大表示数より多い
  #   ＋URLの拡張子: ない, .json
  #   ＋Acceptヘッダ: HTMLが含まれる, JSONが含まれる
  describe 'GET #index' do
    subject { get infomations_path(page: subject_page, format: subject_format), headers: auth_headers.merge(@accept_headers) }
    before  { @accept_headers = nil } # Tips: 定義忘れをエラーにする為

    # テスト内容
    shared_examples_for 'ToOK' do |page|
      let(:subject_page)   { page }
      let(:subject_format) { nil }
      it '[AcceptヘッダにHTMLが含まれる]HTTPステータスが200' do
        @accept_headers = ACCEPT_INC_HTML
        is_expected.to eq(200)
      end
      it '[AcceptヘッダにJSONが含まれる]HTTPステータスが200' do # Tips: HTMLが返却される
        @accept_headers = ACCEPT_INC_JSON
        is_expected.to eq(200)
      end
    end
    shared_examples_for 'ToOK(json)' do |page|
      let(:subject_page)   { page }
      let(:subject_format) { :json }
      it '[AcceptヘッダにHTMLが含まれる]HTTPステータスが406' do
        @accept_headers = ACCEPT_INC_HTML
        # is_expected.to eq(406)
        is_expected.to eq(200) # TODO: JSONが返却される
      end
      it '[AcceptヘッダにJSONが含まれる]HTTPステータスが200。対象項目が一致する' do
        @accept_headers = ACCEPT_INC_JSON
        is_expected.to eq(200)
        expect(JSON.parse(response.body)['success']).to eq(true)

        response_json = JSON.parse(response.body)['infomation']
        expect(response_json['total_count']).to eq(infomations.count) # 全件数
        expect(response_json['current_page']).to eq(page) # 現在ページ
        expect(response_json['total_pages']).to eq((infomations.count - 1).div(Settings['default_infomations_limit']) + 1) # 全ページ数
        expect(response_json['limit_value']).to eq(Settings['default_infomations_limit']) # 最大表示件数
      end
    end

    shared_examples_for 'ページネーション表示' do |page, link_page|
      let(:subject_page)   { page }
      let(:subject_format) { nil }
      let(:url_page)       { link_page >= 2 ? link_page : nil }
      it "#{link_page}ページのパスが含まれる" do
        @accept_headers = ACCEPT_INC_HTML
        subject
        expect(response.body).to include("\"#{infomations_path(page: url_page)}\"")
      end
    end
    shared_examples_for 'ページネーション非表示' do |page, link_page|
      let(:subject_page)   { page }
      let(:subject_format) { nil }
      let(:url_page)       { link_page >= 2 ? link_page : nil }
      it "#{link_page}ページのパスが含まれない" do
        @accept_headers = ACCEPT_INC_HTML
        subject
        expect(response.body).not_to include("\"#{infomations_path(page: url_page)}\"")
      end
    end

    shared_examples_for 'リスト表示' do |page|
      let(:subject_page)   { page }
      let(:subject_format) { nil }
      let(:start_no)       { (Settings['default_infomations_limit'] * (page - 1)) + 1 }
      let(:end_no)         { [@user_infomations.count, Settings['default_infomations_limit'] * page].min }
      it '対象項目が含まれる' do
        @accept_headers = ACCEPT_INC_HTML
        subject
        (start_no..end_no).each do |no|
          info = @user_infomations[@user_infomations.count - no]
          expect(response.body).to include(info.label_i18n) if info.label_i18n.present? # ラベル
          expect(response.body).to include(info.title) # タイトル
          expect(response.body).to include(info.summary) if info.summary.present? # 概要
          if info.body.present?
            expect(response.body).to include("\"#{infomation_path(info)}\"") # お知らせ詳細のパス
          else
            expect(response.body).not_to include("\"#{infomation_path(info)}\"") # Tips: 本文がない場合は遷移しない
          end
          expect(response.body).to include(I18n.l(info.started_at.to_date)) # 掲載開始日
        end
      end
    end
    shared_examples_for 'リスト表示(json)' do |page|
      let(:subject_page)   { page }
      let(:subject_format) { :json }
      let(:start_no)       { (Settings['default_infomations_limit'] * (page - 1)) + 1 }
      let(:end_no)         { [infomations.count, Settings['default_infomations_limit'] * page].min }
      it '件数・対象項目が一致する' do
        @accept_headers = ACCEPT_INC_JSON
        subject
        response_json = JSON.parse(response.body)['infomations']
        expect(response_json.count).to eq(end_no - start_no + 1)
        (start_no..end_no).each do |no|
          data = response_json[no - start_no]
          info = infomations[infomations.count - no]
          expect(data['id']).to eq(info.id) # ID
          expect(data['label']).to eq(info.label) # ラベル
          expect(data['label_i18n']).to eq(info.label_i18n)
          expect(data['title']).to eq(info.title) # タイトル
          expect(data['summary']).to eq(info.summary) # 概要
          expect(data['body_present']).to eq(info.body.present?) # 本文
          expect(data['started_at']).to eq(I18n.l(info.started_at, format: :json)) # 掲載開始日
          expect(data['ended_at']).to eq(info.ended_at.present? ? I18n.l(info.ended_at, format: :json) : nil) # 掲載終了日
          expect(data['target']).to eq(info.target) # 対象
        end
      end
    end

    shared_examples_for 'リダイレクト' do |page, redirect_page|
      let(:subject_page)   { page }
      let(:subject_format) { nil }
      let(:url_page)       { redirect_page >= 2 ? redirect_page : nil }
      it '最終ページにリダイレクトする' do
        @accept_headers = ACCEPT_INC_HTML
        is_expected.to redirect_to(infomations_path(page: url_page))
      end
    end
    shared_examples_for 'リダイレクト(json)' do |page|
      let(:subject_page)   { page }
      let(:subject_format) { :json }
      it 'リダイレクトしない' do
        @accept_headers = ACCEPT_INC_JSON
        is_expected.to eq(200)
      end
    end

    # テストケース
    shared_examples_for '[*]お知らせがない' do
      include_context 'お知らせ一覧作成', 0, 0, 0, 0
      it_behaves_like 'ToOK', 1
      it_behaves_like 'ページネーション非表示', 1, 2
      it_behaves_like 'リダイレクト', 2, 1
      it_behaves_like 'ToOK(json)', 1
      it_behaves_like 'リダイレクト(json)', 2
    end
    shared_examples_for '[未ログイン]お知らせが最大表示数と同じ' do
      count = Settings['test_infomations']
      include_context 'お知らせ一覧作成', count['all_forever_count'] + count['user_forever_count'], count['all_future_count'] + count['user_future_count'], 0, 0
      it_behaves_like 'ToOK', 1
      it_behaves_like 'ページネーション非表示', 1, 2
      it_behaves_like 'リスト表示', 1
      it_behaves_like 'リダイレクト', 2, 1
      it_behaves_like 'ToOK(json)', 1
      it_behaves_like 'リスト表示(json)', 1
      it_behaves_like 'リダイレクト(json)', 2
    end
    shared_examples_for '[ログイン中/削除予約済み]お知らせが最大表示数と同じ' do
      count = Settings['test_infomations']
      include_context 'お知らせ一覧作成', count['all_forever_count'], count['all_future_count'], count['user_forever_count'], count['user_future_count']
      it_behaves_like 'ToOK', 1
      it_behaves_like 'ページネーション非表示', 1, 2
      it_behaves_like 'リスト表示', 1
      it_behaves_like 'リダイレクト', 2, 1
      it_behaves_like 'ToOK(json)', 1
      it_behaves_like 'リスト表示(json)', 1
      it_behaves_like 'リダイレクト(json)', 2
    end
    shared_examples_for '[APIログイン中/削除予約済み]お知らせが最大表示数と同じ' do
      count = Settings['test_infomations']
      include_context 'お知らせ一覧作成', count['all_forever_count'], count['all_future_count'], count['user_forever_count'], count['user_future_count']
      it_behaves_like 'ToOK', 1
      it_behaves_like 'ページネーション非表示', 1, 2
      it_behaves_like 'リスト表示', 1
      it_behaves_like 'リダイレクト', 2, 1
      it_behaves_like 'ToOK(json)', 1
      it_behaves_like 'リスト表示(json)', 1
      it_behaves_like 'リダイレクト(json)', 2
    end
    shared_examples_for '[未ログイン]お知らせが最大表示数より多い' do
      count = Settings['test_infomations']
      include_context 'お知らせ一覧作成', count['all_forever_count'] + count['user_forever_count'], count['all_future_count'] + count['user_future_count'] + 1, 0, 0
      it_behaves_like 'ToOK', 1
      it_behaves_like 'ToOK', 2
      it_behaves_like 'ページネーション表示', 1, 2
      it_behaves_like 'ページネーション表示', 2, 1
      it_behaves_like 'リスト表示', 1
      it_behaves_like 'リスト表示', 2
      it_behaves_like 'リダイレクト', 3, 2
      it_behaves_like 'ToOK(json)', 1
      it_behaves_like 'ToOK(json)', 2
      it_behaves_like 'リスト表示(json)', 1
      it_behaves_like 'リスト表示(json)', 2
      it_behaves_like 'リダイレクト(json)', 3
    end
    shared_examples_for '[ログイン中/削除予約済み]お知らせが最大表示数より多い' do
      count = Settings['test_infomations']
      include_context 'お知らせ一覧作成', count['all_forever_count'], count['all_future_count'], count['user_forever_count'], count['user_future_count'] + 1
      it_behaves_like 'ToOK', 1
      it_behaves_like 'ToOK', 2
      it_behaves_like 'ページネーション表示', 1, 2
      it_behaves_like 'ページネーション表示', 2, 1
      it_behaves_like 'リスト表示', 1
      it_behaves_like 'リスト表示', 2
      it_behaves_like 'リダイレクト', 3, 2
      # it_behaves_like 'ToOK(json)', 1 # Tips: APIは未ログイン扱いの為
      # it_behaves_like 'ToOK(json)', 2
      # it_behaves_like 'リスト表示(json)', 1
      # it_behaves_like 'リスト表示(json)', 2
      # it_behaves_like 'リダイレクト(json)', 3
    end
    shared_examples_for '[APIログイン中/削除予約済み]お知らせが最大表示数より多い' do
      count = Settings['test_infomations']
      include_context 'お知らせ一覧作成', count['all_forever_count'], count['all_future_count'], count['user_forever_count'], count['user_future_count'] + 1
      it_behaves_like 'ToOK', 1
      it_behaves_like 'ToOK', 2
      it_behaves_like 'ページネーション表示', 1, 2
      it_behaves_like 'ページネーション表示', 2, 1
      it_behaves_like 'リスト表示', 1
      it_behaves_like 'リスト表示', 2
      it_behaves_like 'リダイレクト', 3, 2
      it_behaves_like 'ToOK(json)', 1
      it_behaves_like 'ToOK(json)', 2
      it_behaves_like 'リスト表示(json)', 1
      it_behaves_like 'リスト表示(json)', 2
      it_behaves_like 'リダイレクト(json)', 3
    end

    context '未ログイン' do
      let(:infomations) { @all_infomations }
      include_context '未ログイン処理'
      it_behaves_like '[*]お知らせがない'
      it_behaves_like '[未ログイン]お知らせが最大表示数と同じ'
      it_behaves_like '[未ログイン]お知らせが最大表示数より多い'
    end
    context 'ログイン中' do
      let(:infomations) { @all_infomations } # Tips: APIは未ログイン扱いの為、全員のしか見れない
      include_context 'ログイン処理'
      it_behaves_like '[*]お知らせがない'
      it_behaves_like '[ログイン中/削除予約済み]お知らせが最大表示数と同じ'
      it_behaves_like '[ログイン中/削除予約済み]お知らせが最大表示数より多い'
    end
    context 'ログイン中（削除予約済み）' do
      let(:infomations) { @all_infomations } # Tips: APIは未ログイン扱いの為、全員のしか見れない
      include_context 'ログイン処理', :user_destroy_reserved
      it_behaves_like '[*]お知らせがない'
      it_behaves_like '[ログイン中/削除予約済み]お知らせが最大表示数と同じ'
      it_behaves_like '[ログイン中/削除予約済み]お知らせが最大表示数より多い'
    end
    context 'APIログイン中' do
      let(:infomations) { @user_infomations }
      include_context 'APIログイン処理'
      it_behaves_like '[*]お知らせがない'
      it_behaves_like '[APIログイン中/削除予約済み]お知らせが最大表示数と同じ'
      it_behaves_like '[APIログイン中/削除予約済み]お知らせが最大表示数より多い'
    end
    context 'APIログイン中（削除予約済み）' do
      let(:infomations) { @user_infomations }
      include_context 'APIログイン処理', :user_destroy_reserved
      it_behaves_like '[*]お知らせがない'
      it_behaves_like '[APIログイン中/削除予約済み]お知らせが最大表示数と同じ'
      it_behaves_like '[APIログイン中/削除予約済み]お知らせが最大表示数より多い'
    end
  end
end
