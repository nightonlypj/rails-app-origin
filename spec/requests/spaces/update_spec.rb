require 'rails_helper'

RSpec.describe 'Spaces', type: :request do
  let(:response_json) { JSON.parse(response.body) }
  let(:response_json_space) { response_json['space'] }

  # POST /spaces/update/:code スペース設定変更(処理)
  # POST /spaces/update/:code(.json) スペース設定変更API(処理)
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）, APIログイン中, APIログイン中（削除予約済み）
  #   スペース: 存在しない, 公開, 公開（削除予約済み）, 非公開, 非公開（削除予約済み）
  #   権限: ある（管理者）, ない（投稿者, 閲覧者, なし）
  #   パラメータなし, 有効なパラメータ, 無効なパラメータ
  #     同名のスペース: 存在しない, 存在する
  # TODO: 有効なパラメータ（画像削除）
  #   ＋URLの拡張子: ない, .json
  #   ＋Acceptヘッダ: HTMLが含まれる, JSONが含まれる
  describe 'POST #update' do
    subject { post update_space_path(code: space.code, format: subject_format), params:, headers: auth_headers.merge(accept_headers) }

    let_it_be(:created_user) { FactoryBot.create(:user) }
    let_it_be(:valid_attributes)   { FactoryBot.attributes_for(:space).except(:code) }
    let_it_be(:exist_attributes)   { valid_attributes.merge(name: FactoryBot.create(:space, :public, created_user:).name) }
    let_it_be(:invalid_attributes) { valid_attributes.merge(name: nil) }
    shared_context 'valid_condition' do
      let_it_be(:space) { FactoryBot.create(:space, :public, created_user:) }
      before_all { FactoryBot.create(:member, :admin, space:, user:) if user.present? }
      let(:params) { { space: valid_attributes } }
    end

    # テスト内容
    let(:current_space) { Space.find(space.id) }
    shared_examples_for 'OK' do
      it '対象項目が変更される' do
        subject
        expect(current_space.name).to eq(attributes[:name])
        expect(current_space.description).to eq(attributes[:description])
        expect(current_space.private).to eq(attributes[:private])
        expect(current_space.last_updated_user).to eq(user)
      end
    end
    shared_examples_for 'NG' do
      it '変更されない' do
        subject
        expect(current_space).to eq(space)
      end
    end

    shared_examples_for 'ToOK(html/*)' do
      it '変更したスペースにリダイレクトする' do
        is_expected.to redirect_to(space_path(code: space.code))
        expect(flash[:alert]).to be_nil
        expect(flash[:notice]).to eq(get_locale('notice.space.update'))
      end
    end
    shared_examples_for 'ToOK(json/json)' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it 'HTTPステータスが200。対象項目が一致する' do
        is_expected.to eq(200)
        expect(response_json['success']).to be(true)
        expect(response_json['notice']).to eq(get_locale('notice.space.update'))

        count = expect_space_json(response_json_space, current_space, :admin, 1)
        expect(response_json_space.count).to eq(count)

        expect(response_json.count).to eq(3)
      end
    end

    # テストケース
    shared_examples_for '[ログイン中][削除予約なし][ある]パラメータなし' do
      let(:params) { nil }
      message = get_locale('activerecord.errors.models.space.attributes.name.blank')
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToNG(html)', 422, [message]
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中][削除予約なし][ある]パラメータなし' do
      let(:params) { nil }
      message = get_locale('activerecord.errors.models.space.attributes.name.blank')
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToNG(html)', 422, [message] # NOTE: HTMLもログイン状態になる
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 422, { name: [message] }
    end
    shared_examples_for '[ログイン中][削除予約なし][ある]有効なパラメータ（同名のスペースが存在しない）' do
      let(:params) { { space: attributes } }
      let(:attributes) { valid_attributes }
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
    shared_examples_for '[APIログイン中][削除予約なし][ある]有効なパラメータ（同名のスペースが存在しない）' do
      let(:params) { { space: attributes } }
      let(:attributes) { valid_attributes }
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
    shared_examples_for '[ログイン中][削除予約なし][ある]有効なパラメータ（同名のスペースが存在する）' do
      let(:params) { { space: exist_attributes } }
      message = get_locale('activerecord.errors.models.space.attributes.name.taken')
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToNG(html)', 422, [message]
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中][削除予約なし][ある]有効なパラメータ（同名のスペースが存在する）' do
      let(:params) { { space: exist_attributes } }
      message = get_locale('activerecord.errors.models.space.attributes.name.taken')
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToNG(html)', 422, [message] # NOTE: HTMLもログイン状態になる
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 422, { name: [message] }
    end
    shared_examples_for '[ログイン中][削除予約なし][ある]無効なパラメータ' do
      let(:params) { { space: invalid_attributes } }
      message = get_locale('activerecord.errors.models.space.attributes.name.blank')
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToNG(html)', 422, [message]
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中][削除予約なし][ある]無効なパラメータ' do
      let(:params) { { space: invalid_attributes } }
      message = get_locale('activerecord.errors.models.space.attributes.name.blank')
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToNG(html)', 422, [message] # NOTE: HTMLもログイン状態になる
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 422, { name: [message] }
    end

    shared_examples_for '[ログイン中][削除予約なし]権限がある' do |power|
      before_all { FactoryBot.create(:member, power, space:, user:) }
      it_behaves_like '[ログイン中][削除予約なし][ある]パラメータなし'
      it_behaves_like '[ログイン中][削除予約なし][ある]有効なパラメータ（同名のスペースが存在しない）'
      it_behaves_like '[ログイン中][削除予約なし][ある]有効なパラメータ（同名のスペースが存在する）'
      it_behaves_like '[ログイン中][削除予約なし][ある]無効なパラメータ'
    end
    shared_examples_for '[APIログイン中][削除予約なし]権限がある' do |power|
      before_all { FactoryBot.create(:member, power, space:, user:) }
      it_behaves_like '[APIログイン中][削除予約なし][ある]パラメータなし'
      it_behaves_like '[APIログイン中][削除予約なし][ある]有効なパラメータ（同名のスペースが存在しない）'
      it_behaves_like '[APIログイン中][削除予約なし][ある]有効なパラメータ（同名のスペースが存在する）'
      it_behaves_like '[APIログイン中][削除予約なし][ある]無効なパラメータ'
    end
    shared_examples_for '[ログイン中][削除予約なし]権限がない' do |power|
      before_all { FactoryBot.create(:member, power, space:, user:) if power.present? }
      let(:params) { { space: valid_attributes } }
      it_behaves_like 'NG(html)'
      it_behaves_like 'ToNG(html)', Settings.api_only_mode ? 406 : 403
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中][削除予約なし]権限がない' do |power|
      before_all { FactoryBot.create(:member, power, space:, user:) if power.present? }
      let(:params) { { space: valid_attributes } }
      it_behaves_like 'NG(html)'
      it_behaves_like 'ToNG(html)', Settings.api_only_mode ? 406 : 403 # NOTE: HTMLもログイン状態になる
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 403
    end

    shared_examples_for '[ログイン中][削除予約なし]' do
      it_behaves_like '[ログイン中][削除予約なし]権限がある', :admin
      it_behaves_like '[ログイン中][削除予約なし]権限がない', :writer
      it_behaves_like '[ログイン中][削除予約なし]権限がない', :reader
      it_behaves_like '[ログイン中][削除予約なし]権限がない', nil
    end
    shared_examples_for '[APIログイン中][削除予約なし]' do
      it_behaves_like '[APIログイン中][削除予約なし]権限がある', :admin
      it_behaves_like '[APIログイン中][削除予約なし]権限がない', :writer
      it_behaves_like '[APIログイン中][削除予約なし]権限がない', :reader
      it_behaves_like '[APIログイン中][削除予約なし]権限がない', nil
    end
    shared_examples_for '[ログイン中][削除予約済み]' do
      before_all { FactoryBot.create(:member, :admin, space:, user:) }
      let(:params) { { space: valid_attributes } }
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToSpace(html)', 'alert.space.destroy_reserved'
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中][削除予約済み]' do
      before_all { FactoryBot.create(:member, :admin, space:, user:) }
      let(:params) { { space: valid_attributes } }
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToSpace(html)', 'alert.space.destroy_reserved' # NOTE: HTMLもログイン状態になる
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 422, nil, 'alert.space.destroy_reserved'
    end

    shared_examples_for '[ログイン中]スペースが存在しない' do
      let_it_be(:space) { FactoryBot.build_stubbed(:space) }
      let(:params) { { space: valid_attributes } }
      # it_behaves_like 'NG(html)' # NOTE: 存在しない為
      it_behaves_like 'ToNG(html)', Settings.api_only_mode ? 406 : 404
      # it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中]スペースが存在しない' do
      let_it_be(:space) { FactoryBot.build_stubbed(:space) }
      let(:params) { { space: valid_attributes } }
      # it_behaves_like 'NG(html)' # NOTE: 存在しない為
      it_behaves_like 'ToNG(html)', Settings.api_only_mode ? 406 : 404 # NOTE: HTMLもログイン状態になる
      # it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 404
    end
    shared_examples_for '[ログイン中]スペースが公開' do
      let_it_be(:space) { FactoryBot.create(:space, :public, created_user:) }
      it_behaves_like '[ログイン中][削除予約なし]'
    end
    shared_examples_for '[APIログイン中]スペースが公開' do
      let_it_be(:space) { FactoryBot.create(:space, :public, created_user:) }
      it_behaves_like '[APIログイン中][削除予約なし]'
    end
    shared_examples_for '[ログイン中]スペースが公開（削除予約済み）' do
      let_it_be(:space) { FactoryBot.create(:space, :public, :destroy_reserved, created_user:) }
      it_behaves_like '[ログイン中][削除予約済み]'
    end
    shared_examples_for '[APIログイン中]スペースが公開（削除予約済み）' do
      let_it_be(:space) { FactoryBot.create(:space, :public, :destroy_reserved, created_user:) }
      it_behaves_like '[APIログイン中][削除予約済み]'
    end
    shared_examples_for '[ログイン中]スペースが非公開' do
      let_it_be(:space) { FactoryBot.create(:space, :private, created_user:) }
      it_behaves_like '[ログイン中][削除予約なし]'
    end
    shared_examples_for '[APIログイン中]スペースが非公開' do
      let_it_be(:space) { FactoryBot.create(:space, :private, created_user:) }
      it_behaves_like '[APIログイン中][削除予約なし]'
    end
    shared_examples_for '[ログイン中]スペースが非公開（削除予約済み）' do
      let_it_be(:space) { FactoryBot.create(:space, :private, :destroy_reserved, created_user:) }
      it_behaves_like '[ログイン中][削除予約済み]'
    end
    shared_examples_for '[APIログイン中]スペースが非公開（削除予約済み）' do
      let_it_be(:space) { FactoryBot.create(:space, :private, :destroy_reserved, created_user:) }
      it_behaves_like '[APIログイン中][削除予約済み]'
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
      if Settings.enable_public_space
        it_behaves_like '[ログイン中]スペースが公開'
        it_behaves_like '[ログイン中]スペースが公開（削除予約済み）'
      end
      it_behaves_like '[ログイン中]スペースが非公開'
      it_behaves_like '[ログイン中]スペースが非公開（削除予約済み）'
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
      if Settings.enable_public_space
        it_behaves_like '[APIログイン中]スペースが公開'
        it_behaves_like '[APIログイン中]スペースが公開（削除予約済み）'
      end
      it_behaves_like '[APIログイン中]スペースが非公開'
      it_behaves_like '[APIログイン中]スペースが非公開（削除予約済み）'
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
