require 'rails_helper'

RSpec.describe 'Infomations', type: :request do
  let(:response_json) { response.body.present? ? JSON.parse(response.body) : {} }
  let(:response_json_infomation)  { response_json['infomation'] }
  let(:response_json_infomations) { response_json['infomations'] }

  # GET /infomations/:id お知らせ詳細
  # GET /infomations/:id(.json) お知らせ詳細API
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）, APIログイン中, APIログイン中（削除予約済み）
  #   対象: 全員, 自分, 他人
  #   開始日時: 過去, 未来
  #   終了日時: 過去, 未来, ない
  #   ＋URLの拡張子: ない, .json
  #   ＋Acceptヘッダ: HTMLが含まれる, JSONが含まれる
  describe 'GET #show' do
    subject { get infomation_path(id: infomation.id, format: subject_format), headers: auth_headers.merge(accept_headers) }
    let_it_be(:outside_user) { FactoryBot.create(:user) }

    shared_context 'お知らせ作成' do
      let_it_be(:infomation) { FactoryBot.create(:infomation, started_at: started_at, ended_at: ended_at, target: target, user_id: user_id) }
    end

    # テスト内容
    shared_examples_for 'ToOK(html/*)' do
      it 'HTTPステータスが200。対象項目が含まれる' do
        is_expected.to eq(200)
        expect(response.body).to include(infomation.label_i18n) if infomation.label_i18n.present? # ラベル
        expect(response.body).to include(infomation.title) # タイトル
        expect(response.body).to include(infomation.body.present? ? infomation.body : infomation.summary) # 本文, サマリー
        expect(response.body).to include(I18n.l(infomation.started_at.to_date)) # 掲載開始日
      end
    end
    shared_examples_for 'ToOK(json/json)' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it 'HTTPステータスが200。対象項目が一致する' do
        is_expected.to eq(200)
        expect(response_json['success']).to eq(true)
        expect(response_json_infomation['label']).to eq(infomation.label) # ラベル
        expect(response_json_infomation['label_i18n']).to eq(infomation.label_i18n)
        expect(response_json_infomation['title']).to eq(infomation.title) # タイトル
        expect(response_json_infomation['summary']).to eq(infomation.summary) # サマリー
        expect(response_json_infomation['body']).to eq(infomation.body) # 本文
        expect(response_json_infomation['started_at']).to eq(I18n.l(infomation.started_at, format: :json)) # 掲載開始日
        expect(response_json_infomation['ended_at']).to eq(I18n.l(infomation.ended_at, format: :json, default: nil)) # 掲載終了日
        expect(response_json_infomation['target']).to eq(infomation.target) # 対象
      end
    end

    # テストケース
    shared_examples_for '[*][全員][過去]終了日時が過去' do
      let_it_be(:ended_at) { Time.current - 1.day }
      include_context 'お知らせ作成'
      it_behaves_like 'ToNG(html)', 404
      it_behaves_like 'ToNG(json)', 404, nil, 'errors.messages.infomation.ended'
    end
    shared_examples_for '[ログイン中/削除予約済み][自分][過去]終了日時が過去' do
      let_it_be(:ended_at) { Time.current - 1.day }
      include_context 'お知らせ作成'
      it_behaves_like 'ToNG(html)', 404
      it_behaves_like 'ToNG(json)', 404 # NOTE: APIは未ログイン扱いの為、他人
    end
    shared_examples_for '[APIログイン中/削除予約済み][自分][過去]終了日時が過去' do
      let_it_be(:ended_at) { Time.current - 1.day }
      include_context 'お知らせ作成'
      it_behaves_like 'ToNG(html)', 404
      it_behaves_like 'ToNG(json)', 404, nil, 'errors.messages.infomation.ended'
    end
    shared_examples_for '[*][他人][過去]終了日時が過去' do
      let_it_be(:ended_at) { Time.current - 1.day }
      include_context 'お知らせ作成'
      it_behaves_like 'ToNG(html)', 404
      it_behaves_like 'ToNG(json)', 404
    end
    shared_examples_for '[*][*][未来]終了日時が過去' do # NOTE: 不整合
      let_it_be(:ended_at) { Time.current - 1.day }
      include_context 'お知らせ作成'
      it_behaves_like 'ToNG(html)', 404
      it_behaves_like 'ToNG(json)', 404
    end
    shared_examples_for '[*][全員][過去]終了日時が未来' do
      let_it_be(:ended_at) { Time.current + 1.day }
      include_context 'お知らせ作成'
      it_behaves_like 'ToOK(html)'
      it_behaves_like 'ToOK(json)'
    end
    shared_examples_for '[ログイン中/削除予約済み][自分][過去]終了日時が未来' do
      let_it_be(:ended_at) { Time.current + 1.day }
      include_context 'お知らせ作成'
      it_behaves_like 'ToOK(html)'
      it_behaves_like 'ToNG(json)', 404 # NOTE: APIは未ログイン扱いの為、他人
    end
    shared_examples_for '[APIログイン中/削除予約済み][自分][過去]終了日時が未来' do
      let_it_be(:ended_at) { Time.current + 1.day }
      include_context 'お知らせ作成'
      it_behaves_like 'ToOK(html)' # NOTE: HTMLもログイン状態になる
      it_behaves_like 'ToOK(json)'
    end
    shared_examples_for '[*][他人][過去]終了日時が未来' do
      let_it_be(:ended_at) { Time.current + 1.day }
      include_context 'お知らせ作成'
      it_behaves_like 'ToNG(html)', 404
      it_behaves_like 'ToNG(json)', 404
    end
    shared_examples_for '[*][*][未来]終了日時が未来' do
      let_it_be(:ended_at) { Time.current + 1.day }
      include_context 'お知らせ作成'
      it_behaves_like 'ToNG(html)', 404
      it_behaves_like 'ToNG(json)', 404
    end
    shared_examples_for '[*][全員][過去]終了日時がない' do
      let_it_be(:ended_at) { nil }
      include_context 'お知らせ作成'
      it_behaves_like 'ToOK(html)'
      it_behaves_like 'ToOK(json)'
    end
    shared_examples_for '[ログイン中/削除予約済み][自分][過去]終了日時がない' do
      let_it_be(:ended_at) { nil }
      include_context 'お知らせ作成'
      it_behaves_like 'ToOK(html)'
      it_behaves_like 'ToNG(json)', 404 # NOTE: APIは未ログイン扱いの為、他人
    end
    shared_examples_for '[APIログイン中/削除予約済み][自分][過去]終了日時がない' do
      let_it_be(:ended_at) { nil }
      include_context 'お知らせ作成'
      it_behaves_like 'ToOK(html)' # NOTE: HTMLもログイン状態になる
      it_behaves_like 'ToOK(json)'
    end
    shared_examples_for '[*][他人][過去]終了日時がない' do
      let_it_be(:ended_at) { nil }
      include_context 'お知らせ作成'
      it_behaves_like 'ToNG(html)', 404
      it_behaves_like 'ToNG(json)', 404
    end
    shared_examples_for '[*][*][未来]終了日時がない' do
      let_it_be(:ended_at) { nil }
      include_context 'お知らせ作成'
      it_behaves_like 'ToNG(html)', 404
      it_behaves_like 'ToNG(json)', 404
    end

    shared_examples_for '[*][全員]開始日時が過去' do
      let_it_be(:started_at) { Time.current - 1.day }
      it_behaves_like '[*][全員][過去]終了日時が過去'
      it_behaves_like '[*][全員][過去]終了日時が未来'
      it_behaves_like '[*][全員][過去]終了日時がない'
    end
    shared_examples_for '[ログイン中/削除予約済み][自分]開始日時が過去' do
      let_it_be(:started_at) { Time.current - 1.day }
      it_behaves_like '[ログイン中/削除予約済み][自分][過去]終了日時が過去'
      it_behaves_like '[ログイン中/削除予約済み][自分][過去]終了日時が未来'
      it_behaves_like '[ログイン中/削除予約済み][自分][過去]終了日時がない'
    end
    shared_examples_for '[APIログイン中/削除予約済み][自分]開始日時が過去' do
      let_it_be(:started_at) { Time.current - 1.day }
      it_behaves_like '[APIログイン中/削除予約済み][自分][過去]終了日時が過去'
      it_behaves_like '[APIログイン中/削除予約済み][自分][過去]終了日時が未来'
      it_behaves_like '[APIログイン中/削除予約済み][自分][過去]終了日時がない'
    end
    shared_examples_for '[*][他人]開始日時が過去' do
      let_it_be(:started_at) { Time.current - 1.day }
      it_behaves_like '[*][他人][過去]終了日時が過去'
      it_behaves_like '[*][他人][過去]終了日時が未来'
      it_behaves_like '[*][他人][過去]終了日時がない'
    end
    shared_examples_for '[*][*]開始日時が未来' do
      let_it_be(:started_at) { Time.current + 1.day }
      it_behaves_like '[*][*][未来]終了日時が過去'
      it_behaves_like '[*][*][未来]終了日時が未来'
      it_behaves_like '[*][*][未来]終了日時がない'
    end

    shared_examples_for '[*]対象が全員' do
      let_it_be(:target)  { :all }
      let_it_be(:user_id) { nil }
      it_behaves_like '[*][全員]開始日時が過去'
      it_behaves_like '[*][*]開始日時が未来'
    end
    shared_examples_for '[ログイン中/削除予約済み]対象が自分' do
      let_it_be(:target)  { :user }
      let_it_be(:user_id) { user.id }
      it_behaves_like '[ログイン中/削除予約済み][自分]開始日時が過去'
      it_behaves_like '[*][*]開始日時が未来'
    end
    shared_examples_for '[APIログイン中/削除予約済み]対象が自分' do
      let_it_be(:target)  { :user }
      let_it_be(:user_id) { user.id }
      it_behaves_like '[APIログイン中/削除予約済み][自分]開始日時が過去'
      it_behaves_like '[*][*]開始日時が未来'
    end
    shared_examples_for '[*]対象が他人' do
      let_it_be(:target)  { :user }
      let_it_be(:user_id) { outside_user.id }
      it_behaves_like '[*][他人]開始日時が過去'
      it_behaves_like '[*][*]開始日時が未来'
    end

    context '未ログイン' do
      include_context '未ログイン処理'
      it_behaves_like '[*]対象が全員'
      # it_behaves_like '[未ログイン]対象が自分' # NOTE: 未ログインの為、他人
      it_behaves_like '[*]対象が他人'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[*]対象が全員'
      it_behaves_like '[ログイン中/削除予約済み]対象が自分'
      it_behaves_like '[*]対象が他人'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', :destroy_reserved
      it_behaves_like '[*]対象が全員'
      it_behaves_like '[ログイン中/削除予約済み]対象が自分'
      it_behaves_like '[*]対象が他人'
    end
    context 'APIログイン中' do
      include_context 'APIログイン処理'
      it_behaves_like '[*]対象が全員'
      it_behaves_like '[APIログイン中/削除予約済み]対象が自分'
      it_behaves_like '[*]対象が他人'
    end
    context 'APIログイン中（削除予約済み）' do
      include_context 'APIログイン処理', :destroy_reserved
      it_behaves_like '[*]対象が全員'
      it_behaves_like '[APIログイン中/削除予約済み]対象が自分'
      it_behaves_like '[*]対象が他人'
    end
  end
end
