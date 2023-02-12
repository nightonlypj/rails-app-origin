require 'rails_helper'

RSpec.describe 'Downloads', type: :request do
  let(:response_json) { response.body.present? ? JSON.parse(response.body) : {} }

  # GET /downloads/create ダウンロード依頼
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）, APIログイン中, APIログイン中（削除予約済み）
  #   model: member（space: 存在する, 存在しない, ない）, 存在しない, ない
  #   権限: ある（管理者）, ない（投稿者, 閲覧者, なし）
  #   ＋URLの拡張子: ない, .json
  #   ＋Acceptヘッダ: HTMLが含まれる, JSONが含まれる
  describe 'GET #new' do
    subject { get new_download_path(format: subject_format), params: params, headers: auth_headers.merge(accept_headers) }
    let_it_be(:space)     { FactoryBot.create(:space) }
    let_it_be(:space_not) { FactoryBot.build_stubbed(:space) }

    shared_context 'valid_condition' do
      let(:params) { { model: 'member', space_code: space.code } }
      include_context 'set_member_power', :admin
    end

    # テスト内容
    shared_examples_for 'ToOK(html/*)' do
      it 'HTTPステータスが200' do
        is_expected.to eq(200)
      end
    end

    # テストケース
    if Settings.api_only_mode
      include_context 'APIログイン処理'
      include_context 'valid_condition'
      it_behaves_like 'ToNG(html)', 406
      it_behaves_like 'ToNG(json)', 406
      next
    end

    shared_examples_for '[ログイン中/削除予約済み][member]権限がある' do |power|
      include_context 'set_member_power', power
      it_behaves_like 'ToOK(html)'
      it_behaves_like 'ToNG(json)', 406
    end
    shared_examples_for '[ログイン中/削除予約済み][member]権限がない' do |power|
      include_context 'set_member_power', power
      it_behaves_like 'ToNG(html)', 403
      it_behaves_like 'ToNG(json)', 406
    end

    shared_examples_for '[ログイン中/削除予約済み]modelがmember（spaceが存在する）' do
      let(:params) { { model: 'member', space_code: space.code } }
      it_behaves_like '[ログイン中/削除予約済み][member]権限がある', :admin
      it_behaves_like '[ログイン中/削除予約済み][member]権限がない', :writer
      it_behaves_like '[ログイン中/削除予約済み][member]権限がない', :reader
      it_behaves_like '[ログイン中/削除予約済み][member]権限がない', nil
    end
    shared_examples_for '[ログイン中/削除予約済み]modelがmember（spaceが存在しない）' do
      let(:params) { { model: 'member', space_code: space_not.code } }
      it_behaves_like 'ToNG(html)', 404
      it_behaves_like 'ToNG(json)', 406
    end
    shared_examples_for '[ログイン中/削除予約済み]modelがmember（spaceがない）' do
      let(:params) { { model: 'member', space_code: nil } }
      it_behaves_like 'ToNG(html)', 404
      it_behaves_like 'ToNG(json)', 406
    end
    shared_examples_for '[ログイン中/削除予約済み]modelが存在しない' do
      let(:params) { { model: 'xxx' } }
      it_behaves_like 'ToNG(html)', 404
      it_behaves_like 'ToNG(json)', 406
    end
    shared_examples_for '[ログイン中/削除予約済み]modelがない' do
      let(:params) { { model: nil } }
      it_behaves_like 'ToNG(html)', 404
      it_behaves_like 'ToNG(json)', 406
    end

    shared_examples_for '[ログイン中/削除予約済み]' do
      it_behaves_like '[ログイン中/削除予約済み]modelがmember（spaceが存在する）'
      it_behaves_like '[ログイン中/削除予約済み]modelがmember（spaceが存在しない）'
      it_behaves_like '[ログイン中/削除予約済み]modelがmember（spaceがない）'
      it_behaves_like '[ログイン中/削除予約済み]modelが存在しない'
      it_behaves_like '[ログイン中/削除予約済み]modelがない'
    end
    shared_examples_for '[APIログイン中/削除予約済み]' do
      include_context 'valid_condition'
      it_behaves_like 'ToOK(html)' # NOTE: HTMLもログイン状態になる
      it_behaves_like 'ToNG(json)', 406
    end

    context '未ログイン' do
      include_context '未ログイン処理'
      include_context 'valid_condition'
      it_behaves_like 'ToLogin(html)'
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
