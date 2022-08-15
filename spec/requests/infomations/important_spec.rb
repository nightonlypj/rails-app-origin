require 'rails_helper'

RSpec.describe 'Infomations', type: :request do
  # GET /infomations/important(.json) 大切なお知らせAPI
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）, APIログイン中, APIログイン中（削除予約済み）
  #   大切なお知らせ: ない, ある
  #   ＋URLの拡張子: .json, ない
  #   ＋Acceptヘッダ: JSONが含まれる, JSONが含まれない
  describe 'GET #important' do
    subject { get important_infomations_path(format: subject_format), headers: auth_headers.merge(accept_headers) }
    before_all { FactoryBot.create(:infomation, :important, :force_finished) }

    # テスト内容
    shared_examples_for 'ToOK(json/json)' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it 'HTTPステータスが200。対象項目が一致する' do
        is_expected.to eq(200)
        expect(JSON.parse(response.body)['success']).to eq(true)
      end
    end

    shared_examples_for 'リスト表示(json)' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it '件数・対象項目が一致する' do
        subject
        response_json = JSON.parse(response.body)['infomations']
        expect(response_json.count).to eq(infomations.count)
        (1..infomations.count).each do |no|
          data = response_json[no - 1]
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

    shared_examples_for 'ToOK' do
      it_behaves_like 'ToOK(json/json)'
      it_behaves_like 'To406(json/html)'
      it_behaves_like 'To406(html/json)'
      it_behaves_like 'To406(html/html)'
    end

    # テストケース
    shared_examples_for '[*]大切なお知らせがない' do
      include_context '大切なお知らせ一覧作成', 0, 0, 0, 0
      it_behaves_like 'ToOK'
      it_behaves_like 'リスト表示(json)'
    end
    shared_examples_for '[未ログイン]大切なお知らせがある' do
      include_context '大切なお知らせ一覧作成', 1, 1, 0, 0
      it_behaves_like 'ToOK'
      it_behaves_like 'リスト表示(json)'
    end
    shared_examples_for '[ログイン中/削除予約済み]大切なお知らせがある' do
      include_context '大切なお知らせ一覧作成', 1, 1, 1, 1
      it_behaves_like 'ToOK'
      it_behaves_like 'リスト表示(json)'
    end

    context '未ログイン' do
      let(:infomations) { @all_important_infomations }
      include_context '未ログイン処理'
      include_context 'お知らせ一覧作成', 1, 1, 0, 0
      it_behaves_like '[*]大切なお知らせがない'
      it_behaves_like '[未ログイン]大切なお知らせがある'
    end
    context 'ログイン中' do
      let(:infomations) { @all_important_infomations } # Tips: APIは未ログイン扱いの為、全員のしか見れない
      include_context 'ログイン処理'
      include_context 'お知らせ一覧作成', 1, 1, 1, 1
      it_behaves_like '[*]大切なお知らせがない'
      it_behaves_like '[ログイン中/削除予約済み]大切なお知らせがある'
    end
    context 'ログイン中（削除予約済み）' do
      let(:infomations) { @all_important_infomations } # Tips: APIは未ログイン扱いの為、全員のしか見れない
      include_context 'ログイン処理', :destroy_reserved
      include_context 'お知らせ一覧作成', 1, 1, 1, 1
      it_behaves_like '[*]大切なお知らせがない'
      it_behaves_like '[ログイン中/削除予約済み]大切なお知らせがある'
    end
    context 'APIログイン中' do
      let(:infomations) { @user_important_infomations }
      include_context 'APIログイン処理'
      include_context 'お知らせ一覧作成', 1, 1, 1, 1
      it_behaves_like '[*]大切なお知らせがない'
      it_behaves_like '[ログイン中/削除予約済み]大切なお知らせがある'
    end
    context 'APIログイン中（削除予約済み）' do
      let(:infomations) { @user_important_infomations }
      include_context 'APIログイン処理', :destroy_reserved
      include_context 'お知らせ一覧作成', 1, 1, 1, 1
      it_behaves_like '[*]大切なお知らせがない'
      it_behaves_like '[ログイン中/削除予約済み]大切なお知らせがある'
    end
  end
end
