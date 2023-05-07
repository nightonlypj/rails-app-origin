require 'rails_helper'

RSpec.describe 'Spaces', type: :request do
  let(:response_json) { JSON.parse(response.body) }
  let(:response_json_space) { response_json['space'] }

  # POST /spaces/delete/:code スペース削除(処理)
  # POST /spaces/delete/:code(.json) スペース削除API(処理)
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）, APIログイン中, APIログイン中（削除予約済み）
  #   スペース: 存在しない, 公開, 非公開
  #   削除予約: ある, ない
  #   権限: ある（管理者）, ない（投稿者, 閲覧者, なし）
  #   ＋URLの拡張子: ない, .json
  #   ＋Acceptヘッダ: HTMLが含まれる, JSONが含まれる
  describe 'POST #destroy' do
    subject { post destroy_space_path(code: space.code, format: subject_format), headers: auth_headers.merge(accept_headers) }
    let(:current_space) { Space.last }

    let_it_be(:space_not)    { FactoryBot.build_stubbed(:space) }
    let_it_be(:space_public) { FactoryBot.create(:space, :public) }
    shared_context 'valid_condition' do
      let_it_be(:space) { space_public }
      include_context 'set_member_power', :admin
    end

    # テスト内容
    shared_examples_for 'OK' do
      let!(:start_time) { Time.current.floor }
      it "削除依頼日時が現在日時に、削除予定日時が#{Settings.space_destroy_schedule_days}日後に変更される" do
        subject
        expect(current_space.destroy_requested_at).to be_between(start_time, Time.current)
        expect(current_space.destroy_schedule_at).to be_between(start_time + Settings.space_destroy_schedule_days.days,
                                                                Time.current + Settings.space_destroy_schedule_days.days)
      end
    end
    shared_examples_for 'NG' do
      it '変更されない' do
        subject
        expect(current_space).to eq(space)
      end
    end

    shared_examples_for 'ToOK(html/*)' do
      it '削除したスペースにリダイレクトする' do
        is_expected.to redirect_to(space_path(space.code))
        expect(flash[:alert]).to be_nil
        expect(flash[:notice]).to eq(get_locale('notice.space.destroy'))
      end
    end
    shared_examples_for 'ToOK(json/json)' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it 'HTTPステータスが200。対象項目が一致する' do
        is_expected.to eq(200)
        expect(response_json['success']).to eq(true)
        expect(response_json['notice']).to eq(get_locale('notice.space.destroy'))

        count = expect_space_json(response_json_space, current_space, :admin, 1)
        expect(response_json_space.count).to eq(count)

        expect(response_json.count).to eq(3)
      end
    end

    # テストケース
    shared_examples_for '[ログイン中][*][ない]権限がある' do |power|
      include_context 'set_member_power', power
      if Settings.api_only_mode
        it_behaves_like 'NG(html)'
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'OK(html)'
        it_behaves_like 'ToOK(html)'
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中][*][ない]権限がある' do |power|
      include_context 'set_member_power', power
      if Settings.api_only_mode
        it_behaves_like 'NG(html)'
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'OK(html)'
        it_behaves_like 'ToOK(html)' # NOTE: HTMLもログイン状態になる
      end
      it_behaves_like 'OK(json)'
      it_behaves_like 'ToOK(json)'
    end
    shared_examples_for '[ログイン中][*][ない]権限がない' do |power|
      include_context 'set_member_power', power
      it_behaves_like 'NG(html)'
      it_behaves_like 'ToNG(html)', Settings.api_only_mode ? 406 : 403
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中][*][ない]権限がない' do |power|
      include_context 'set_member_power', power
      it_behaves_like 'NG(html)'
      it_behaves_like 'ToNG(html)', Settings.api_only_mode ? 406 : 403 # NOTE: HTMLもログイン状態になる
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 403
    end

    shared_examples_for '[ログイン中][*]削除予約がある' do |private|
      let_it_be(:space) { FactoryBot.create(:space, :destroy_reserved, private: private) }
      include_context 'set_member_power', :admin
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToSpace(html)', 'alert.space.destroy_reserved'
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中][*]削除予約がある' do |private|
      let_it_be(:space) { FactoryBot.create(:space, :destroy_reserved, private: private) }
      include_context 'set_member_power', :admin
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToSpace(html)', 'alert.space.destroy_reserved' # NOTE: HTMLもログイン状態になる
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 422, nil, 'alert.space.destroy_reserved'
    end
    shared_examples_for '[ログイン中][*]削除予約がない' do |private|
      let_it_be(:space) { FactoryBot.create(:space, private: private) }
      it_behaves_like '[ログイン中][*][ない]権限がある', :admin
      it_behaves_like '[ログイン中][*][ない]権限がない', :writer
      it_behaves_like '[ログイン中][*][ない]権限がない', :reader
      it_behaves_like '[ログイン中][*][ない]権限がない', nil
    end
    shared_examples_for '[APIログイン中][*]削除予約がない' do |private|
      let_it_be(:space) { FactoryBot.create(:space, private: private) }
      it_behaves_like '[APIログイン中][*][ない]権限がある', :admin
      it_behaves_like '[APIログイン中][*][ない]権限がない', :writer
      it_behaves_like '[APIログイン中][*][ない]権限がない', :reader
      it_behaves_like '[APIログイン中][*][ない]権限がない', nil
    end

    shared_examples_for '[ログイン中]スペースが存在しない' do
      let_it_be(:space) { space_not }
      let(:attributes) { valid_attributes }
      # it_behaves_like 'NG(html)' # NOTE: 存在しない為
      it_behaves_like 'ToNG(html)', Settings.api_only_mode ? 406 : 404
      # it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中]スペースが存在しない' do
      let_it_be(:space) { space_not }
      let(:attributes) { valid_attributes }
      # it_behaves_like 'NG(html)' # NOTE: 存在しない為
      it_behaves_like 'ToNG(html)', Settings.api_only_mode ? 406 : 404 # NOTE: HTMLもログイン状態になる
      # it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 404
    end
    shared_examples_for '[ログイン中]スペースが公開' do
      it_behaves_like '[ログイン中][*]削除予約がある', false
      it_behaves_like '[ログイン中][*]削除予約がない', false
    end
    shared_examples_for '[APIログイン中]スペースが公開' do
      it_behaves_like '[APIログイン中][*]削除予約がある', false
      it_behaves_like '[APIログイン中][*]削除予約がない', false
    end
    shared_examples_for '[ログイン中]スペースが非公開' do
      it_behaves_like '[ログイン中][*]削除予約がある', true
      it_behaves_like '[ログイン中][*]削除予約がない', true
    end
    shared_examples_for '[APIログイン中]スペースが非公開' do
      it_behaves_like '[APIログイン中][*]削除予約がある', true
      it_behaves_like '[APIログイン中][*]削除予約がない', true
    end

    context '未ログイン' do
      include_context '未ログイン処理'
      include_context 'valid_condition'
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToLogin(html)'
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 401
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中]スペースが存在しない'
      it_behaves_like '[ログイン中]スペースが公開'
      it_behaves_like '[ログイン中]スペースが非公開'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', :destroy_reserved
      include_context 'valid_condition'
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToSpace(html)', 'alert.user.destroy_reserved'
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    context 'APIログイン中' do
      include_context 'APIログイン処理'
      it_behaves_like '[APIログイン中]スペースが存在しない'
      it_behaves_like '[APIログイン中]スペースが公開'
      it_behaves_like '[APIログイン中]スペースが非公開'
    end
    context 'APIログイン中（削除予約済み）' do
      include_context 'APIログイン処理', :destroy_reserved
      include_context 'valid_condition'
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToSpace(html)', 'alert.user.destroy_reserved' # NOTE: HTMLもログイン状態になる
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 422, nil, 'alert.user.destroy_reserved'
    end
  end
end
