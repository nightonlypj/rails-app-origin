require 'rails_helper'

RSpec.describe 'Spaces', type: :request do
  let(:response_json) { response.body.present? ? JSON.parse(response.body) : {} }
  let(:response_json_space)           { response_json['space'] }
  let(:response_json_space_image_url) { response_json['space']['image_url'] }

  # GET /s/:code スペーストップ
  # GET /s/:code(.json) スペース詳細API
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）, APIログイン中, APIログイン中（削除予約済み）
  #   スペース: 存在しない, 公開, 非公開
  #   権限: ない, ある（管理者, 投稿者, 閲覧者）
  #   ＋URLの拡張子: ない, .json
  #   ＋Acceptヘッダ: HTMLが含まれる, JSONが含まれる
  describe 'GET #index' do
    subject { get space_path(code: space.code, format: subject_format), headers: auth_headers.merge(accept_headers) }

    # テスト内容
    shared_examples_for 'ToOK(html/*)' do
      it 'HTTPステータスが200。対象項目が含まれる' do
        is_expected.to eq(200)
        expect(response.body).to include(space.image_url(:small)) # 画像
        expect(response.body).to include(space.name) # 名称
        expect(response.body).to include('非公開') if space.private # 非公開
        expect(response.body).to include(I18n.l(space.destroy_schedule_at.to_date)) if space.destroy_reserved? # 削除予定日時
        expect(response.body).to include(Member.powers_i18n[user_power]) if user_power.present? # 権限
        if user_power.present?
          expect(response.body).to include("href=\"#{members_path(space.code)}\"") # メンバー一覧
        else
          expect(response.body).not_to include("href=\"#{members_path(space.code)}\"")
        end
        if user_power == :admin
          expect(response.body).to include("href=\"#{edit_space_path(space.code)}\"") # スペース情報変更
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
        expect(response_json_space['code']).to eq(space.code)
        expect(response_json_space_image_url['mini']).to eq("#{Settings['base_image_url']}#{space.image_url(:mini)}")
        expect(response_json_space_image_url['small']).to eq("#{Settings['base_image_url']}#{space.image_url(:small)}")
        expect(response_json_space_image_url['medium']).to eq("#{Settings['base_image_url']}#{space.image_url(:medium)}")
        expect(response_json_space_image_url['large']).to eq("#{Settings['base_image_url']}#{space.image_url(:large)}")
        expect(response_json_space_image_url['xlarge']).to eq("#{Settings['base_image_url']}#{space.image_url(:xlarge)}")
        expect(response_json_space['name']).to eq(space.name)
        expect(response_json_space['description']).to eq(space.description)
        expect(response_json_space['private']).to eq(space.private)
        expect(response_json_space['destroy_requested_at']).to eq(I18n.l(space.destroy_requested_at, format: :json, default: nil))
        expect(response_json_space['destroy_schedule_at']).to eq(I18n.l(space.destroy_schedule_at, format: :json, default: nil))
        if user_power.blank?
          expect(response_json_space['current_member']).to be_nil
        else
          expect(response_json_space['current_member']['power']).to eq(user_power.to_s)
          expect(response_json_space['current_member']['power_i18n']).to eq(Member.powers_i18n[user_power])
        end

        expect(response_json_space['member_count']).to eq(member_count) # メンバー数
      end
    end

    # テストケース
    shared_examples_for '[*][公開]権限がない' do
      let(:user_power) { nil }
      let(:member_count) { 0 }
      it_behaves_like 'ToOK(html)'
      it_behaves_like 'ToOK(json)'
    end
    shared_examples_for '[未ログイン][非公開]権限がない' do
      it_behaves_like 'ToLogin(html/html)'
      it_behaves_like 'ToLogin(html/json)'
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
    shared_examples_for '[ログイン中/削除予約済み][公開]権限がある(html)' do |power|
      let(:user_power) { power }
      let(:member_count) { 1 }
      before_all { FactoryBot.create(:member, power: power, space: space, user: user) }
      it_behaves_like 'ToOK(html)'
    end
    shared_examples_for '[ログイン中/削除予約済み][公開]権限がある(json)' do |power|
      let(:user_power) { nil }
      let(:member_count) { 1 }
      before_all { FactoryBot.create(:member, power: power, space: space, user: user) }
      it_behaves_like 'ToOK(json)' # NOTE: APIは未ログイン扱いだが、スペースが公開は見れる
    end
    shared_examples_for '[ログイン中/削除予約済み][非公開]権限がある' do |power|
      let(:user_power) { power }
      before_all { FactoryBot.create(:member, power: power, space: space, user: user) }
      it_behaves_like 'ToOK(html)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中/削除予約済み][*]権限がある' do |power|
      let(:user_power) { power }
      let(:member_count) { 1 }
      before_all { FactoryBot.create(:member, power: power, space: space, user: user) }
      it_behaves_like 'ToOK(html)' # NOTE: HTMLもログイン状態になる
      it_behaves_like 'ToOK(json)'
    end

    shared_examples_for '[*]スペースが存在しない' do
      let_it_be(:space) { FactoryBot.build_stubbed(:space) }
      it_behaves_like 'ToNG(html)', 404
      it_behaves_like 'ToNG(json)', 404
    end
    shared_examples_for '[未ログイン]スペースが公開' do
      let_it_be(:space) { FactoryBot.create(:space, :public) }
      it_behaves_like '[*][公開]権限がない'
      # it_behaves_like '[未ログイン][公開]権限がある', :admin # NOTE: 未ログインの為、権限がない
      # it_behaves_like '[未ログイン][公開]権限がある', :writer
      # it_behaves_like '[未ログイン][公開]権限がある', :reader
    end
    shared_examples_for '[ログイン中/削除予約済み]スペースが公開' do
      let_it_be(:space) { FactoryBot.create(:space, :public) }
      it_behaves_like '[*][公開]権限がない'
      it_behaves_like '[ログイン中/削除予約済み][公開]権限がある(html)', :admin
      it_behaves_like '[ログイン中/削除予約済み][公開]権限がある(json)', :admin
      it_behaves_like '[ログイン中/削除予約済み][公開]権限がある(html)', :writer
      it_behaves_like '[ログイン中/削除予約済み][公開]権限がある(json)', :writer
      it_behaves_like '[ログイン中/削除予約済み][公開]権限がある(html)', :reader
      it_behaves_like '[ログイン中/削除予約済み][公開]権限がある(json)', :reader
    end
    shared_examples_for '[APIログイン中/削除予約済み]スペースが公開' do
      let_it_be(:space) { FactoryBot.create(:space, :public) }
      it_behaves_like '[*][公開]権限がない'
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がある', :admin
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がある', :writer
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がある', :reader
    end
    shared_examples_for '[未ログイン]スペースが非公開' do
      let_it_be(:space) { FactoryBot.create(:space, :private) }
      it_behaves_like '[未ログイン][非公開]権限がない'
      # it_behaves_like '[未ログイン][非公開]権限がある', :admin # NOTE: 未ログインの為、権限がない
      # it_behaves_like '[未ログイン][非公開]権限がある', :writer
      # it_behaves_like '[未ログイン][非公開]権限がある', :reader
    end
    shared_examples_for '[ログイン中/削除予約済み]スペースが非公開' do
      let_it_be(:space) { FactoryBot.create(:space, :private) }
      it_behaves_like '[ログイン中/削除予約済み][非公開]権限がない'
      it_behaves_like '[ログイン中/削除予約済み][非公開]権限がある', :admin
      it_behaves_like '[ログイン中/削除予約済み][非公開]権限がある', :writer
      it_behaves_like '[ログイン中/削除予約済み][非公開]権限がある', :reader
    end
    shared_examples_for '[APIログイン中/削除予約済み]スペースが非公開' do
      let_it_be(:space) { FactoryBot.create(:space, :private) }
      it_behaves_like '[APIログイン中/削除予約済み][非公開]権限がない'
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がある', :admin
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がある', :writer
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がある', :reader
    end

    context '未ログイン' do
      include_context '未ログイン処理'
      it_behaves_like '[*]スペースが存在しない'
      it_behaves_like '[未ログイン]スペースが公開'
      it_behaves_like '[未ログイン]スペースが非公開'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[*]スペースが存在しない'
      it_behaves_like '[ログイン中/削除予約済み]スペースが公開'
      it_behaves_like '[ログイン中/削除予約済み]スペースが非公開'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', :destroy_reserved
      it_behaves_like '[*]スペースが存在しない'
      it_behaves_like '[ログイン中/削除予約済み]スペースが公開'
      it_behaves_like '[ログイン中/削除予約済み]スペースが非公開'
    end
    context 'APIログイン中' do
      include_context 'APIログイン処理'
      it_behaves_like '[*]スペースが存在しない'
      it_behaves_like '[APIログイン中/削除予約済み]スペースが公開'
      it_behaves_like '[APIログイン中/削除予約済み]スペースが非公開'
    end
    context 'APIログイン中（削除予約済み）' do
      include_context 'APIログイン処理', :destroy_reserved
      it_behaves_like '[*]スペースが存在しない'
      it_behaves_like '[APIログイン中/削除予約済み]スペースが公開'
      it_behaves_like '[APIログイン中/削除予約済み]スペースが非公開'
    end
  end
end
