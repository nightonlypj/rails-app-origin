require 'rails_helper'

RSpec.describe 'Downloads', type: :request do
  let(:response_json) { JSON.parse(response.body) }
  let(:response_json_download)  { response_json['download'] }
  let(:response_json_downloads) { response_json['downloads'] }

  # GET /downloads ダウンロード結果一覧
  # GET /downloads(.json) ダウンロード結果一覧API
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）, APIログイン中, APIログイン中（削除予約済み）
  #   ダウンロード結果: 存在しない, 最大表示数と同じ, 最大表示数より多い
  #   ＋URLの拡張子: ない, .json
  #   ＋Acceptヘッダ: HTMLが含まれる, JSONが含まれる
  describe 'GET #index' do
    subject { get downloads_path(page: subject_page, format: subject_format), headers: auth_headers.merge(accept_headers) }

    # テスト内容
    shared_examples_for 'ToOK(html/*)' do
      it 'HTTPステータスが200' do
        is_expected.to eq(200)
      end
    end
    shared_examples_for 'ToOK(json/json)' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      before { user.cache_undownloaded_count = nil } # NOTE: キャッシュクリア
      it 'HTTPステータスが200。対象項目が一致する' do
        is_expected.to eq(200)
        expect(response_json['success']).to eq(true)
        expect(response_json_download['total_count']).to eq(downloads.count)
        expect(response_json_download['current_page']).to eq(subject_page)
        expect(response_json_download['total_pages']).to eq((downloads.count - 1).div(Settings['default_downloads_limit']) + 1)
        expect(response_json_download['limit_value']).to eq(Settings['default_downloads_limit'])

        expect(response_json['undownloaded_count']).to eq(user.undownloaded_count)
      end
    end

    shared_examples_for 'ページネーション表示' do |page, link_page|
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      let(:subject_page) { page }
      let(:url_page)     { link_page >= 2 ? link_page : nil }
      it "#{link_page}ページのパスが含まれる" do
        subject
        expect(response.body).to include("\"#{downloads_path(page: url_page)}\"")
      end
    end
    shared_examples_for 'ページネーション非表示' do |page, link_page|
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      let(:subject_page) { page }
      let(:url_page)     { link_page >= 2 ? link_page : nil }
      it "#{link_page}ページのパスが含まれない" do
        subject
        expect(response.body).not_to include("\"#{downloads_path(page: url_page)}\"")
      end
    end

    shared_examples_for 'リスト表示（0件）' do
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      let(:subject_page) { 1 }
      it '存在しないメッセージが含まれる' do
        subject
        expect(response.body).to include('対象が見つかりません。')
      end
    end
    shared_examples_for 'リスト表示' do |page|
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      let(:subject_page) { page }
      let(:start_no)     { (Settings['default_downloads_limit'] * (page - 1)) + 1 }
      let(:end_no)       { [downloads.count, Settings['default_downloads_limit'] * page].min }
      it '対象項目が含まれる' do
        subject
        (start_no..end_no).each do |no|
          download = downloads[downloads.count - no]
          # 依頼日時
          expect(response.body).to include(I18n.l(download.requested_at))
          # 完了日時
          expect(response.body).to include(I18n.l(download.completed_at)) if download.completed_at.present?
          # ステータス
          expect(response.body).to include(download.status_i18n)
          # ファイル
          url = "href=\"#{file_download_path(download.id)}\""
          if download.status.to_sym == :success
            expect(response.body).to include(url)
            expect(response.body).to include('（済み）') if download.last_downloaded_at.present?
          else
            expect(response.body).not_to include(url)
          end
          # 対象・形式等
          if download.model.to_sym == :member
            expect(response.body).to include("メンバー: #{download.space.name}")
          else
            expect(response.body).to include(download.model_i18n)
          end
          expect(response.body).to include(download.target_i18n)
          expect(response.body).to include(download.char_code_i18n)
          expect(response.body).to include(download.newline_code_i18n)
        end
      end
    end
    shared_examples_for 'リスト表示(json)' do |page|
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      let(:subject_page) { page }
      let(:start_no)     { (Settings['default_downloads_limit'] * (page - 1)) + 1 }
      let(:end_no)       { [downloads.count, Settings['default_downloads_limit'] * page].min }
      it '件数・対象項目が一致する' do
        subject
        expect(response_json_downloads.count).to eq(end_no - start_no + 1)
        (start_no..end_no).each do |no|
          expect_download_json(response_json_downloads[no - start_no], downloads[downloads.count - no])
        end
      end
    end

    shared_examples_for 'リダイレクト' do |page, redirect_page|
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      let(:subject_page) { page }
      let(:url_page)     { redirect_page >= 2 ? redirect_page : nil }
      it '最終ページにリダイレクトする' do
        is_expected.to redirect_to(downloads_path(page: url_page))
      end
    end
    shared_examples_for 'リダイレクト(json)' do |page|
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      let(:subject_page) { page }
      it 'リダイレクトしない' do
        is_expected.to eq(200)
      end
    end

    # テストケース
    shared_examples_for '[ログイン中/削除予約済み]ダウンロード結果が存在しない' do
      include_context 'ダウンロード結果一覧作成', 0, 0, 0, 0, 0
      it_behaves_like 'ToOK(html)', 1
      it_behaves_like 'ページネーション非表示', 1, 2
      it_behaves_like 'リスト表示（0件）'
      it_behaves_like 'リダイレクト', 2, 1
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中/削除予約済み]ダウンロード結果が存在しない' do
      include_context 'ダウンロード結果一覧作成', 0, 0, 0, 0, 0
      it_behaves_like 'ToOK(html)', 1 # NOTE: HTMLもログイン状態になる
      it_behaves_like 'ページネーション非表示', 1, 2
      it_behaves_like 'リスト表示（0件）'
      it_behaves_like 'リダイレクト', 2, 1
      it_behaves_like 'ToOK(json)', 1
      it_behaves_like 'リダイレクト(json)', 2
    end
    shared_examples_for '[ログイン中/削除予約済み]ダウンロード結果が最大表示数と同じ' do
      count = Settings['test_downloads']
      include_context 'ダウンロード結果一覧作成', count['waiting_count'], count['processing_count'], count['success_count'], count['failure_count'], count['downloaded_count']
      it_behaves_like 'ToOK(html)', 1
      it_behaves_like 'ページネーション非表示', 1, 2
      it_behaves_like 'リスト表示', 1
      it_behaves_like 'リダイレクト', 2, 1
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中/削除予約済み]ダウンロード結果が最大表示数と同じ' do
      count = Settings['test_downloads']
      include_context 'ダウンロード結果一覧作成', count['waiting_count'], count['processing_count'], count['success_count'], count['failure_count'], count['downloaded_count']
      it_behaves_like 'ToOK(html)', 1
      it_behaves_like 'ページネーション非表示', 1, 2
      it_behaves_like 'リスト表示', 1
      it_behaves_like 'リダイレクト', 2, 1
      it_behaves_like 'ToOK(json)', 1
      it_behaves_like 'リスト表示(json)', 1
      it_behaves_like 'リダイレクト(json)', 2
    end
    shared_examples_for '[ログイン中/削除予約済み]ダウンロード結果が最大表示数より多い' do
      count = Settings['test_downloads']
      include_context 'ダウンロード結果一覧作成', count['waiting_count'], count['processing_count'], count['success_count'], count['failure_count'], count['downloaded_count'] + 1
      it_behaves_like 'ToOK(html)', 1
      it_behaves_like 'ToOK(html)', 2
      it_behaves_like 'ページネーション表示', 1, 2
      it_behaves_like 'ページネーション表示', 2, 1
      it_behaves_like 'リスト表示', 1
      it_behaves_like 'リスト表示', 2
      it_behaves_like 'リダイレクト', 3, 2
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中/削除予約済み]ダウンロード結果が最大表示数より多い' do
      count = Settings['test_downloads']
      include_context 'ダウンロード結果一覧作成', count['waiting_count'], count['processing_count'], count['success_count'], count['failure_count'], count['downloaded_count'] + 1
      it_behaves_like 'ToOK(html)', 1
      it_behaves_like 'ToOK(html)', 2
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

    shared_examples_for '[ログイン中/削除予約済み]' do
      it_behaves_like '[ログイン中/削除予約済み]ダウンロード結果が存在しない'
      it_behaves_like '[ログイン中/削除予約済み]ダウンロード結果が最大表示数と同じ'
      it_behaves_like '[ログイン中/削除予約済み]ダウンロード結果が最大表示数より多い'
    end
    shared_examples_for '[APIログイン中/削除予約済み]' do
      it_behaves_like '[APIログイン中/削除予約済み]ダウンロード結果が存在しない'
      it_behaves_like '[APIログイン中/削除予約済み]ダウンロード結果が最大表示数と同じ'
      it_behaves_like '[APIログイン中/削除予約済み]ダウンロード結果が最大表示数より多い'
    end

    context '未ログイン' do
      include_context '未ログイン処理'
      it_behaves_like 'ToLogin(html)'
      it_behaves_like 'ToNG(json)', 401
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中/削除予約済み]'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', :destroy_reserved
      it_behaves_like '[ログイン中/削除予約済み]'
    end
    context 'APIログイン中' do
      include_context 'APIログイン処理'
      it_behaves_like '[APIログイン中/削除予約済み]'
    end
    context 'APIログイン中（削除予約済み）' do
      include_context 'APIログイン処理', :destroy_reserved
      it_behaves_like '[APIログイン中/削除予約済み]'
    end
  end
end
