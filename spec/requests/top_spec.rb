require 'rails_helper'

RSpec.describe 'Top', type: :request do
  let(:response_json) { response.body.present? ? JSON.parse(response.body) : {} }

  # GET / トップページ
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）, APIログイン中, APIログイン中（削除予約済み）
  #   大切なお知らせ: ない, ある
  #   ＋URLの拡張子: ない, .json
  #   ＋Acceptヘッダ: HTMLが含まれる, JSONが含まれる
  describe 'GET #index' do
    subject { get root_path(format: subject_format), headers: auth_headers.merge(accept_headers) }

    # テスト内容
    shared_examples_for 'ToOK(html/*)' do
      it 'HTTPステータスが200。対象項目が含まれる' do
        is_expected.to eq(200)
        (1..@user_important_infomations.count).each do |no|
          infomation = @user_important_infomations[@user_important_infomations.count - no]

          expect(response.body).to include(infomation.label_i18n) if infomation.label_i18n.present?
          expect(response.body).to include(infomation.title)

          url = "href=\"#{infomation_path(infomation)}\""
          if infomation.body.present? || infomation.summary.present?
            expect(response.body).to include(url)
          else
            expect(response.body).not_to include(url)
          end

          expect(response.body).to include(I18n.l(infomation.started_at.to_date))
        end
      end
    end

    # テストケース
    shared_examples_for '[*]大切なお知らせがない' do
      include_context '大切なお知らせ一覧作成', 0, 0, 0, 0
      it_behaves_like 'ToOK(html)'
    end
    shared_examples_for '[未ログイン]大切なお知らせがある' do
      include_context '大切なお知らせ一覧作成', 1, 1, 0, 0
      it_behaves_like 'ToOK(html)'
    end
    shared_examples_for '[ログイン中/削除予約済み]大切なお知らせがある' do
      include_context '大切なお知らせ一覧作成', 1, 1, 1, 1
      it_behaves_like 'ToOK(html)'
    end

    shared_examples_for '[ログイン中/削除予約済み]' do
      include_context 'お知らせ一覧作成', 1, 1, 1, 1
      it_behaves_like '[*]大切なお知らせがない'
      it_behaves_like '[ログイン中/削除予約済み]大切なお知らせがある'
      it_behaves_like 'ToNG(json)', 406
    end
    shared_examples_for '[APIログイン中/削除予約済み]' do
      include_context 'お知らせ一覧作成', 1, 1, 1, 1
      it_behaves_like '[*]大切なお知らせがない'
      it_behaves_like '[未ログイン]大切なお知らせがある' # NOTE: APIは未ログイン扱い
      it_behaves_like 'ToNG(json)', 406
    end

    context '未ログイン' do
      include_context '未ログイン処理'
      include_context 'お知らせ一覧作成', 1, 1, 0, 0
      it_behaves_like '[*]大切なお知らせがない'
      it_behaves_like '[未ログイン]大切なお知らせがある'
      it_behaves_like 'ToNG(json)', 406
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
