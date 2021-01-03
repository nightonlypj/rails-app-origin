require 'rails_helper'

RSpec.describe 'Top', type: :request do
  # GET / トップページ
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  describe 'GET /index' do
    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get root_path
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

  # 新しいお知らせ
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   お知らせ: ない, 最大表示数と同じ, 最大表示数より多い → データ作成
  describe '@new_infomations' do
    # テスト内容
    shared_examples_for 'リスト表示' do
      let!(:end_no) { Settings['new_infomations_limit'] }
      it 'タイトルが含まれる' do
        get root_path
        (1..end_no).each do |no|
          expect(response.body).to include(@infomations[@infomations.count - no].title)
        end
      end
      it '概要が含まれる（ありの場合）' do
        get root_path
        (1..end_no).each do |no|
          expect(response.body).to include(@infomations[@infomations.count - no].summary) if @infomations[@infomations.count - no].summary.present?
        end
      end
      it 'お知らせ詳細のパスが含まれる（本文ありの場合）' do
        get root_path
        (1..end_no).each do |no|
          if @infomations[@infomations.count - no].body.present?
            expect(response.body).to include("\"#{infomation_path(@infomations[@infomations.count - no])}\"")
          end
        end
      end
      it 'お知らせ詳細のパスが含まれない（本文なしの場合）' do
        get root_path
        (1..end_no).each do |no|
          unless @infomations[@infomations.count - no].body.present?
            expect(response.body).not_to include("\"#{infomation_path(@infomations[@infomations.count - no])}\"")
          end
        end
      end
      it '掲載開始日が含まれる' do # Tips: ユニークではない為、正確ではない
        get root_path
        (1..end_no).each do |no|
          expect(response.body).to include(I18n.l(@infomations[@infomations.count - no].started_at.to_date))
        end
      end
    end

    shared_examples_for 'もっと見る表示' do
      it 'パスが含まれる' do
        get root_path
        expect(response.body).to include("\"#{infomations_path}\"")
      end
    end
    shared_examples_for 'もっと見る非表示' do
      it 'パスが含まれない' do
        get root_path
        expect(response.body).not_to include("\"#{infomations_path}\"")
      end
    end

    # テストケース
    shared_examples_for 'お知らせがない' do
      it_behaves_like 'もっと見る非表示'
    end
    shared_examples_for '[未ログイン]お知らせが最大表示数と同じ' do
      count = Settings['test_infomations']
      include_context 'お知らせ一覧作成', count['all_forever_count'] + count['user_forever_count'], count['all_future_count'] + count['user_future_count'], 0, 0
      it_behaves_like 'リスト表示'
      it_behaves_like 'もっと見る非表示'
    end
    shared_examples_for '[ログイン中]お知らせが最大表示数と同じ' do
      count = Settings['test_infomations']
      include_context 'お知らせ一覧作成', count['all_forever_count'], count['all_future_count'], count['user_forever_count'], count['user_future_count']
      it_behaves_like 'リスト表示'
      it_behaves_like 'もっと見る非表示'
    end
    shared_examples_for '[未ログイン]お知らせが最大表示数より多い' do
      count = Settings['test_infomations']
      include_context 'お知らせ一覧作成', count['all_forever_count'] + count['user_forever_count'], count['all_future_count'] + count['user_future_count'] + 1, 0, 0
      it_behaves_like 'リスト表示'
      it_behaves_like 'もっと見る表示'
    end
    shared_examples_for '[ログイン中]お知らせが最大表示数より多い' do
      count = Settings['test_infomations']
      include_context 'お知らせ一覧作成', count['all_forever_count'], count['all_future_count'], count['user_forever_count'], count['user_future_count'] + 1
      it_behaves_like 'リスト表示'
      it_behaves_like 'もっと見る表示'
    end

    context '未ログイン' do
      it_behaves_like 'お知らせがない'
      it_behaves_like '[未ログイン]お知らせが最大表示数と同じ'
      it_behaves_like '[未ログイン]お知らせが最大表示数より多い'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'お知らせがない'
      it_behaves_like '[ログイン中]お知らせが最大表示数と同じ'
      it_behaves_like '[ログイン中]お知らせが最大表示数より多い'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like 'お知らせがない'
      it_behaves_like '[ログイン中]お知らせが最大表示数と同じ'
      it_behaves_like '[ログイン中]お知らせが最大表示数より多い'
    end
  end
end
