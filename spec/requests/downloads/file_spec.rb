require 'rails_helper'

RSpec.describe 'Downloads', type: :request do
  let(:response_json) { JSON.parse(response.body) }

  # GET /downloads/file/:id ダウンロード
  # GET /downloads/file/:id(.json) ダウンロードAPI
  # 前提条件
  #   モデルがメンバー(model=member)
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）, APIログイン中, APIログイン中（削除予約済み）
  #   ID: 存在する（状態: 成功, 成功以外（処理待ち, 処理中, 成功, 失敗））, 存在しない
  #   依頼ユーザー: ログインユーザー, その他ユーザー
  #   権限: ある（管理者）, ない（投稿者, 閲覧者, なし）
  #   ＋URLの拡張子: ない, .json
  #   ＋Acceptヘッダ: HTMLが含まれる, JSONが含まれる
  describe 'GET #file' do
    subject { get file_download_path(id: download.id, format: subject_format), headers: auth_headers.merge(accept_headers) }
    let_it_be(:space)      { FactoryBot.create(:space) }
    let_it_be(:other_user) { FactoryBot.create(:user) }

    shared_context 'user_condition' do |status = :success|
      let_it_be(:download)      { FactoryBot.create(:download, status, user:, space:) }
      let_it_be(:download_file) { FactoryBot.create(:download_file, download:) }
    end
    shared_context 'other_user_condition' do |status = :success|
      let_it_be(:download)      { FactoryBot.create(:download, status, user: other_user, space:) }
      let_it_be(:download_file) { FactoryBot.create(:download_file, download:) }
    end

    # テスト内容
    shared_examples_for 'ToOK(html/*)' do
      it 'HTTPステータスが200。対象項目が含まれる' do
        is_expected.to eq(200)
        filename = "#{download.model}_#{I18n.l(download.requested_at, format: :file)}.#{download.format}"
        expect(response.header['Content-Disposition']).to eq("attachment; filename=\"#{filename}\"; filename*=UTF-8''#{filename}")
        expect(response.body).to eq(download_file.body)
      end
    end
    shared_examples_for 'ToOK(json/json)' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it_behaves_like 'ToOK(html/*)'
    end

    # テストケース
    shared_examples_for '[ログイン中/削除予約済み][成功][ログインユーザー]権限がある' do |power|
      before_all { FactoryBot.create(:member, power, space:, user:) }
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToOK(html)'
      end
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中/削除予約済み][成功][ログインユーザー]権限がある' do |power|
      before_all { FactoryBot.create(:member, power, space:, user:) }
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToOK(html)' # NOTE: HTMLもログイン状態になる
      end
      it_behaves_like 'ToOK(json)'
    end
    shared_examples_for '[ログイン中/削除予約済み][成功][ログインユーザー]権限がない' do |power|
      before_all { FactoryBot.create(:member, power, space:, user:) if power.present? }
      it_behaves_like 'ToNG(html)', Settings.api_only_mode ? 406 : 403
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中/削除予約済み][成功][ログインユーザー]権限がない' do |power|
      before_all { FactoryBot.create(:member, power, space:, user:) if power.present? }
      it_behaves_like 'ToNG(html)', Settings.api_only_mode ? 406 : 403 # NOTE: HTMLもログイン状態になる
      it_behaves_like 'ToNG(json)', 403
    end
    shared_examples_for '[ログイン中/削除予約済み][成功][その他ユーザー]権限がない' do
      it_behaves_like 'ToNG(html)', Settings.api_only_mode ? 406 : 404
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中/削除予約済み][成功][その他ユーザー]権限がない' do
      it_behaves_like 'ToNG(html)', Settings.api_only_mode ? 406 : 404
      it_behaves_like 'ToNG(json)', 404, nil, 'alert.download.notfound'
    end

    shared_examples_for '[ログイン中/削除予約済み][成功]依頼ユーザーがログインユーザー' do |status|
      include_context 'user_condition', status
      it_behaves_like '[ログイン中/削除予約済み][成功][ログインユーザー]権限がある', :admin
      it_behaves_like '[ログイン中/削除予約済み][成功][ログインユーザー]権限がない', :writer
      it_behaves_like '[ログイン中/削除予約済み][成功][ログインユーザー]権限がない', :reader
      it_behaves_like '[ログイン中/削除予約済み][成功][ログインユーザー]権限がない', nil
    end
    shared_examples_for '[APIログイン中/削除予約済み][成功]依頼ユーザーがログインユーザー' do |status|
      include_context 'user_condition', status
      it_behaves_like '[APIログイン中/削除予約済み][成功][ログインユーザー]権限がある', :admin
      it_behaves_like '[APIログイン中/削除予約済み][成功][ログインユーザー]権限がない', :writer
      it_behaves_like '[APIログイン中/削除予約済み][成功][ログインユーザー]権限がない', :reader
      it_behaves_like '[APIログイン中/削除予約済み][成功][ログインユーザー]権限がない', nil
    end
    shared_examples_for '[ログイン中/削除予約済み][成功]依頼ユーザーがその他ユーザー' do |status|
      include_context 'other_user_condition', status
      # it_behaves_like '[ログイン中/削除予約済み][成功][その他ユーザー]権限がある', :admin # NOTE: その他ユーザーの場合は権限がない
      # it_behaves_like '[ログイン中/削除予約済み][成功][その他ユーザー]権限がない', :writer
      # it_behaves_like '[ログイン中/削除予約済み][成功][その他ユーザー]権限がない', :reader
      it_behaves_like '[ログイン中/削除予約済み][成功][その他ユーザー]権限がない'
    end
    shared_examples_for '[APIログイン中/削除予約済み][成功]依頼ユーザーがその他ユーザー' do |status|
      include_context 'other_user_condition', status
      # it_behaves_like '[APIログイン中/削除予約済み][成功][その他ユーザー]権限がある', :admin # NOTE: その他ユーザーの場合は権限がない
      # it_behaves_like '[APIログイン中/削除予約済み][成功][その他ユーザー]権限がない', :writer
      # it_behaves_like '[APIログイン中/削除予約済み][成功][その他ユーザー]権限がない', :reader
      it_behaves_like '[APIログイン中/削除予約済み][成功][その他ユーザー]権限がない'
    end

    shared_examples_for '[ログイン中/削除予約済み]IDが存在する（状態が成功）' do |status|
      it_behaves_like '[ログイン中/削除予約済み][成功]依頼ユーザーがログインユーザー', status
      it_behaves_like '[ログイン中/削除予約済み][成功]依頼ユーザーがその他ユーザー', status
    end
    shared_examples_for '[APIログイン中/削除予約済み]IDが存在する（状態が成功）' do |status|
      it_behaves_like '[APIログイン中/削除予約済み][成功]依頼ユーザーがログインユーザー', status
      it_behaves_like '[APIログイン中/削除予約済み][成功]依頼ユーザーがその他ユーザー', status
    end
    shared_examples_for '[ログイン中/削除予約済み]IDが存在する（状態が成功以外）' do |status|
      include_context 'user_condition', status
      before_all { FactoryBot.create(:member, space:, user:) }
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToOK(html)'
      end
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中/削除予約済み]IDが存在する（状態が成功以外）' do |status|
      include_context 'user_condition', status
      before_all { FactoryBot.create(:member, space:, user:) }
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToOK(html)' # NOTE: HTMLもログイン状態になる
      end
      it_behaves_like 'ToOK(json)'
    end
    shared_examples_for '[ログイン中/削除予約済み]IDが存在しない' do
      let_it_be(:download) { FactoryBot.build_stubbed(:download) }
      it_behaves_like 'ToNG(html)', Settings.api_only_mode ? 406 : 404
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中/削除予約済み]IDが存在しない' do
      let_it_be(:download) { FactoryBot.build_stubbed(:download) }
      it_behaves_like 'ToNG(html)', Settings.api_only_mode ? 406 : 404
      it_behaves_like 'ToNG(json)', 404, nil, 'alert.download.notfound'
    end

    shared_examples_for '[ログイン中/削除予約済み]' do
      it_behaves_like '[ログイン中/削除予約済み]IDが存在する（状態が成功）', :success
      it_behaves_like '[ログイン中/削除予約済み]IDが存在する（状態が成功以外）', :waiting
      it_behaves_like '[ログイン中/削除予約済み]IDが存在する（状態が成功以外）', :processing
      it_behaves_like '[ログイン中/削除予約済み]IDが存在する（状態が成功以外）', :failure
      it_behaves_like '[ログイン中/削除予約済み]IDが存在しない'
    end
    shared_examples_for '[APIログイン中/削除予約済み]' do
      it_behaves_like '[APIログイン中/削除予約済み]IDが存在する（状態が成功）', :success
      it_behaves_like '[APIログイン中/削除予約済み]IDが存在する（状態が成功以外）', :waiting
      it_behaves_like '[APIログイン中/削除予約済み]IDが存在する（状態が成功以外）', :processing
      it_behaves_like '[APIログイン中/削除予約済み]IDが存在する（状態が成功以外）', :failure
      it_behaves_like '[APIログイン中/削除予約済み]IDが存在しない'
    end

    context '未ログイン' do
      include_context '未ログイン処理'
      include_context 'other_user_condition'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToLogin(html)'
      end
      it_behaves_like 'ToNG(json)', 401
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
