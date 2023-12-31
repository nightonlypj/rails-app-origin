require 'rails_helper'

RSpec.describe 'Spaces', type: :request do
  let(:response_json) { JSON.parse(response.body) }
  let(:response_json_space) { response_json['space'] }

  # POST /spaces/create スペース作成(処理)
  # POST /spaces/create(.json) スペース作成API(処理)
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）, APIログイン中, APIログイン中（削除予約済み）
  #   パラメータなし, 有効なパラメータ, 無効なパラメータ
  #     同名のスペース: 存在しない, 存在する
  #   ＋URLの拡張子: ない, .json
  #   ＋Acceptヘッダ: HTMLが含まれる, JSONが含まれる
  describe 'POST #create' do
    subject { post create_space_path(format: subject_format), params:, headers: auth_headers.merge(accept_headers) }
    let_it_be(:valid_attributes)   { FactoryBot.attributes_for(:space).except(:code) }
    let_it_be(:exist_attributes)   { valid_attributes.merge(name: FactoryBot.create(:space, :public).name) }
    let_it_be(:invalid_attributes) { valid_attributes.merge(name: nil) }

    # テスト内容
    let(:current_space)  { Space.last }
    let(:current_member) { Member.last }
    shared_examples_for 'OK' do
      it 'スペースとメンバーが作成・対象項目が設定される' do
        expect do
          subject
          expect(current_space.name).to eq(attributes[:name])
          expect(current_space.description).to eq(attributes[:description])
          expect(current_space.private).to eq(attributes[:private])
          expect(current_space.destroy_requested_at).to be_nil
          expect(current_space.destroy_schedule_at).to be_nil
          expect(current_space.created_user).to eq(user)
          expect(current_space.last_updated_user).to be_nil

          expect(current_member.space).to eq(current_space)
          expect(current_member.user).to eq(user)
          expect(current_member.power.to_sym).to eq(:admin)
          expect(current_member.invitationed_user).to be_nil
          expect(current_member.last_updated_user).to be_nil
        end.to change(Space, :count).by(1) && change(Member, :count).by(1)
      end
    end
    shared_examples_for 'NG' do
      it 'スペースとメンバーが作成されない' do
        expect { subject }.to change(Space, :count).by(0) && change(Member, :count).by(0)
      end
    end

    shared_examples_for 'ToOK(html/*)' do
      it '作成したスペースにリダイレクトする' do
        is_expected.to redirect_to(space_path(current_space.code))
        expect(flash[:alert]).to be_nil
        expect(flash[:notice]).to eq(get_locale('notice.space.create'))
      end
    end
    shared_examples_for 'ToOK(json/json)' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it 'HTTPステータスが201。対象項目が一致する' do
        is_expected.to eq(201)
        expect(response_json['success']).to eq(true)
        expect(response_json['notice']).to eq(get_locale('notice.space.create'))

        count = expect_space_json(response_json_space, current_space, :admin, 1)
        expect(response_json_space.count).to eq(count)

        expect(response_json.count).to eq(3)
      end
    end

    # テストケース
    shared_examples_for '[ログイン中]パラメータなし' do
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
    shared_examples_for '[APIログイン中]パラメータなし' do
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
    shared_examples_for '[ログイン中]有効なパラメータ（同名のスペースが存在しない）' do
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
    shared_examples_for '[APIログイン中]有効なパラメータ（同名のスペースが存在しない）' do
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
    shared_examples_for '[ログイン中]有効なパラメータ（同名のスペースが存在する）' do
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
    shared_examples_for '[APIログイン中]有効なパラメータ（同名のスペースが存在する）' do
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
    shared_examples_for '[ログイン中]無効なパラメータ' do
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
    shared_examples_for '[APIログイン中]無効なパラメータ' do
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

    context '未ログイン' do
      include_context '未ログイン処理'
      let(:params) { { space: valid_attributes } }
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
      it_behaves_like '[ログイン中]パラメータなし'
      it_behaves_like '[ログイン中]有効なパラメータ（同名のスペースが存在しない）'
      it_behaves_like '[ログイン中]有効なパラメータ（同名のスペースが存在する）'
      it_behaves_like '[ログイン中]無効なパラメータ'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', :destroy_reserved
      let(:params) { { space: valid_attributes } }
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToSpaces(html)', 'alert.user.destroy_reserved'
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    context 'APIログイン中' do
      include_context 'APIログイン処理'
      it_behaves_like '[APIログイン中]パラメータなし'
      it_behaves_like '[APIログイン中]有効なパラメータ（同名のスペースが存在しない）'
      it_behaves_like '[APIログイン中]有効なパラメータ（同名のスペースが存在する）'
      it_behaves_like '[APIログイン中]無効なパラメータ'
    end
    context 'APIログイン中（削除予約済み）' do
      include_context 'APIログイン処理', :destroy_reserved
      let(:params) { { space: valid_attributes } }
      it_behaves_like 'NG(html)'
      if Settings.api_only_mode
        it_behaves_like 'ToNG(html)', 406
      else
        it_behaves_like 'ToSpaces(html)', 'alert.user.destroy_reserved' # NOTE: HTMLもログイン状態になる
      end
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(json)', 422, nil, 'alert.user.destroy_reserved'
    end
  end
end
