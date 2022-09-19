require 'rails_helper'

RSpec.describe 'Infomations', type: :request do
  # GET /infomations/1 お知らせ詳細
  # GET /infomations/1(.json) お知らせ詳細API
  # 前提条件
  #   なし
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
    shared_examples_for 'ToOK(html)' do
      let(:subject_format) { nil }
      it 'HTTPステータスが200。対象項目が含まれる' do
        is_expected.to eq(200)
        expect(response.body).to include(infomation.label_i18n) if infomation.label_i18n.present? # ラベル
        expect(response.body).to include(infomation.title) # タイトル
        expect(response.body).to include(infomation.body.present? ? infomation.body : infomation.summary) # 本文, サマリー
        expect(response.body).to include(I18n.l(infomation.started_at.to_date)) # 掲載開始日
      end
    end

    shared_examples_for 'ToOK(html/html)' do
      let(:accept_headers) { ACCEPT_INC_HTML }
      it_behaves_like 'ToOK(html)'
    end
    shared_examples_for 'ToOK(html/json)' do
      let(:accept_headers) { ACCEPT_INC_JSON }
      it_behaves_like 'ToOK(html)'
    end
    shared_examples_for 'ToOK(json/json)' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it 'HTTPステータスが200。対象項目が一致する' do
        is_expected.to eq(200)
        expect(JSON.parse(response.body)['success']).to eq(true)

        response_json = JSON.parse(response.body)['infomation']
        expect(response_json['label']).to eq(infomation.label) # ラベル
        expect(response_json['label_i18n']).to eq(infomation.label_i18n)
        expect(response_json['title']).to eq(infomation.title) # タイトル
        expect(response_json['summary']).to eq(infomation.summary) # サマリー
        expect(response_json['body']).to eq(infomation.body) # 本文
        expect(response_json['started_at']).to eq(I18n.l(infomation.started_at, format: :json)) # 掲載開始日
        expect(response_json['ended_at']).to eq(infomation.ended_at.present? ? I18n.l(infomation.ended_at, format: :json) : nil) # 掲載終了日
        expect(response_json['target']).to eq(infomation.target) # 対象
      end
    end
    shared_examples_for 'ToNot(json/json)' do |success, alert, notice|
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it 'HTTPステータスが404。対象項目が一致する' do
        is_expected.to eq(404)
        response_json = response.body.present? ? JSON.parse(response.body) : {}
        expect(response_json['success']).to eq(success)

        expect(response_json['alert']).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(response_json['notice']).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    shared_examples_for 'ToOK' do
      it_behaves_like 'ToOK(html/html)'
      it_behaves_like 'ToOK(html/json)'
    end
    shared_examples_for 'ToOK(json)' do
      it_behaves_like 'To406(json/html)'
      it_behaves_like 'ToOK(json/json)'
    end
    shared_examples_for 'ToNot' do
      it_behaves_like 'To404(html/html)'
      it_behaves_like 'To404(html/json)'
    end
    shared_examples_for 'ToNot(json)' do |success, alert, notice|
      it_behaves_like 'To406(json/html)'
      it_behaves_like 'ToNot(json/json)', success, alert, notice
    end

    # テストケース
    shared_examples_for '[*][全員][過去]終了日時が過去' do
      let_it_be(:ended_at) { Time.current - 1.day }
      include_context 'お知らせ作成'
      it_behaves_like 'ToNot'
      it_behaves_like 'ToNot(json)', false, 'errors.messages.infomation.ended', nil
    end
    shared_examples_for '[ログイン中/削除予約済み][自分][過去]終了日時が過去' do
      let_it_be(:ended_at) { Time.current - 1.day }
      include_context 'お知らせ作成'
      it_behaves_like 'ToNot'
      it_behaves_like 'ToNot(json)', nil, nil, nil # Tips: APIは未ログイン扱いの為、他人
    end
    shared_examples_for '[APIログイン中/削除予約済み][自分][過去]終了日時が過去' do
      let_it_be(:ended_at) { Time.current - 1.day }
      include_context 'お知らせ作成'
      it_behaves_like 'ToNot'
      it_behaves_like 'ToNot(json)', false, 'errors.messages.infomation.ended', nil
    end
    shared_examples_for '[*][他人][過去]終了日時が過去' do
      let_it_be(:ended_at) { Time.current - 1.day }
      include_context 'お知らせ作成'
      it_behaves_like 'ToNot'
      it_behaves_like 'ToNot(json)', nil, nil, nil
    end
    shared_examples_for '[*][*][未来]終了日時が過去' do # Tips: 不整合
      let_it_be(:ended_at) { Time.current - 1.day }
      include_context 'お知らせ作成'
      it_behaves_like 'ToNot'
      it_behaves_like 'ToNot(json)', nil, nil, nil
    end
    shared_examples_for '[*][全員][過去]終了日時が未来' do
      let_it_be(:ended_at) { Time.current + 1.day }
      include_context 'お知らせ作成'
      it_behaves_like 'ToOK'
      it_behaves_like 'ToOK(json)'
    end
    shared_examples_for '[ログイン中/削除予約済み][自分][過去]終了日時が未来' do
      let_it_be(:ended_at) { Time.current + 1.day }
      include_context 'お知らせ作成'
      it_behaves_like 'ToOK'
      it_behaves_like 'ToNot(json)', nil, nil, nil # Tips: APIは未ログイン扱いの為、他人
    end
    shared_examples_for '[APIログイン中/削除予約済み][自分][過去]終了日時が未来' do
      let_it_be(:ended_at) { Time.current + 1.day }
      include_context 'お知らせ作成'
      it_behaves_like 'ToOK' # Tips: HTMLもログイン状態になる
      it_behaves_like 'ToOK(json)'
    end
    shared_examples_for '[*][他人][過去]終了日時が未来' do
      let_it_be(:ended_at) { Time.current + 1.day }
      include_context 'お知らせ作成'
      it_behaves_like 'ToNot'
      it_behaves_like 'ToNot(json)', nil, nil, nil
    end
    shared_examples_for '[*][*][未来]終了日時が未来' do
      let_it_be(:ended_at) { Time.current + 1.day }
      include_context 'お知らせ作成'
      it_behaves_like 'ToNot'
      it_behaves_like 'ToNot(json)', nil, nil, nil
    end
    shared_examples_for '[*][全員][過去]終了日時がない' do
      let_it_be(:ended_at) { nil }
      include_context 'お知らせ作成'
      it_behaves_like 'ToOK'
      it_behaves_like 'ToOK(json)'
    end
    shared_examples_for '[ログイン中/削除予約済み][自分][過去]終了日時がない' do
      let_it_be(:ended_at) { nil }
      include_context 'お知らせ作成'
      it_behaves_like 'ToOK'
      it_behaves_like 'ToNot(json)', nil, nil, nil # Tips: APIは未ログイン扱いの為、他人
    end
    shared_examples_for '[APIログイン中/削除予約済み][自分][過去]終了日時がない' do
      let_it_be(:ended_at) { nil }
      include_context 'お知らせ作成'
      it_behaves_like 'ToOK' # Tips: HTMLもログイン状態になる
      it_behaves_like 'ToOK(json)'
    end
    shared_examples_for '[*][他人][過去]終了日時がない' do
      let_it_be(:ended_at) { nil }
      include_context 'お知らせ作成'
      it_behaves_like 'ToNot'
      it_behaves_like 'ToNot(json)', nil, nil, nil
    end
    shared_examples_for '[*][*][未来]終了日時がない' do
      let_it_be(:ended_at) { nil }
      include_context 'お知らせ作成'
      it_behaves_like 'ToNot'
      it_behaves_like 'ToNot(json)', nil, nil, nil
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
      # it_behaves_like '[未ログイン]対象が自分' # Tips: 未ログインの為、他人
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
