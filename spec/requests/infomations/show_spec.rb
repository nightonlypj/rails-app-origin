require 'rails_helper'

RSpec.describe 'Infomations', type: :request do
  # GET /infomations/1 お知らせ詳細
  # GET /infomations/1.json お知らせ詳細API
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   対象: 全員, 自分, 他人
  #   開始日時: 過去, 未来
  #   終了日時: 過去, 未来, ない → まとめてデータ作成
  describe 'GET #show' do
    subject { get infomation_path(id: infomation.id, format: subject_format) }
    let(:infomation)   { FactoryBot.create(:infomation, started_at: started_at, ended_at: ended_at, target: target, user_id: user_id) }
    let(:outside_user) { FactoryBot.create(:user) }

    # テスト内容
    shared_examples_for 'ToOK' do
      let(:subject_format) { nil }
      it '成功ステータス。対象項目が含まれる' do
        is_expected.to eq(200)
        expect(response.body).to include(infomation.title) # タイトル
        expect(response.body).to include(infomation.body) if infomation.body.present? # 本文
        expect(response.body).to include(I18n.l(infomation.started_at.to_date)) # 掲載開始日 # Tips: ユニークではない為、正確ではない
      end
    end
    shared_examples_for 'ToOK(json)' do
      let(:subject_format) { :json }
      it '成功ステータス。対象項目が一致する' do
        is_expected.to eq(200)
        expect(JSON.parse(response.body)['success']).to eq(true)

        response_json = JSON.parse(response.body)['infomation']
        expect(response_json['title']).to eq(infomation.title) # タイトル
        expect(response_json['body']).to eq(infomation.body.present? ? infomation.body : '') # 本文
        expect(response_json['started_at']).to eq(I18n.l(infomation.started_at, format: :json)) # 掲載開始日 # Tips: ユニークではない為、正確ではない
        expect(response_json['ended_at']).to eq(infomation.ended_at.present? ? I18n.l(infomation.ended_at, format: :json) : '') # 掲載終了日 # Tips: ユニークではない為、正確ではない
        expect(response_json['target']).to eq(infomation.target) # 対象 # Tips: ユニークではない為、正確ではない
      end
    end
    shared_examples_for 'ToNot' do
      let(:subject_format) { nil }
      it '存在しないステータス' do
        is_expected.to eq(404)
      end
    end
    shared_examples_for 'ToNot(json)' do |success, alert, notice|
      let(:subject_format) { :json }
      it '存在しないステータス。対象項目が一致する' do
        is_expected.to eq(404)
        response_json = response.body.present? ? JSON.parse(response.body) : {}
        expect(response_json['success']).to eq(success)

        expect(response_json['alert']).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(response_json['notice']).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[*][全員][過去]終了日時が過去' do
      let(:ended_at) { Time.current - 1.day }
      it_behaves_like 'ToNot'
      it_behaves_like 'ToNot(json)', false, 'errors.messages.infomation.ended', nil
    end
    shared_examples_for '[ログイン中/削除予約済み][自分][過去]終了日時が過去' do
      let(:ended_at) { Time.current - 1.day }
      it_behaves_like 'ToNot'
      it_behaves_like 'ToNot(json)', false, 'errors.messages.infomation.ended', nil
    end
    shared_examples_for '[*][他人][過去]終了日時が過去' do
      let(:ended_at) { Time.current - 1.day }
      it_behaves_like 'ToNot'
      it_behaves_like 'ToNot(json)', nil, nil, nil
    end
    shared_examples_for '[*][*][未来]終了日時が過去' do # Tips: 不整合
      let(:ended_at) { Time.current - 1.day }
      it_behaves_like 'ToNot'
      it_behaves_like 'ToNot(json)', nil, nil, nil
    end
    shared_examples_for '[*][全員][過去]終了日時が未来' do
      let(:ended_at) { Time.current + 1.day }
      it_behaves_like 'ToOK'
      it_behaves_like 'ToOK(json)'
    end
    shared_examples_for '[ログイン中/削除予約済み][自分][過去]終了日時が未来' do
      let(:ended_at) { Time.current + 1.day }
      it_behaves_like 'ToOK'
      it_behaves_like 'ToOK(json)'
    end
    shared_examples_for '[*][他人][過去]終了日時が未来' do
      let(:ended_at) { Time.current + 1.day }
      it_behaves_like 'ToNot'
      it_behaves_like 'ToNot(json)', nil, nil, nil
    end
    shared_examples_for '[*][*][未来]終了日時が未来' do
      let(:ended_at) { Time.current + 1.day }
      it_behaves_like 'ToNot'
      it_behaves_like 'ToNot(json)', nil, nil, nil
    end
    shared_examples_for '[*][全員][過去]終了日時がない' do
      let(:ended_at) { nil }
      it_behaves_like 'ToOK'
      it_behaves_like 'ToOK(json)'
    end
    shared_examples_for '[ログイン中/削除予約済み][自分][過去]終了日時がない' do
      let(:ended_at) { nil }
      it_behaves_like 'ToOK'
      it_behaves_like 'ToOK(json)'
    end
    shared_examples_for '[*][他人][過去]終了日時がない' do
      let(:ended_at) { nil }
      it_behaves_like 'ToNot'
      it_behaves_like 'ToNot(json)', nil, nil, nil
    end
    shared_examples_for '[*][*][未来]終了日時がない' do
      let(:ended_at) { nil }
      it_behaves_like 'ToNot'
      it_behaves_like 'ToNot(json)', nil, nil, nil
    end

    shared_examples_for '[*][全員]開始日時が過去' do
      let(:started_at) { Time.current - 1.day }
      it_behaves_like '[*][全員][過去]終了日時が過去'
      it_behaves_like '[*][全員][過去]終了日時が未来'
      it_behaves_like '[*][全員][過去]終了日時がない'
    end
    shared_examples_for '[ログイン中/削除予約済み][自分]開始日時が過去' do
      let(:started_at) { Time.current - 1.day }
      it_behaves_like '[ログイン中/削除予約済み][自分][過去]終了日時が過去'
      it_behaves_like '[ログイン中/削除予約済み][自分][過去]終了日時が未来'
      it_behaves_like '[ログイン中/削除予約済み][自分][過去]終了日時がない'
    end
    shared_examples_for '[*][他人]開始日時が過去' do
      let(:started_at) { Time.current - 1.day }
      it_behaves_like '[*][他人][過去]終了日時が過去'
      it_behaves_like '[*][他人][過去]終了日時が未来'
      it_behaves_like '[*][他人][過去]終了日時がない'
    end
    shared_examples_for '[*][*]開始日時が未来' do
      let(:started_at) { Time.current + 1.day }
      it_behaves_like '[*][*][未来]終了日時が過去'
      it_behaves_like '[*][*][未来]終了日時が未来'
      it_behaves_like '[*][*][未来]終了日時がない'
    end

    shared_examples_for '[*]対象が全員' do
      let(:target)  { :All }
      let(:user_id) { nil }
      it_behaves_like '[*][全員]開始日時が過去'
      it_behaves_like '[*][*]開始日時が未来'
    end
    shared_examples_for '[ログイン中/削除予約済み]対象が自分' do
      let(:target)  { :User }
      let(:user_id) { user.id }
      it_behaves_like '[ログイン中/削除予約済み][自分]開始日時が過去'
      it_behaves_like '[*][*]開始日時が未来'
    end
    shared_examples_for '[*]対象が他人' do
      let(:target)  { :User }
      let(:user_id) { outside_user.id }
      it_behaves_like '[*][他人]開始日時が過去'
      it_behaves_like '[*][*]開始日時が未来'
    end

    context '未ログイン' do
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
      include_context 'ログイン処理', :user_destroy_reserved
      it_behaves_like '[*]対象が全員'
      it_behaves_like '[ログイン中/削除予約済み]対象が自分'
      it_behaves_like '[*]対象が他人'
    end
  end
end
