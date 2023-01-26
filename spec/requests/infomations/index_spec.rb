require 'rails_helper'

RSpec.describe 'Infomations', type: :request do
  let(:response_json) { JSON.parse(response.body) }
  let(:response_json_infomation)  { response_json['infomation'] }
  let(:response_json_infomations) { response_json['infomations'] }

  # GET /infomations お知らせ一覧
  # GET /infomations(.json) お知らせ一覧API
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）, APIログイン中, APIログイン中（削除予約済み）
  #   お知らせ: ない, 最大表示数と同じ, 最大表示数より多い
  #   ＋URLの拡張子: ない, .json
  #   ＋Acceptヘッダ: HTMLが含まれる, JSONが含まれる
  describe 'GET #index' do
    subject { get infomations_path(page: subject_page, format: subject_format), headers: auth_headers.merge(accept_headers) }

    # テスト内容
    shared_examples_for 'ToOK(html/*)' do
      it 'HTTPステータスが200' do
        is_expected.to eq(200)
      end
    end
    shared_examples_for 'ToOK(json/json)' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it 'HTTPステータスが200。対象項目が一致する' do
        is_expected.to eq(200)
        expect(response_json['success']).to eq(true)
        expect(response_json_infomation['total_count']).to eq(infomations.count)
        expect(response_json_infomation['current_page']).to eq(subject_page)
        expect(response_json_infomation['total_pages']).to eq((infomations.count - 1).div(Settings.default_infomations_limit) + 1)
        expect(response_json_infomation['limit_value']).to eq(Settings.default_infomations_limit)
      end
    end

    shared_examples_for 'ページネーション表示' do |page, link_page|
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      let(:subject_page) { page }
      let(:url_page)     { link_page >= 2 ? link_page : nil }
      it "#{link_page}ページのパスが含まれる" do
        subject
        expect(response.body).to include("\"#{infomations_path(page: url_page)}\"")
      end
    end
    shared_examples_for 'ページネーション非表示' do |page, link_page|
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      let(:subject_page) { page }
      let(:url_page)     { link_page >= 2 ? link_page : nil }
      it "#{link_page}ページのパスが含まれない" do
        subject
        expect(response.body).not_to include("\"#{infomations_path(page: url_page)}\"")
      end
    end

    shared_examples_for 'リスト表示（0件）' do
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      let(:subject_page) { 1 }
      it '存在しないメッセージが含まれる' do
        subject
        expect(response.body).to include('お知らせはありません。')
      end
    end
    shared_examples_for 'リスト表示' do |page|
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      let(:subject_page) { page }
      let(:start_no)     { (Settings.default_infomations_limit * (page - 1)) + 1 }
      let(:end_no)       { [@user_infomations.count, Settings.default_infomations_limit * page].min }
      it '対象項目が含まれる' do
        subject
        (start_no..end_no).each do |no|
          infomation = @user_infomations[@user_infomations.count - no]
          # タイトル
          expect(response.body).to include(infomation.label_i18n) if infomation.label_i18n.present?

          url = "href=\"#{infomation_path(infomation)}\""
          if infomation.body.present?
            expect(response.body).to include(url)
          else
            expect(response.body).not_to include(url)
          end

          expect(response.body).to include(infomation.title)
          expect(response.body).to include(I18n.l(infomation.started_at.to_date))
          # 概要
          expect(response.body).to include(infomation.summary) if infomation.summary.present?
        end
      end
    end
    shared_examples_for 'リスト表示(json)' do |page|
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      let(:subject_page) { page }
      let(:start_no)     { (Settings.default_infomations_limit * (page - 1)) + 1 }
      let(:end_no)       { [infomations.count, Settings.default_infomations_limit * page].min }
      it '件数・対象項目が一致する' do
        subject
        expect(response_json_infomations.count).to eq(end_no - start_no + 1)
        (start_no..end_no).each do |no|
          data = response_json_infomations[no - start_no]
          infomation = infomations[infomations.count - no]
          expect(data['id']).to eq(infomation.id)
          expect_infomation_json(data, infomation, false)
        end
      end
    end

    shared_examples_for 'リダイレクト' do |page, redirect_page|
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      let(:subject_page) { page }
      let(:url_page)     { redirect_page >= 2 ? redirect_page : nil }
      it '最終ページにリダイレクトする' do
        is_expected.to redirect_to(infomations_path(page: url_page))
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
    shared_examples_for '[*]お知らせがない' do
      include_context 'お知らせ一覧作成', 0, 0, 0, 0
      it_behaves_like 'ToOK(html)', 1
      it_behaves_like 'ページネーション非表示', 1, 2
      it_behaves_like 'リスト表示（0件）'
      it_behaves_like 'リダイレクト', 2, 1
      it_behaves_like 'ToOK(json)', 1
      it_behaves_like 'リスト表示(json)', 1
      it_behaves_like 'リダイレクト(json)', 2
    end
    shared_examples_for '[未ログイン]お知らせが最大表示数と同じ' do
      count = Settings.test_infomations_count
      include_context 'お知らせ一覧作成', count.all_forever + count.user_forever, count.all_future + count.user_future, 0, 0
      it_behaves_like 'ToOK(html)', 1
      it_behaves_like 'ページネーション非表示', 1, 2
      it_behaves_like 'リスト表示', 1
      it_behaves_like 'リダイレクト', 2, 1
      it_behaves_like 'ToOK(json)', 1
      it_behaves_like 'リスト表示(json)', 1
      it_behaves_like 'リダイレクト(json)', 2
    end
    shared_examples_for '[ログイン中/削除予約済み]お知らせが最大表示数と同じ' do
      count = Settings.test_infomations_count
      include_context 'お知らせ一覧作成', count.all_forever, count.all_future, count.user_forever, count.user_future
      it_behaves_like 'ToOK(html)', 1
      it_behaves_like 'ページネーション非表示', 1, 2
      it_behaves_like 'リスト表示', 1
      it_behaves_like 'リダイレクト', 2, 1
      it_behaves_like 'ToOK(json)', 1
      it_behaves_like 'リスト表示(json)', 1
      it_behaves_like 'リダイレクト(json)', 2
    end
    shared_examples_for '[APIログイン中/削除予約済み]お知らせが最大表示数と同じ' do
      count = Settings.test_infomations_count
      include_context 'お知らせ一覧作成', count.all_forever, count.all_future, count.user_forever, count.user_future
      it_behaves_like 'ToOK(html)', 1
      it_behaves_like 'ページネーション非表示', 1, 2
      it_behaves_like 'リスト表示', 1
      it_behaves_like 'リダイレクト', 2, 1
      it_behaves_like 'ToOK(json)', 1
      it_behaves_like 'リスト表示(json)', 1
      it_behaves_like 'リダイレクト(json)', 2
    end
    shared_examples_for '[未ログイン]お知らせが最大表示数より多い' do
      count = Settings.test_infomations_count
      include_context 'お知らせ一覧作成', count.all_forever + count.user_forever, count.all_future + count.user_future + 1, 0, 0
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
    shared_examples_for '[ログイン中/削除予約済み]お知らせが最大表示数より多い' do
      count = Settings.test_infomations_count
      include_context 'お知らせ一覧作成', count.all_forever, count.all_future, count.user_forever, count.user_future + 1
      it_behaves_like 'ToOK(html)', 1
      it_behaves_like 'ToOK(html)', 2
      it_behaves_like 'ページネーション表示', 1, 2
      it_behaves_like 'ページネーション表示', 2, 1
      it_behaves_like 'リスト表示', 1
      it_behaves_like 'リスト表示', 2
      it_behaves_like 'リダイレクト', 3, 2
      # it_behaves_like 'ToOK(json)', 1 # NOTE: APIは未ログイン扱いの為
      # it_behaves_like 'ToOK(json)', 2
      # it_behaves_like 'リスト表示(json)', 1
      # it_behaves_like 'リスト表示(json)', 2
      # it_behaves_like 'リダイレクト(json)', 3
    end
    shared_examples_for '[APIログイン中/削除予約済み]お知らせが最大表示数より多い' do
      count = Settings.test_infomations_count
      include_context 'お知らせ一覧作成', count.all_forever, count.all_future, count.user_forever, count.user_future + 1
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
      let(:infomations) { @all_infomations } # NOTE: APIは未ログイン扱いの為、全員のしか見れない
      it_behaves_like '[*]お知らせがない'
      it_behaves_like '[ログイン中/削除予約済み]お知らせが最大表示数と同じ'
      it_behaves_like '[ログイン中/削除予約済み]お知らせが最大表示数より多い'
    end
    shared_examples_for '[APIログイン中/削除予約済み]' do
      let(:infomations) { @user_infomations }
      it_behaves_like '[*]お知らせがない'
      it_behaves_like '[APIログイン中/削除予約済み]お知らせが最大表示数と同じ'
      it_behaves_like '[APIログイン中/削除予約済み]お知らせが最大表示数より多い'
    end

    context '未ログイン' do
      let(:infomations) { @all_infomations }
      include_context '未ログイン処理'
      it_behaves_like '[*]お知らせがない'
      it_behaves_like '[未ログイン]お知らせが最大表示数と同じ'
      it_behaves_like '[未ログイン]お知らせが最大表示数より多い'
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
