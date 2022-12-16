require 'rails_helper'

RSpec.describe 'Downloads', type: :request do
  let(:response_json) { JSON.parse(response.body) }

  # GET /downloads/file/:id ダウンロード
  # GET /downloads/file/:id(.json) ダウンロードAPI
  # 前提条件
  #   モデルがメンバー(model=member)
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）, APIログイン中, APIログイン中（削除予約済み）
  #   ID: 存在しない, 存在する
  #   依頼ユーザー: ログインユーザー, その他ユーザー
  #   権限: ある（管理者）, ない（投稿者, 閲覧者, なし）
  #   ＋URLの拡張子: ない, .json
  #   ＋Acceptヘッダ: HTMLが含まれる, JSONが含まれる
  # TODO: 状態: 処理待ち, 処理中, 成功, 失敗
  describe 'GET #file' do
    subject { get file_download_path(id: download.id, format: subject_format), headers: auth_headers.merge(accept_headers) }

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
    shared_examples_for '[ログイン中/削除予約済み][存在する][ログインユーザー]権限がある' do |power|
      let_it_be(:user_power) { power }
      before_all { FactoryBot.create(:member, power: power, space: download.space, user: user) }
      it_behaves_like 'ToOK(html)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中/削除予約済み][存在する][ログインユーザー]権限がある' do |power|
      let_it_be(:user_power) { power }
      before_all { FactoryBot.create(:member, power: power, space: download.space, user: user) }
      it_behaves_like 'ToOK(html)' # NOTE: HTMLもログイン状態になる
      it_behaves_like 'ToOK(json)'
    end
    shared_examples_for '[ログイン中/削除予約済み][存在する][ログインユーザー]権限がない' do |power|
      before_all { FactoryBot.create(:member, power: power, space: download.space, user: user) if power.present? }
      it_behaves_like 'ToNG(html)', 403
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中/削除予約済み][存在する][ログインユーザー]権限がない' do |power|
      before_all { FactoryBot.create(:member, power: power, space: download.space, user: user) if power.present? }
      it_behaves_like 'ToNG(html)', 403 # NOTE: HTMLもログイン状態になる
      it_behaves_like 'ToNG(json)', 403
    end
    shared_examples_for '[ログイン中/削除予約済み][存在する][その他ユーザー]権限がない' do
      it_behaves_like 'ToNG(html)', 404
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中/削除予約済み][存在する][その他ユーザー]権限がない' do
      it_behaves_like 'ToNG(html)', 404
      it_behaves_like 'ToNG(json)', 404, nil, 'alert.download.notfound'
    end

    shared_examples_for '[ログイン中/削除予約済み][存在する]依頼ユーザーがログインユーザー' do
      let_it_be(:download)      { FactoryBot.create(:download, :member, :success, user: user) }
      let_it_be(:download_file) { FactoryBot.create(:download_file, download: download) }
      it_behaves_like '[ログイン中/削除予約済み][存在する][ログインユーザー]権限がある', :admin
      it_behaves_like '[ログイン中/削除予約済み][存在する][ログインユーザー]権限がない', :writer
      it_behaves_like '[ログイン中/削除予約済み][存在する][ログインユーザー]権限がない', :reader
      it_behaves_like '[ログイン中/削除予約済み][存在する][ログインユーザー]権限がない', nil
    end
    shared_examples_for '[APIログイン中/削除予約済み][存在する]依頼ユーザーがログインユーザー' do
      let_it_be(:download)      { FactoryBot.create(:download, :member, :success, user: user) }
      let_it_be(:download_file) { FactoryBot.create(:download_file, download: download) }
      it_behaves_like '[APIログイン中/削除予約済み][存在する][ログインユーザー]権限がある', :admin
      it_behaves_like '[APIログイン中/削除予約済み][存在する][ログインユーザー]権限がない', :writer
      it_behaves_like '[APIログイン中/削除予約済み][存在する][ログインユーザー]権限がない', :reader
      it_behaves_like '[APIログイン中/削除予約済み][存在する][ログインユーザー]権限がない', nil
    end
    shared_examples_for '[ログイン中/削除予約済み][存在する]依頼ユーザーがその他ユーザー' do
      let_it_be(:download) { FactoryBot.create(:download, :member, :success) }
      # it_behaves_like '[ログイン中/削除予約済み][存在する][その他ユーザー]権限がある', :admin # NOTE: その他ユーザーの場合は権限がない
      # it_behaves_like '[ログイン中/削除予約済み][存在する][その他ユーザー]権限がない', :writer
      # it_behaves_like '[ログイン中/削除予約済み][存在する][その他ユーザー]権限がない', :reader
      it_behaves_like '[ログイン中/削除予約済み][存在する][その他ユーザー]権限がない'
    end
    shared_examples_for '[APIログイン中/削除予約済み][存在する]依頼ユーザーがその他ユーザー' do
      let_it_be(:download) { FactoryBot.create(:download, :member, :success) }
      # it_behaves_like '[APIログイン中/削除予約済み][存在する][その他ユーザー]権限がある', :admin # NOTE: その他ユーザーの場合は権限がない
      # it_behaves_like '[APIログイン中/削除予約済み][存在する][その他ユーザー]権限がない', :writer
      # it_behaves_like '[APIログイン中/削除予約済み][存在する][その他ユーザー]権限がない', :reader
      it_behaves_like '[APIログイン中/削除予約済み][存在する][その他ユーザー]権限がない'
    end

    shared_examples_for '[未ログイン]IDが存在しない' do
      let_it_be(:download) { FactoryBot.build_stubbed(:download) }
      it_behaves_like 'ToLogin(html)'
      it_behaves_like 'ToNG(json)', 401
    end
    shared_examples_for '[ログイン中/削除予約済み]IDが存在しない' do
      let_it_be(:download) { FactoryBot.build_stubbed(:download) }
      it_behaves_like 'ToNG(html)', 404
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中/削除予約済み]IDが存在しない' do
      let_it_be(:download) { FactoryBot.build_stubbed(:download) }
      it_behaves_like 'ToNG(html)', 404
      it_behaves_like 'ToNG(json)', 404, nil, 'alert.download.notfound'
    end
    shared_examples_for '[未ログイン]IDが存在する' do
      let_it_be(:download) { FactoryBot.create(:download, :success) }
      it_behaves_like 'ToLogin(html)'
      it_behaves_like 'ToNG(json)', 401
    end
    shared_examples_for '[ログイン中/削除予約済み]IDが存在する' do
      it_behaves_like '[ログイン中/削除予約済み][存在する]依頼ユーザーがログインユーザー'
      it_behaves_like '[ログイン中/削除予約済み][存在する]依頼ユーザーがその他ユーザー'
    end
    shared_examples_for '[APIログイン中/削除予約済み]IDが存在する' do
      it_behaves_like '[APIログイン中/削除予約済み][存在する]依頼ユーザーがログインユーザー'
      it_behaves_like '[APIログイン中/削除予約済み][存在する]依頼ユーザーがその他ユーザー'
    end

    context '未ログイン' do
      include_context '未ログイン処理'
      it_behaves_like '[未ログイン]IDが存在しない'
      it_behaves_like '[未ログイン]IDが存在する'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中/削除予約済み]IDが存在しない'
      it_behaves_like '[ログイン中/削除予約済み]IDが存在する'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', :destroy_reserved
      it_behaves_like '[ログイン中/削除予約済み]IDが存在しない'
      it_behaves_like '[ログイン中/削除予約済み]IDが存在する'
    end
    context 'APIログイン中' do
      include_context 'APIログイン処理'
      it_behaves_like '[APIログイン中/削除予約済み]IDが存在しない'
      it_behaves_like '[APIログイン中/削除予約済み]IDが存在する'
    end
    context 'APIログイン中（削除予約済み）' do
      include_context 'APIログイン処理', :destroy_reserved
      it_behaves_like '[APIログイン中/削除予約済み]IDが存在しない'
      it_behaves_like '[APIログイン中/削除予約済み]IDが存在する'
    end
  end
end
