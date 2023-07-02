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
        expect(response_json.count).to eq(2)
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
          count = expect_infomation_json(data, infomation, { id: true, body: false })
          expect(data['force_started_at']).to eq(I18n.l(infomation.force_started_at, format: :json, default: nil))
          expect(data['force_ended_at']).to eq(I18n.l(infomation.force_ended_at, format: :json, default: nil))
          expect(data.count).to eq(count + 2)
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
    shared_examples_for '[未ログイン以外]大切なお知らせがある' do
      include_context '大切なお知らせ一覧作成', 1, 1, 1, 1
      it_behaves_like 'ToNG(html)', 406
      it_behaves_like 'ToOK(json)'
      it_behaves_like 'リスト表示(json)'
    end

    shared_examples_for '[ログイン中/削除予約済み]' do
      let(:infomations) { @all_important_infomations } # NOTE: APIは未ログイン扱いの為、全員のしか見れない
      include_context 'お知らせ一覧作成', 1, 1, 1, 1
      it_behaves_like '[*]大切なお知らせがない'
      it_behaves_like '[未ログイン以外]大切なお知らせがある'
    end
    shared_examples_for '[APIログイン中/削除予約済み]' do
      let(:infomations) { @user_important_infomations }
      include_context 'お知らせ一覧作成', 1, 1, 1, 1
      it_behaves_like '[*]大切なお知らせがない'
      it_behaves_like '[未ログイン以外]大切なお知らせがある'
    end

    context '未ログイン' do
      let(:infomations) { @all_important_infomations }
      include_context '未ログイン処理'
      include_context 'お知らせ一覧作成', 1, 1, 0, 0
      it_behaves_like '[*]大切なお知らせがない'
      it_behaves_like '[未ログイン]大切なお知らせがある'
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
