require 'rails_helper'

RSpec.describe 'Spaces', type: :request do
  let(:response_json) { JSON.parse(response.body) }

  # POST /spaces/create スペース作成(処理)
  # POST /spaces/create(.json) スペース作成API(処理)
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）, APIログイン中, APIログイン中（削除予約済み）
  #   パラメータなし, 有効なパラメータ（同名がない, ある）, 無効なパラメータ
  #   ＋URLの拡張子: ない, .json
  #   ＋Acceptヘッダ: HTMLが含まれる, JSONが含まれる
  describe 'POST #create' do
    subject { post create_space_path(format: subject_format), params: { space: attributes }, headers: auth_headers.merge(accept_headers) }
    let_it_be(:valid_attributes)   { FactoryBot.attributes_for(:space) }
    let_it_be(:exist_attributes)   { valid_attributes.merge(name: FactoryBot.create(:space, :public).name) }
    let_it_be(:invalid_attributes) { valid_attributes.merge(name: nil) }
    let(:current_space)  { Space.last }
    let(:current_member) { Member.last }

    # テスト内容
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
        expect(response_json['alert']).to be_nil
        expect(response_json['notice']).to eq(get_locale('notice.space.create'))
        expect_space_json(response_json['space'], current_space, :admin, 1)
      end
    end

    # テストケース
    shared_examples_for '[ログイン中]パラメータなし' do
      let(:attributes) { nil }
      it_behaves_like 'NG(html)'
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(html)', 422, [get_locale('activerecord.errors.models.space.attributes.name.blank')]
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中]パラメータなし' do
      let(:attributes) { nil }
      it_behaves_like 'NG(html)'
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(html)', 422, [get_locale('activerecord.errors.models.space.attributes.name.blank')]
      it_behaves_like 'ToNG(json)', 422, { name: [get_locale('activerecord.errors.models.space.attributes.name.blank')] }
    end
    shared_examples_for '[ログイン中]有効なパラメータ（同名がない）' do
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK(html)'
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToOK(html)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中]有効なパラメータ（同名がない）' do
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK(html)'
      it_behaves_like 'OK(json)'
      it_behaves_like 'ToOK(html)' # NOTE: HTMLもログイン状態になる
      it_behaves_like 'ToOK(json)'
    end
    shared_examples_for '[ログイン中]有効なパラメータ（同名がある）' do
      let(:attributes) { exist_attributes }
      it_behaves_like 'NG(html)'
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(html)', 422, [get_locale('activerecord.errors.models.space.attributes.name.taken')]
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中]有効なパラメータ（同名がある）' do
      let(:attributes) { exist_attributes }
      it_behaves_like 'NG(html)'
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(html)', 422, [get_locale('activerecord.errors.models.space.attributes.name.taken')] # NOTE: HTMLもログイン状態になる
      it_behaves_like 'ToNG(json)', 422, { name: [get_locale('activerecord.errors.models.space.attributes.name.taken')] }
    end
    shared_examples_for '[ログイン中]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG(html)'
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(html)', 422, [get_locale('activerecord.errors.models.space.attributes.name.blank')]
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG(html)'
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(html)', 422, [get_locale('activerecord.errors.models.space.attributes.name.blank')] # NOTE: HTMLもログイン状態になる
      it_behaves_like 'ToNG(json)', 422, { name: [get_locale('activerecord.errors.models.space.attributes.name.blank')] }
    end

    context '未ログイン' do
      include_context '未ログイン処理'
      let(:attributes) { valid_attributes }
      it_behaves_like 'NG(html)'
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToLogin(html)'
      it_behaves_like 'ToNG(json)', 401
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中]パラメータなし'
      it_behaves_like '[ログイン中]有効なパラメータ（同名がない）'
      it_behaves_like '[ログイン中]有効なパラメータ（同名がある）'
      it_behaves_like '[ログイン中]無効なパラメータ'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', :destroy_reserved
      let(:attributes) { valid_attributes }
      it_behaves_like 'NG(html)'
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToSpaces(html)', 'alert.user.destroy_reserved'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    context 'APIログイン中' do
      include_context 'APIログイン処理'
      it_behaves_like '[APIログイン中]パラメータなし'
      it_behaves_like '[APIログイン中]有効なパラメータ（同名がない）'
      it_behaves_like '[APIログイン中]有効なパラメータ（同名がある）'
      it_behaves_like '[APIログイン中]無効なパラメータ'
    end
    context 'APIログイン中（削除予約済み）' do
      include_context 'APIログイン処理', :destroy_reserved
      let(:attributes) { valid_attributes }
      it_behaves_like 'NG(html)'
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToSpaces(html)', 'alert.user.destroy_reserved' # NOTE: HTMLもログイン状態になる
      it_behaves_like 'ToNG(json)', 422, nil, 'alert.user.destroy_reserved'
    end
  end
end
