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
  describe 'GET /show' do
    let!(:outside_user) { FactoryBot.create(:user) }
    shared_context 'データ作成' do
      let!(:infomation) { FactoryBot.create(:infomation, started_at: started_at, ended_at: ended_at, target: target, user_id: user_id) }
    end

    # テスト内容
    shared_examples_for 'ToOK' do
      include_context 'データ作成'
      it '成功ステータス' do
        get infomation_path(id: infomation.id)
        expect(response).to be_successful
      end
      it '(json)成功ステータス' do
        get infomation_path(id: infomation.id, format: :json)
        expect(response).to be_successful
      end
      it 'タイトルが含まれる' do
        get infomation_path(id: infomation.id)
        expect(response.body).to include(infomation.title)
      end
      it '(json)タイトルが一致する' do
        get infomation_path(id: infomation.id, format: :json)
        expect(JSON.parse(response.body)['infomation']['title']).to eq(infomation.title)
      end
      it '本文が含まれる（ありの場合）' do
        get infomation_path(id: infomation.id)
        expect(response.body).to include(infomation.body) if infomation.body.present?
      end
      it '(json)本文が一致する' do
        get infomation_path(id: infomation.id, format: :json)
        expect(JSON.parse(response.body)['infomation']['body']).to eq(infomation.body.present? ? infomation.body : '')
      end
      it '掲載開始日が含まれる' do # Tips: ユニークではない為、正確ではない
        get infomation_path(id: infomation.id)
        expect(response.body).to include(I18n.l(infomation.started_at.to_date))
      end
      it '(json)開始日時が一致する' do # Tips: ユニークではない為、正確ではない
        get infomation_path(id: infomation.id, format: :json)
        expect(JSON.parse(response.body)['infomation']['started_at']).to eq(I18n.l(infomation.started_at, format: :json))
      end
      it '(json)終了日時が一致する' do # Tips: ユニークではない為、正確ではない
        get infomation_path(id: infomation.id, format: :json)
        expect(JSON.parse(response.body)['infomation']['ended_at']).to eq(infomation.ended_at.present? ? I18n.l(infomation.ended_at, format: :json) : '')
      end
      it '(json)対象が一致する' do # Tips: ユニークではない為、正確ではない
        get infomation_path(id: infomation.id, format: :json)
        expect(JSON.parse(response.body)['infomation']['target']).to eq(infomation.target)
      end
    end
    shared_examples_for 'ToNG' do |error|
      include_context 'データ作成'
      it '存在しないステータス' do
        get infomation_path(id: infomation.id)
        expect(response).to be_not_found
      end
      it '(json)存在しないエラー' do
        get infomation_path(id: infomation.id, format: :json)
        expect(response).to be_not_found
        message = response.body.present? ? JSON.parse(response.body)['error'] : nil
        expect(message).to error.present? ? eq(I18n.t(error)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[*][全員][過去]終了日時が過去' do
      let!(:ended_at) { Time.current - 1.day }
      it_behaves_like 'ToNG', 'errors.messages.infomation.ended'
    end
    shared_examples_for '[ログイン中/削除予約済み][自分][過去]終了日時が過去' do
      let!(:ended_at) { Time.current - 1.day }
      it_behaves_like 'ToNG', 'errors.messages.infomation.ended'
    end
    shared_examples_for '[*][他人][過去]終了日時が過去' do
      let!(:ended_at) { Time.current - 1.day }
      it_behaves_like 'ToNG', nil
    end
    shared_examples_for '[*][*][未来]終了日時が過去' do # Tips: 不整合
      let!(:ended_at) { Time.current - 1.day }
      it_behaves_like 'ToNG', nil
    end
    shared_examples_for '[*][全員][過去]終了日時が未来' do
      let!(:ended_at) { Time.current + 1.day }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[ログイン中/削除予約済み][自分][過去]終了日時が未来' do
      let!(:ended_at) { Time.current + 1.day }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[*][他人][過去]終了日時が未来' do
      let!(:ended_at) { Time.current + 1.day }
      it_behaves_like 'ToNG', nil
    end
    shared_examples_for '[*][*][未来]終了日時が未来' do
      let!(:ended_at) { Time.current + 1.day }
      it_behaves_like 'ToNG', nil
    end
    shared_examples_for '[*][全員][過去]終了日時がない' do
      let!(:ended_at) { nil }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[ログイン中/削除予約済み][自分][過去]終了日時がない' do
      let!(:ended_at) { nil }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[*][他人][過去]終了日時がない' do
      let!(:ended_at) { nil }
      it_behaves_like 'ToNG', nil
    end
    shared_examples_for '[*][*][未来]終了日時がない' do
      let!(:ended_at) { nil }
      it_behaves_like 'ToNG', nil
    end

    shared_examples_for '[*][全員]開始日時が過去' do
      let!(:started_at) { Time.current - 1.day }
      it_behaves_like '[*][全員][過去]終了日時が過去' # Tips: NG
      it_behaves_like '[*][全員][過去]終了日時が未来'
      it_behaves_like '[*][全員][過去]終了日時がない'
    end
    shared_examples_for '[ログイン中/削除予約済み][自分]開始日時が過去' do
      let!(:started_at) { Time.current - 1.day }
      it_behaves_like '[ログイン中/削除予約済み][自分][過去]終了日時が過去' # Tips: NG
      it_behaves_like '[ログイン中/削除予約済み][自分][過去]終了日時が未来'
      it_behaves_like '[ログイン中/削除予約済み][自分][過去]終了日時がない'
    end
    shared_examples_for '[*][他人]開始日時が過去' do # Tips: NG
      let!(:started_at) { Time.current - 1.day }
      it_behaves_like '[*][他人][過去]終了日時が過去'
      it_behaves_like '[*][他人][過去]終了日時が未来'
      it_behaves_like '[*][他人][過去]終了日時がない'
    end
    shared_examples_for '[*][*]開始日時が未来' do # Tips: NG
      let!(:started_at) { Time.current + 1.day }
      it_behaves_like '[*][*][未来]終了日時が過去'
      it_behaves_like '[*][*][未来]終了日時が未来'
      it_behaves_like '[*][*][未来]終了日時がない'
    end

    shared_examples_for '[*]対象が全員' do
      let!(:target) { :All }
      let!(:user_id) { nil }
      it_behaves_like '[*][全員]開始日時が過去'
      it_behaves_like '[*][*]開始日時が未来' # Tips: NG
    end
    shared_examples_for '[ログイン中/削除予約済み]対象が自分' do
      let!(:target) { :User }
      let!(:user_id) { user.id }
      it_behaves_like '[ログイン中/削除予約済み][自分]開始日時が過去'
      it_behaves_like '[*][*]開始日時が未来' # Tips: NG
    end
    shared_examples_for '[*]対象が他人' do # Tips: NG
      let!(:target) { :User }
      let!(:user_id) { outside_user.id }
      it_behaves_like '[*][他人]開始日時が過去'
      it_behaves_like '[*][*]開始日時が未来'
    end

    context '未ログイン' do
      it_behaves_like '[*]対象が全員'
      # it_behaves_like '[未ログイン]対象が自分' # Tips: 未ログインの為、他人
      it_behaves_like '[*]対象が他人' # Tips: NG
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[*]対象が全員'
      it_behaves_like '[ログイン中/削除予約済み]対象が自分'
      it_behaves_like '[*]対象が他人' # Tips: NG
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[*]対象が全員'
      it_behaves_like '[ログイン中/削除予約済み]対象が自分'
      it_behaves_like '[*]対象が他人' # Tips: NG
    end
  end
end
