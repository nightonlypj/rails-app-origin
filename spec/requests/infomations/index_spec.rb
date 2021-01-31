require 'rails_helper'

RSpec.describe 'Infomations', type: :request do
  # GET /infomations お知らせ一覧
  # GET /infomations.json お知らせ一覧API
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  describe 'GET /index' do
    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get infomations_path
        expect(response).to be_successful
      end
      it '(json)成功ステータス' do
        get infomations_path(format: :json)
        expect(response).to be_successful
      end
    end

    # テストケース
    context '未ログイン' do
      it_behaves_like 'ToOK'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'ToOK'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like 'ToOK'
    end
  end

  # お知らせ一覧
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   お知らせ: ない, 最大表示数と同じ, 最大表示数より多い → データ作成
  describe '@infomations' do
    # テスト内容
    shared_examples_for 'ページ情報' do |page|
      it '(json)全件数が一致する' do
        get infomations_path(page: page, format: :json)
        expect(JSON.parse(response.body)['infomation']['total_count']).to eq(@infomations.count)
      end
      it '(json)現在ページが一致する' do
        get infomations_path(page: page, format: :json)
        expect(JSON.parse(response.body)['infomation']['current_page']).to eq(page)
      end
      it '(json)全ページ数が一致する' do
        get infomations_path(page: page, format: :json)
        total_pages = (@infomations.count - 1).div(Settings['default_infomations_limit']) + 1
        expect(JSON.parse(response.body)['infomation']['total_pages']).to eq(total_pages)
      end
      it '(json)最大表示件数が一致する' do
        get infomations_path(page: page, format: :json)
        expect(JSON.parse(response.body)['infomation']['limit_value']).to eq(Settings['default_infomations_limit'])
      end
    end

    shared_examples_for 'ページネーション表示' do |page, link_page|
      it 'パスが含まれる' do
        get infomations_path(page: page)
        if link_page == 1
          expect(response.body).to include("\"#{infomations_path}\"")
        else
          expect(response.body).to include("\"#{infomations_path(page: link_page)}\"")
        end
      end
    end
    shared_examples_for 'ページネーション非表示' do |page, link_page|
      it 'パスが含まれない' do
        get infomations_path(page: page)
        if link_page == 1
          expect(response.body).not_to include("\"#{infomations_path}\"")
        else
          expect(response.body).not_to include("\"#{infomations_path(page: link_page)}\"")
        end
      end
    end

    shared_examples_for 'リスト表示' do |page|
      let!(:start_no) { Settings['default_infomations_limit'] * (page - 1) + 1 }
      let!(:end_no) { [@infomations.count, Settings['default_infomations_limit'] * page].min }
      it '(json)配列の件数が一致する' do
        get infomations_path(page: page, format: :json)
        expect(JSON.parse(response.body)['infomations'].count).to eq(end_no - start_no + 1)
      end
      it '(json)お知らせIDが一致する' do
        get infomations_path(page: page, format: :json)
        parse_response = JSON.parse(response.body)['infomations']
        (start_no..end_no).each do |no|
          expect(parse_response[no - start_no]['id']).to eq(@infomations[@infomations.count - no].id)
        end
      end
      it 'タイトルが含まれる' do
        get infomations_path(page: page)
        (start_no..end_no).each do |no|
          expect(response.body).to include(@infomations[@infomations.count - no].title)
        end
      end
      it '(json)タイトルが一致する' do
        get infomations_path(page: page, format: :json)
        parse_response = JSON.parse(response.body)['infomations']
        (start_no..end_no).each do |no|
          expect(parse_response[no - start_no]['title']).to eq(@infomations[@infomations.count - no].title)
        end
      end
      it '概要が含まれる（ありの場合）' do
        get infomations_path(page: page)
        (start_no..end_no).each do |no|
          expect(response.body).to include(@infomations[@infomations.count - no].summary) if @infomations[@infomations.count - no].summary.present?
        end
      end
      it '(json)概要が一致する' do
        get infomations_path(page: page, format: :json)
        parse_response = JSON.parse(response.body)['infomations']
        (start_no..end_no).each do |no|
          summary = @infomations[@infomations.count - no].summary.present? ? @infomations[@infomations.count - no].summary : ''
          expect(parse_response[no - start_no]['summary']).to eq(summary)
        end
      end
      it 'お知らせ詳細のパスが含まれる（本文ありの場合）' do
        get infomations_path(page: page)
        (start_no..end_no).each do |no|
          if @infomations[@infomations.count - no].body.present?
            expect(response.body).to include("\"#{infomation_path(@infomations[@infomations.count - no])}\"")
          end
        end
      end
      it 'お知らせ詳細のパスが含まれない（本文なしの場合）' do
        get infomations_path(page: page)
        (start_no..end_no).each do |no|
          unless @infomations[@infomations.count - no].body.present?
            expect(response.body).not_to include("\"#{infomation_path(@infomations[@infomations.count - no])}\"")
          end
        end
      end
      it '掲載開始日が含まれる' do # Tips: ユニークではない為、正確ではない
        get infomations_path(page: page)
        (start_no..end_no).each do |no|
          expect(response.body).to include(I18n.l(@infomations[@infomations.count - no].started_at.to_date))
        end
      end
      it '(json)開始日時が一致する' do # Tips: ユニークではない為、正確ではない
        get infomations_path(page: page, format: :json)
        parse_response = JSON.parse(response.body)['infomations']
        (start_no..end_no).each do |no|
          expect(parse_response[no - start_no]['started_at']).to eq(I18n.l(@infomations[@infomations.count - no].started_at, format: :json))
        end
      end
      it '(json)終了日時が一致する' do # Tips: ユニークではない為、正確ではない
        get infomations_path(page: page, format: :json)
        parse_response = JSON.parse(response.body)['infomations']
        (start_no..end_no).each do |no|
          ended_at = @infomations[@infomations.count - no].ended_at.present? ? I18n.l(@infomations[@infomations.count - no].ended_at, format: :json) : ''
          expect(parse_response[no - start_no]['ended_at']).to eq(ended_at)
        end
      end
      it '(json)対象が一致する' do # Tips: ユニークではない為、正確ではない
        get infomations_path(page: page, format: :json)
        parse_response = JSON.parse(response.body)['infomations']
        (start_no..end_no).each do |no|
          expect(parse_response[no - start_no]['target']).to eq(@infomations[@infomations.count - no].target)
        end
      end
    end

    shared_examples_for 'リダイレクト' do |page, redirect_page|
      it '最終ページにリダイレクト' do
        get infomations_path(page: page)
        if redirect_page == 1
          expect(response).to redirect_to(infomations_path)
        else
          expect(response).to redirect_to(infomations_path(page: redirect_page))
        end
      end
      it '(json)リダイレクトしない' do
        get infomations_path(page: page, format: :json)
        expect(response).to be_successful
      end
    end

    # テストケース
    shared_examples_for '[*]お知らせがない' do
      include_context 'お知らせ一覧作成', 0, 0, 0, 0
      it_behaves_like 'ページ情報', 1
      it_behaves_like 'ページネーション非表示', 1, 2
      it_behaves_like 'リダイレクト', 2, 1
    end
    shared_examples_for '[未ログイン]お知らせが最大表示数と同じ' do
      count = Settings['test_infomations']
      include_context 'お知らせ一覧作成', count['all_forever_count'] + count['user_forever_count'], count['all_future_count'] + count['user_future_count'], 0, 0
      it_behaves_like 'ページ情報', 1
      it_behaves_like 'ページネーション非表示', 1, 2
      it_behaves_like 'リスト表示', 1
      it_behaves_like 'リダイレクト', 2, 1
    end
    shared_examples_for '[ログイン中/削除予約済み]お知らせが最大表示数と同じ' do
      count = Settings['test_infomations']
      include_context 'お知らせ一覧作成', count['all_forever_count'], count['all_future_count'], count['user_forever_count'], count['user_future_count']
      it_behaves_like 'ページ情報', 1
      it_behaves_like 'ページネーション非表示', 1, 2
      it_behaves_like 'リスト表示', 1
      it_behaves_like 'リダイレクト', 2, 1
    end
    shared_examples_for '[未ログイン]お知らせが最大表示数より多い' do
      count = Settings['test_infomations']
      include_context 'お知らせ一覧作成', count['all_forever_count'] + count['user_forever_count'], count['all_future_count'] + count['user_future_count'] + 1, 0, 0
      it_behaves_like 'ページ情報', 1
      it_behaves_like 'ページ情報', 2
      it_behaves_like 'ページネーション表示', 1, 2
      it_behaves_like 'ページネーション表示', 2, 1
      it_behaves_like 'リスト表示', 1
      it_behaves_like 'リスト表示', 2
      it_behaves_like 'リダイレクト', 3, 2
    end
    shared_examples_for '[ログイン中/削除予約済み]お知らせが最大表示数より多い' do
      count = Settings['test_infomations']
      include_context 'お知らせ一覧作成', count['all_forever_count'], count['all_future_count'], count['user_forever_count'], count['user_future_count'] + 1
      it_behaves_like 'ページ情報', 1
      it_behaves_like 'ページ情報', 2
      it_behaves_like 'ページネーション表示', 1, 2
      it_behaves_like 'ページネーション表示', 2, 1
      it_behaves_like 'リスト表示', 1
      it_behaves_like 'リスト表示', 2
      it_behaves_like 'リダイレクト', 3, 2
    end

    context '未ログイン' do
      it_behaves_like '[*]お知らせがない'
      it_behaves_like '[未ログイン]お知らせが最大表示数と同じ'
      it_behaves_like '[未ログイン]お知らせが最大表示数より多い'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[*]お知らせがない'
      it_behaves_like '[ログイン中/削除予約済み]お知らせが最大表示数と同じ'
      it_behaves_like '[ログイン中/削除予約済み]お知らせが最大表示数より多い'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[*]お知らせがない'
      it_behaves_like '[ログイン中/削除予約済み]お知らせが最大表示数と同じ'
      it_behaves_like '[ログイン中/削除予約済み]お知らせが最大表示数より多い'
    end
  end
end
