require 'rails_helper'

RSpec.describe 'Infomations', type: :request do
  let(:response_json) { JSON.parse(response.body) }
  let(:response_json_infomations) { response_json['infomations'] }

  # GET /infomations/important(.json) 大切なお知らせ一覧API
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
        expect(response_json['success']).to eq(true)
      end
    end

    shared_examples_for 'リスト表示(json)' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it '件数・対象項目が一致する' do
        subject
        expect(response_json_infomations.count).to eq(infomations.count)
        (1..infomations.count).each do |no|
          data = response_json_infomations[no - 1]
          infomation = infomations[infomations.count - no]
          expect(data['id']).to eq(infomation.id) # ID
          expect(data['label']).to eq(infomation.label) # ラベル
          expect(data['label_i18n']).to eq(infomation.label_i18n)
          expect(data['title']).to eq(infomation.title) # タイトル
          expect(data['summary']).to eq(infomation.summary) # 概要
          expect(data['body_present']).to eq(infomation.body.present?) # 本文
          expect(data['started_at']).to eq(I18n.l(infomation.started_at, format: :json)) # 掲載開始日
          expect(data['ended_at']).to eq(I18n.l(infomation.ended_at, format: :json, default: nil)) # 掲載終了日
          expect(data['target']).to eq(infomation.target) # 対象
        end
      end
    end

    # テストケース
    shared_examples_for '[*]大切なお知らせがない' do
      include_context '大切なお知らせ一覧作成', 0, 0, 0, 0
      it_behaves_like 'ToNG(html)', 406
      it_behaves_like 'ToOK(json)'
      it_behaves_like 'リスト表示(json)'
    end
    shared_examples_for '[未ログイン]大切なお知らせがある' do
      include_context '大切なお知らせ一覧作成', 1, 1, 0, 0
      it_behaves_like 'ToNG(html)', 406
      it_behaves_like 'ToOK(json)'
      it_behaves_like 'リスト表示(json)'
    end
    shared_examples_for '[ログイン中/削除予約済み]大切なお知らせがある' do
      include_context '大切なお知らせ一覧作成', 1, 1, 1, 1
      it_behaves_like 'ToNG(html)', 406
      it_behaves_like 'ToOK(json)'
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
      let(:infomations) { @all_important_infomations } # NOTE: APIは未ログイン扱いの為、全員のしか見れない
      include_context 'ログイン処理'
      include_context 'お知らせ一覧作成', 1, 1, 1, 1
      it_behaves_like '[*]大切なお知らせがない'
      it_behaves_like '[ログイン中/削除予約済み]大切なお知らせがある'
    end
    context 'ログイン中（削除予約済み）' do
      let(:infomations) { @all_important_infomations } # NOTE: APIは未ログイン扱いの為、全員のしか見れない
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
