require 'rails_helper'

RSpec.describe 'Top', type: :request do
  # GET / トップページ
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）
  describe 'GET #index' do
    subject { get root_path }

    # テスト内容
    shared_examples_for 'ToOK' do
      it 'HTTPステータスが200' do
        is_expected.to eq(200)
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
      include_context 'ログイン処理', :user_destroy_reserved
      it_behaves_like 'ToOK'
    end
  end

  # お知らせ
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）
  #   お知らせ: ない, 最大表示数と同じ, 最大表示数より多い
  describe '@infomations' do
    subject { get root_path }

    # テスト内容
    shared_examples_for 'リスト表示' do
      it '対象項目が含まれる' do
        subject
        (1..Settings['infomations_limit']).each do |no|
          info = @user_infomations[@user_infomations.count - no]
          expect(response.body).to include(info.title) # タイトル
          expect(response.body).to include(info.summary) if info.summary.present? # 概要
          if info.body.present?
            expect(response.body).to include("\"#{infomation_path(info)}\"") # お知らせ詳細のパス
          else
            expect(response.body).not_to include("\"#{infomation_path(info)}\"") # Tips: 本文がない場合は表示しない
          end
          expect(response.body).to include(I18n.l(info.started_at.to_date)) # 掲載開始日
        end
      end
    end

    shared_examples_for 'リンク表示' do
      it 'お知らせ一覧のパスが含まれる' do
        subject
        expect(response.body).to include("\"#{infomations_path}\"")
      end
    end
    shared_examples_for 'リンク非表示' do
      it 'お知らせ一覧のパスが含まれない' do
        subject
        expect(response.body).not_to include("\"#{infomations_path}\"")
      end
    end

    # テストケース
    shared_examples_for '[*]お知らせがない' do
      it_behaves_like 'リンク非表示'
    end
    shared_examples_for '[未ログイン]お知らせが最大表示数と同じ' do
      count = Settings['test_infomations']
      include_context 'お知らせ一覧作成', count['all_forever_count'] + count['user_forever_count'], count['all_future_count'] + count['user_future_count'], 0, 0
      it_behaves_like 'リスト表示'
      it_behaves_like 'リンク表示'
    end
    shared_examples_for '[ログイン中/削除予約済み]お知らせが最大表示数と同じ' do
      count = Settings['test_infomations']
      include_context 'お知らせ一覧作成', count['all_forever_count'], count['all_future_count'], count['user_forever_count'], count['user_future_count']
      it_behaves_like 'リスト表示'
      it_behaves_like 'リンク表示'
    end
    shared_examples_for '[未ログイン]お知らせが最大表示数より多い' do
      count = Settings['test_infomations']
      include_context 'お知らせ一覧作成', count['all_forever_count'] + count['user_forever_count'], count['all_future_count'] + count['user_future_count'] + 1, 0, 0
      it_behaves_like 'リスト表示'
      it_behaves_like 'リンク表示'
    end
    shared_examples_for '[ログイン中/削除予約済み]お知らせが最大表示数より多い' do
      count = Settings['test_infomations']
      include_context 'お知らせ一覧作成', count['all_forever_count'], count['all_future_count'], count['user_forever_count'], count['user_future_count'] + 1
      it_behaves_like 'リスト表示'
      it_behaves_like 'リンク表示'
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
      include_context 'ログイン処理', :user_destroy_reserved
      it_behaves_like '[*]お知らせがない'
      it_behaves_like '[ログイン中/削除予約済み]お知らせが最大表示数と同じ'
      it_behaves_like '[ログイン中/削除予約済み]お知らせが最大表示数より多い'
    end
  end
end
