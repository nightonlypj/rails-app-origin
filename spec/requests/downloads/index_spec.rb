require 'rails_helper'

RSpec.describe 'Downloads', type: :request do
  let(:response_json) { JSON.parse(response.body) }
  let(:response_json_download)  { response_json['download'] }
  let(:response_json_downloads) { response_json['downloads'] }
  let(:response_json_target)    { response_json['target'] }
  let(:default_params) { { id: nil, target_id: nil } }

  # GET /downloads ダウンロード結果一覧
  # GET /downloads(.json) ダウンロード結果一覧API
  # 前提条件
  #   検索条件なし, 対象IDなし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）, APIログイン中, APIログイン中（削除予約済み）
  #   ダウンロード結果: 存在しない, 最大表示数と同じ, 最大表示数より多い
  #     ステータス: 処理待ち, 処理中, 成功, 失敗
  #     モデル: メンバー
  #     対象: 選択項目, 検索, 全て
  #     形式: CSV, TSV
  #     文字コード: Shift_JIS, EUC-JP, UTF-8
  #     改行コード: CR+LF, LF, CR
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
        expect(response_json['success']).to be(true)
        expect(response_json['search_params']).to eq(default_params.stringify_keys)

        expect(response_json_download['total_count']).to eq(downloads.count)
        expect(response_json_download['current_page']).to eq(subject_page)
        expect(response_json_download['total_pages']).to eq((downloads.count - 1).div(Settings.default_downloads_limit) + 1)
        expect(response_json_download['limit_value']).to eq(Settings.default_downloads_limit)
        expect(response_json_download.count).to eq(4)

        expect(response_json['undownloaded_count']).to eq(user.undownloaded_count)
        expect(response_json.count).to eq(5)
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
      let(:url_page)     { link_page }
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
        expect(response.body).to include(I18n.t('対象が見つかりません。'))
      end
    end
    shared_examples_for 'リスト表示' do |page|
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      let(:subject_page) { page }
      let(:start_no)     { (Settings.default_downloads_limit * (page - 1)) + 1 }
      let(:end_no)       { [downloads.count, Settings.default_downloads_limit * page].min }
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
          url = "href=\"#{file_download_path(id: download.id)}\""
          if download.status.to_sym == :success
            expect(response.body).to include(url)
            expect(response.body).to include(I18n.t('（済み）')) if download.last_downloaded_at.present?
          else
            expect(response.body).not_to include(url)
          end
          # 対象・形式等
          if download.model.to_sym == :member
            expect(response.body).to include("#{I18n.t('メンバー')}: #{download.space.name}")
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
      let(:start_no)     { (Settings.default_downloads_limit * (page - 1)) + 1 }
      let(:end_no)       { [downloads.count, Settings.default_downloads_limit * page].min }
      it '件数・対象項目が一致する' do
        subject
        expect(response_json_downloads.count).to eq(end_no - start_no + 1)
        (start_no..end_no).each do |no|
          data = response_json_downloads[no - start_no]
          count = expect_download_json(data, downloads[downloads.count - no])
          expect(data.count).to eq(count)
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
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToOK(html)', 1
        it_behaves_like 'ページネーション非表示', 1, 2
        it_behaves_like 'リスト表示（0件）'
        it_behaves_like 'リダイレクト', 2, 1
      end
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中/削除予約済み]ダウンロード結果が存在しない' do
      include_context 'ダウンロード結果一覧作成', 0, 0, 0, 0, 0
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToOK(html)', 1 # NOTE: HTMLもログイン状態になる
        it_behaves_like 'ページネーション非表示', 1, 2
        it_behaves_like 'リスト表示（0件）'
        it_behaves_like 'リダイレクト', 2, 1
      end
      it_behaves_like 'ToOK(json)', 1
      it_behaves_like 'リダイレクト(json)', 2
    end
    shared_examples_for '[ログイン中/削除予約済み]ダウンロード結果が最大表示数と同じ' do
      count = Settings.test_downloads_count
      include_context 'ダウンロード結果一覧作成', count.waiting, count.processing, count.success, count.failure, count.downloaded
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToOK(html)', 1
        it_behaves_like 'ページネーション非表示', 1, 2
        it_behaves_like 'リスト表示', 1
        it_behaves_like 'リダイレクト', 2, 1
      end
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中/削除予約済み]ダウンロード結果が最大表示数と同じ' do
      count = Settings.test_downloads_count
      include_context 'ダウンロード結果一覧作成', count.waiting, count.processing, count.success, count.failure, count.downloaded
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToOK(html)', 1
        it_behaves_like 'ページネーション非表示', 1, 2
        it_behaves_like 'リスト表示', 1
        it_behaves_like 'リダイレクト', 2, 1
      end
      it_behaves_like 'ToOK(json)', 1
      it_behaves_like 'リスト表示(json)', 1
      it_behaves_like 'リダイレクト(json)', 2
    end
    shared_examples_for '[ログイン中/削除予約済み]ダウンロード結果が最大表示数より多い' do
      count = Settings.test_downloads_count
      include_context 'ダウンロード結果一覧作成', count.waiting, count.processing, count.success, count.failure, count.downloaded + 1
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToOK(html)', 1
        it_behaves_like 'ToOK(html)', 2
        it_behaves_like 'ページネーション表示', 1, 2
        it_behaves_like 'ページネーション表示', 2, 1
        it_behaves_like 'リスト表示', 1
        it_behaves_like 'リスト表示', 2
        it_behaves_like 'リダイレクト', 3, 2
      end
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中/削除予約済み]ダウンロード結果が最大表示数より多い' do
      count = Settings.test_downloads_count
      include_context 'ダウンロード結果一覧作成', count.waiting, count.processing, count.success, count.failure, count.downloaded + 1
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToOK(html)', 1
        it_behaves_like 'ToOK(html)', 2
        it_behaves_like 'ページネーション表示', 1, 2
        it_behaves_like 'ページネーション表示', 2, 1
        it_behaves_like 'リスト表示', 1
        it_behaves_like 'リスト表示', 2
        it_behaves_like 'リダイレクト', 3, 2
      end
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
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToLogin(html)'
      end
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

  # 前提条件
  #   ログイン中（URLの拡張子がない/AcceptヘッダにHTMLが含まれる）, APIログイン中（URLの拡張子が.json/AcceptヘッダにJSONが含まれる）
  #   IDあり, 対象IDなし, 依頼日時のみ確認
  # テストパターン
  #   ID: 存在する, 存在しない
  describe 'GET #index (.search)' do
    subject { get downloads_path(format: subject_format), params:, headers: auth_headers.merge(accept_headers) }

    # テスト内容
    shared_examples_for 'ToOK[依頼日時]' do
      it 'HTTPステータスが200。対象の依頼日時が一致する/含まれる' do
        is_expected.to eq(200)
        if subject_format == :json
          # JSON
          expect(response_json_downloads.count).to eq(downloads.count)
          downloads.each_with_index do |download, index|
            expect(response_json_downloads[downloads.count - index - 1]['requested_at']).to eq(I18n.l(download.requested_at, format: :json))
          end

          expect(response_json['search_params']).to eq(default_params.merge(params).stringify_keys)
        else
          # HTML
          downloads.each do |download|
            expect(response.body).to include(I18n.l(download.requested_at))
          end
        end
      end
    end
    shared_examples_for 'ToNG[0件]' do
      it '0件/存在しないメッセージが含まれる' do
        is_expected.to eq(200)
        if subject_format == :json
          # JSON
          expect(response_json_downloads.count).to eq(0)
        else
          # HTML
          expect(response.body).to include(I18n.t('対象が見つかりません。'))
        end
      end
    end

    # テストケース
    shared_examples_for 'IDが存在する' do
      let_it_be(:space) { FactoryBot.create(:space, created_user: user) }
      let_it_be(:download) { FactoryBot.create(:download, space:, user:) }
      let(:params) { { id: download.id, target_id: nil } }
      let(:downloads) { [download] }
      it_behaves_like 'ToOK[依頼日時]'
    end
    shared_examples_for 'IDが存在しない' do
      let_it_be(:download) { FactoryBot.build_stubbed(:download) }
      let(:params) { { id: download.id, target_id: nil } }
      it_behaves_like 'ToNG[0件]'
    end

    shared_examples_for 'ID' do
      it_behaves_like 'IDが存在する'
      it_behaves_like 'IDが存在しない'
    end

    context 'ログイン中（URLの拡張子がない/AcceptヘッダにHTMLが含まれる）' do
      next if Settings.api_only_mode

      include_context 'ログイン処理'
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      it_behaves_like 'ID'
    end
    context 'APIログイン中（URLの拡張子が.json/AcceptヘッダにJSONが含まれる）' do
      include_context 'APIログイン処理'
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it_behaves_like 'ID'
    end
  end

  # 前提条件
  #   ログイン中（URLの拡張子がない/AcceptヘッダにHTMLが含まれる）, APIログイン中（URLの拡張子が.json/AcceptヘッダにJSONが含まれる）
  #   対象IDあり, 依頼日時/対象のみ確認
  # テストパターン
  #   対象ID: 一覧に存在する, 一覧に存在しない, 存在しない
  #   ステータス: 処理待ち, 処理中, 成功, 失敗, ダウンロード済み
  describe 'GET #index (:target_id)' do
    subject { get downloads_path(format: subject_format), params: { target_id: download.id }, headers: auth_headers.merge(accept_headers) }
    let_it_be(:space) { FactoryBot.create(:space) }

    # テスト内容
    shared_examples_for 'OK' do |status, alert, notice|
      it 'HTTPステータスが200。対象が一致する/メッセージが含まれる' do
        is_expected.to eq(200)
        if subject_format == :json
          # JSON
          expect(response_json['search_params']).to eq(default_params.merge(target_id: download.id).stringify_keys)

          if status.present?
            expect(response_json_target['status']).to eq(status.to_s)
            expect(response_json_target['alert']).to alert.present? ? eq(get_locale(alert)) : be_nil
            expect(response_json_target['notice']).to notice.present? ? eq(get_locale(notice)) : be_nil
          else
            expect(response_json_target).to be_nil
          end
        else
          # HTML
          expect(flash[:alert]).to alert.present? ? eq(get_locale(alert)) : be_nil
          expect(flash[:notice]).to notice.present? ? eq(get_locale(notice)) : be_nil
          expect(response.body).to include(get_locale(alert)) if alert.present?
          expect(response.body).to include(get_locale(notice)) if notice.present?
        end
      end
    end

    # テストケース
    shared_examples_for '一覧に存在する(notice)' do |status|
      before_all { FactoryBot.create_list(:download, Settings.default_downloads_limit, user:, space:) }
      let_it_be(:download) { FactoryBot.create(:download, status, user:, space:) }
      it_behaves_like 'OK', status, nil, "notice.download.status.#{status}"
    end
    shared_examples_for '一覧に存在しない(notice)' do |status|
      let_it_be(:download) { FactoryBot.create(:download, status, user:, space:) }
      before_all { FactoryBot.create_list(:download, Settings.default_downloads_limit, user:, space:) }
      it_behaves_like 'OK', status, nil, "notice.download.status.#{status}"
    end
    shared_examples_for '一覧に存在する(alert)' do |status|
      before_all { FactoryBot.create_list(:download, Settings.default_downloads_limit, user:, space:) }
      let_it_be(:download) { FactoryBot.create(:download, status, user:, space:) }
      it_behaves_like 'OK', status, "alert.download.status.#{status}", nil
    end
    shared_examples_for '一覧に存在しない(alert)' do |status|
      let_it_be(:download) { FactoryBot.create(:download, status, user:, space:) }
      before_all { FactoryBot.create_list(:download, Settings.default_downloads_limit, user:, space:) }
      it_behaves_like 'OK', status, "alert.download.status.#{status}", nil
    end
    shared_examples_for '一覧に存在する(nil)' do |status|
      before_all { FactoryBot.create_list(:download, Settings.default_downloads_limit, user:, space:) }
      let_it_be(:download) { FactoryBot.create(:download, status, user:, space:) }
      it_behaves_like 'OK', :success, nil, nil
    end
    shared_examples_for '一覧に存在しない(nil)' do |status|
      let_it_be(:download) { FactoryBot.create(:download, status, user:, space:) }
      before_all { FactoryBot.create_list(:download, Settings.default_downloads_limit, user:, space:) }
      it_behaves_like 'OK', :success, nil, nil
    end
    shared_examples_for '存在しない' do
      let_it_be(:download) { FactoryBot.build_stubbed(:download) }
      it_behaves_like 'OK', nil, nil, nil
    end

    shared_examples_for '対象ID' do
      it_behaves_like '一覧に存在する(notice)', :waiting
      it_behaves_like '一覧に存在する(notice)', :processing
      it_behaves_like '一覧に存在する(notice)', :success
      it_behaves_like '一覧に存在する(alert)', :failure
      it_behaves_like '一覧に存在する(nil)', :downloaded
      it_behaves_like '一覧に存在しない(notice)', :waiting
      it_behaves_like '一覧に存在しない(notice)', :processing
      it_behaves_like '一覧に存在しない(notice)', :success
      it_behaves_like '一覧に存在しない(alert)', :failure
      it_behaves_like '一覧に存在しない(nil)', :downloaded
      it_behaves_like '存在しない'
    end

    context 'ログイン中（URLの拡張子がない/AcceptヘッダにHTMLが含まれる）' do
      next if Settings.api_only_mode

      include_context 'ログイン処理'
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      it_behaves_like '対象ID'
    end
    context 'APIログイン中（URLの拡張子が.json/AcceptヘッダにJSONが含まれる）' do
      include_context 'APIログイン処理'
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it_behaves_like '対象ID'
    end
  end
end
