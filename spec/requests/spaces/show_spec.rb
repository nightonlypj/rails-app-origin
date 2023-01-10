require 'rails_helper'

RSpec.describe 'Spaces', type: :request do
  let(:response_json) { response.body.present? ? JSON.parse(response.body) : {} }

  # GET /s/:code スペーストップ
  # GET /s/:code(.json) スペース詳細API
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）, APIログイン中, APIログイン中（削除予約済み）
  #   スペース: 存在しない, 公開, 非公開
  #   権限: ある（管理者, 投稿者, 閲覧者）, ない,
  #   ＋URLの拡張子: ない, .json
  #   ＋Acceptヘッダ: HTMLが含まれる, JSONが含まれる
  describe 'GET #index' do
    subject { get space_path(code: space.code, format: subject_format), headers: auth_headers.merge(accept_headers) }

    shared_context 'set_power' do |power|
      let(:user_power) { power }
      before_all { FactoryBot.create(:member, power, space: space, user: user) if power.present? && user.present? }
    end

    # テスト内容
    shared_examples_for 'ToOK(html/*)' do
      it 'HTTPステータスが200。対象項目が含まれる' do
        is_expected.to eq(200)
        expect_space_html(response, space, user_power, false)
        if user_power.present?
          expect(response.body).to include("href=\"#{members_path(space.code)}\"") # メンバー一覧
        else
          expect(response.body).not_to include("href=\"#{members_path(space.code)}\"")
        end
        if user_power == :admin
          expect(response.body).to include("href=\"#{edit_space_path(space.code)}\"") # スペース設定変更
        else
          expect(response.body).not_to include("href=\"#{edit_space_path(space.code)}\"")
        end
        expect(response.body).to include(space.description) # 説明
      end
    end
    shared_examples_for 'ToOK(json/json)' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it 'HTTPステータスが200。対象項目が一致する' do
        is_expected.to eq(200)
        expect(response_json['success']).to eq(true)
        expect(response_json['alert']).to be_nil
        expect(response_json['notice']).to be_nil
        expect_space_json(response_json['space'], space, user_power, member_count)
      end
    end

    # テストケース
    shared_examples_for '[ログイン中/削除予約済み][公開]権限がある(html)' do |power|
      include_context 'set_power', power
      it_behaves_like 'ToOK(html)'
    end
    shared_examples_for '[ログイン中/削除予約済み][公開]権限がある(json)' do |power|
      let(:user_power) { nil } # NOTE: APIは未ログイン扱い
      before_all { FactoryBot.create(:member, power, space: space, user: user) }
      let(:member_count) { 1 }
      it_behaves_like 'ToOK(json)' # NOTE: 公開スペースは見れる
    end
    shared_examples_for '[ログイン中/削除予約済み][非公開]権限がある' do |power|
      include_context 'set_power', power
      it_behaves_like 'ToOK(html)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中/削除予約済み][*]権限がある' do |power|
      include_context 'set_power', power
      let(:member_count) { 1 }
      it_behaves_like 'ToOK(html)' # NOTE: HTMLもログイン状態になる
      it_behaves_like 'ToOK(json)'
    end
    shared_examples_for '[*][公開]権限がない' do
      let(:user_power) { nil }
      let(:member_count) { 0 }
      it_behaves_like 'ToOK(html)'
      it_behaves_like 'ToOK(json)'
    end
    shared_examples_for '[未ログイン][非公開]権限がない' do
      it_behaves_like 'ToLogin(html)'
      it_behaves_like 'ToNG(json)', 401
    end
    shared_examples_for '[ログイン中/削除予約済み][非公開]権限がない' do
      it_behaves_like 'ToNG(html)', 403
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中/削除予約済み][非公開]権限がない' do
      it_behaves_like 'ToNG(html)', 403 # NOTE: HTMLもログイン状態になる
      it_behaves_like 'ToNG(json)', 403
    end

    shared_examples_for '[*]スペースが存在しない' do
      let_it_be(:space) { FactoryBot.build_stubbed(:space) }
      it_behaves_like 'ToNG(html)', 404
      it_behaves_like 'ToNG(json)', 404
    end
    shared_examples_for '[未ログイン]スペースが公開' do
      let_it_be(:space) { FactoryBot.create(:space, :public) }
      # it_behaves_like '[未ログイン][公開]権限がある', :admin # NOTE: 未ログインの為、権限がない
      # it_behaves_like '[未ログイン][公開]権限がある', :writer
      # it_behaves_like '[未ログイン][公開]権限がある', :reader
      it_behaves_like '[*][公開]権限がない'
    end
    shared_examples_for '[ログイン中/削除予約済み]スペースが公開' do
      let_it_be(:space) { FactoryBot.create(:space, :public) }
      it_behaves_like '[ログイン中/削除予約済み][公開]権限がある(html)', :admin
      it_behaves_like '[ログイン中/削除予約済み][公開]権限がある(json)', :admin
      it_behaves_like '[ログイン中/削除予約済み][公開]権限がある(html)', :writer
      it_behaves_like '[ログイン中/削除予約済み][公開]権限がある(json)', :writer
      it_behaves_like '[ログイン中/削除予約済み][公開]権限がある(html)', :reader
      it_behaves_like '[ログイン中/削除予約済み][公開]権限がある(json)', :reader
      it_behaves_like '[*][公開]権限がない'
    end
    shared_examples_for '[APIログイン中/削除予約済み]スペースが公開' do
      let_it_be(:space) { FactoryBot.create(:space, :public) }
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がある', :admin
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がある', :writer
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がある', :reader
      it_behaves_like '[*][公開]権限がない'
    end
    shared_examples_for '[未ログイン]スペースが非公開' do
      let_it_be(:space) { FactoryBot.create(:space, :private) }
      # it_behaves_like '[未ログイン][非公開]権限がある', :admin # NOTE: 未ログインの為、権限がない
      # it_behaves_like '[未ログイン][非公開]権限がある', :writer
      # it_behaves_like '[未ログイン][非公開]権限がある', :reader
      it_behaves_like '[未ログイン][非公開]権限がない'
    end
    shared_examples_for '[ログイン中/削除予約済み]スペースが非公開' do
      let_it_be(:space) { FactoryBot.create(:space, :private, created_user: user) }
      it_behaves_like '[ログイン中/削除予約済み][非公開]権限がある', :admin
      it_behaves_like '[ログイン中/削除予約済み][非公開]権限がある', :writer
      it_behaves_like '[ログイン中/削除予約済み][非公開]権限がある', :reader
      it_behaves_like '[ログイン中/削除予約済み][非公開]権限がない'
    end
    shared_examples_for '[APIログイン中/削除予約済み]スペースが非公開' do
      let_it_be(:space) { FactoryBot.create(:space, :private, created_user: user, last_updated_user: user) }
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がある', :admin
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がある', :writer
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がある', :reader
      it_behaves_like '[APIログイン中/削除予約済み][非公開]権限がない'
    end

    shared_examples_for '[ログイン中/削除予約済み]' do
      it_behaves_like '[*]スペースが存在しない'
      it_behaves_like '[ログイン中/削除予約済み]スペースが公開'
      it_behaves_like '[ログイン中/削除予約済み]スペースが非公開'
    end
    shared_examples_for '[APIログイン中/削除予約済み]' do
      it_behaves_like '[*]スペースが存在しない'
      it_behaves_like '[APIログイン中/削除予約済み]スペースが公開'
      it_behaves_like '[APIログイン中/削除予約済み]スペースが非公開'
    end

    context '未ログイン' do
      include_context '未ログイン処理'
      it_behaves_like '[*]スペースが存在しない'
      it_behaves_like '[未ログイン]スペースが公開'
      it_behaves_like '[未ログイン]スペースが非公開'
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
