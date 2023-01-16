require 'rails_helper'

RSpec.describe 'Downloads', type: :request do
  let(:response_json) { JSON.parse(response.body) }

  # POST /downloads/create ダウンロード依頼(処理)
  # POST /downloads/create(.json) ダウンロード依頼API(処理)
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）, APIログイン中, APIログイン中（削除予約済み）
  #   model: member（space: 存在する, 存在しない, ない）, 存在しない, ない
  #   権限: ある（管理者）, ない（投稿者, 閲覧者, なし）
  #   パラメータなし, 有効なパラメータ, 無効なパラメータ
  #   ＋URLの拡張子: ない, .json
  #   ＋Acceptヘッダ: HTMLが含まれる, JSONが含まれる
  describe 'POST #create' do
    subject { post create_download_path(format: subject_format), params: { download: attributes }, headers: auth_headers.merge(accept_headers) }
    let_it_be(:space)     { FactoryBot.create(:space) }
    let_it_be(:space_not) { FactoryBot.build_stubbed(:space) }
    let_it_be(:valid_attributes)   { FactoryBot.attributes_for(:download) }
    let_it_be(:invalid_attributes) { valid_attributes.merge(target: nil) }
    let(:current_download) { Download.last }

    shared_context 'valid_condition' do
      let(:params) { { model: 'member', space_code: space.code, output_items: nil, 'output_items_user.name': '1' } }
      let(:attributes) { valid_attributes.merge(params) }
      include_context 'set_member_power', :admin
    end

    # テスト内容
    shared_examples_for 'OK' do
      let!(:start_time) { Time.current.floor }
      it 'ダウンロードが作成・対象項目が設定される' do
        expect do
          subject
          expect(current_download.user).to eq(user)
          expect(current_download.status.to_sym).to eq(:waiting)
          expect(current_download.requested_at).to be_between(start_time, Time.current)
          expect(current_download.completed_at).to be_nil
          expect(current_download.error_message).to be_nil
          expect(current_download.last_downloaded_at).to be_nil

          expect(current_download.model).to eq(attributes[:model])
          expect(current_download.space).to attributes[:model] == 'member' ? eq(space) : be_nil

          expect(current_download.target.to_sym).to eq(attributes[:target])
          expect(current_download.format.to_sym).to eq(attributes[:format])
          expect(current_download.char_code.to_sym).to eq(attributes[:char_code])
          expect(current_download.newline_code.to_sym).to eq(attributes[:newline_code])

          expect(current_download.output_items).to eq(output_items)
          expect(current_download.select_items).to eq(select_items)
          expect(current_download.search_params).to eq(search_params)
        end.to change(Download, :count).by(1)
      end
    end
    shared_examples_for 'NG' do
      it 'ダウンロードが作成されない' do
        expect { subject }.to change(Download, :count).by(0)
      end
    end

    shared_examples_for 'ToOK(html/*)' do
      it 'ダウンロード結果一覧にリダイレクトする' do
        is_expected.to redirect_to(downloads_path(id: current_download.id))
        expect(flash[:alert]).to be_nil
        expect(flash[:notice]).to be_nil
      end
    end
    shared_examples_for 'ToOK(json/json)' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it 'HTTPステータスが201。対象項目が一致する' do
        is_expected.to eq(201)
        expect(response_json['success']).to eq(true)
        expect(response_json['alert']).to be_nil
        expect(response_json['notice']).to eq(get_locale('notice.download.create'))
        expect_download_json(response_json['download'], current_download)
      end
    end

    # テストケース
    shared_examples_for '[ログイン中/削除予約済み][member][ある]パラメータなし' do
      let(:attributes) { params }
      it_behaves_like 'NG(html)'
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(html)', 422, [
        get_locale('activerecord.errors.models.download.attributes.target.blank'),
        get_locale('activerecord.errors.models.download.attributes.format.blank'),
        get_locale('activerecord.errors.models.download.attributes.char_code.blank'),
        get_locale('activerecord.errors.models.download.attributes.newline_code.blank'),
        get_locale('activerecord.errors.models.download.attributes.output_items.blank')
      ]
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中/削除予約済み][member][ある]パラメータなし' do
      let(:attributes) { params }
      it_behaves_like 'NG(html)'
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(html)', 422, [
        get_locale('activerecord.errors.models.download.attributes.target.blank'),
        get_locale('activerecord.errors.models.download.attributes.format.blank'),
        get_locale('activerecord.errors.models.download.attributes.char_code.blank'),
        get_locale('activerecord.errors.models.download.attributes.newline_code.blank'),
        get_locale('activerecord.errors.models.download.attributes.output_items.blank')
      ]
      it_behaves_like 'ToNG(json)', 422, {
        target: [get_locale('activerecord.errors.models.download.attributes.target.blank')],
        format: [get_locale('activerecord.errors.models.download.attributes.format.blank')],
        char_code: [get_locale('activerecord.errors.models.download.attributes.char_code.blank')],
        newline_code: [get_locale('activerecord.errors.models.download.attributes.newline_code.blank')],
        output_items: [get_locale('activerecord.errors.models.download.attributes.output_items.blank')]
      }
    end
    shared_examples_for '[ログイン中/削除予約済み][member][ある]有効なパラメータ' do
      let(:attributes) { valid_attributes.merge(params).merge(add_attributes) }
      it_behaves_like 'OK(html)'
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToOK(html)'
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中/削除予約済み][member][ある]有効なパラメータ' do
      let(:attributes) { valid_attributes.merge(params).merge(add_attributes) }
      it_behaves_like 'NG(html)' # NOTE: HTMLもログイン状態になるが、パラメータが異なる為
      it_behaves_like 'OK(json)'
      it_behaves_like 'ToNG(html)', 422, [get_locale('activerecord.errors.models.download.attributes.output_items.blank')] # NOTE: HTMLもログイン状態になるが、パラメータが異なる為
      it_behaves_like 'ToOK(json)'
    end
    shared_examples_for '[ログイン中/削除予約済み][member][ある]無効なパラメータ' do
      let(:attributes) { invalid_attributes.merge(params).merge(add_attributes) }
      it_behaves_like 'NG(html)'
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(html)', 422, [get_locale('activerecord.errors.models.download.attributes.target.blank')]
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中/削除予約済み][member][ある]無効なパラメータ' do
      let(:attributes) { invalid_attributes.merge(params).merge(add_attributes) }
      it_behaves_like 'NG(html)'
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(html)', 422, [get_locale('activerecord.errors.models.download.attributes.target.blank')] # NOTE: HTMLもログイン状態になる
      it_behaves_like 'ToNG(json)', 422, { target: [get_locale('activerecord.errors.models.download.attributes.target.blank')] }
    end

    shared_examples_for '[ログイン中/削除予約済み][member]権限がある' do |power|
      include_context 'set_member_power', power
      it_behaves_like '[ログイン中/削除予約済み][member][ある]パラメータなし'
      it_behaves_like '[ログイン中/削除予約済み][member][ある]有効なパラメータ'
      it_behaves_like '[ログイン中/削除予約済み][member][ある]無効なパラメータ'
    end
    shared_examples_for '[APIログイン中/削除予約済み][member]権限がある' do |power|
      include_context 'set_member_power', power
      it_behaves_like '[APIログイン中/削除予約済み][member][ある]パラメータなし'
      it_behaves_like '[APIログイン中/削除予約済み][member][ある]有効なパラメータ'
      it_behaves_like '[APIログイン中/削除予約済み][member][ある]無効なパラメータ'
    end
    shared_examples_for '[ログイン中/削除予約済み][member]権限がない' do |power|
      include_context 'set_member_power', power
      let(:attributes) { valid_attributes.merge(params) }
      it_behaves_like 'NG(html)'
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(html)', 403
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中/削除予約済み][member]権限がない' do |power|
      include_context 'set_member_power', power
      let(:attributes) { valid_attributes.merge(params) }
      it_behaves_like 'NG(html)'
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToNG(html)', 403 # NOTE: HTMLもログイン状態になる
      it_behaves_like 'ToNG(json)', 403
    end

    let(:output_items)  { '["user.name"]' }
    let(:select_items)  { '["code000000000000000000001", "code000000000000000000002"]' }
    let(:search_params) { '{"text"=>"aaa"}' }
    shared_examples_for '[ログイン中/削除予約済み]modelがmember（spaceが存在する）' do
      let(:params) { { model: 'member', space_code: space.code } }
      let(:add_attributes) do
        {
          output_items: nil,
          'output_items_user.name': '1',
          select_items: 'code000000000000000000001,code000000000000000000002',
          search_params: { 'text' => 'aaa' }
        }
      end
      it_behaves_like '[ログイン中/削除予約済み][member]権限がある', :admin
      it_behaves_like '[ログイン中/削除予約済み][member]権限がない', :writer
      it_behaves_like '[ログイン中/削除予約済み][member]権限がない', :reader
      it_behaves_like '[ログイン中/削除予約済み][member]権限がない', nil
    end
    shared_examples_for '[APIログイン中/削除予約済み]modelがmember（spaceが存在する）' do
      let(:params) { { model: 'member', space_code: space.code } }
      let(:add_attributes) do
        {
          output_items: ['user.name'],
          select_items: %w[code000000000000000000001 code000000000000000000002],
          search_params: { 'text' => 'aaa' }
        }
      end
      it_behaves_like '[APIログイン中/削除予約済み][member]権限がある', :admin
      it_behaves_like '[APIログイン中/削除予約済み][member]権限がない', :writer
      it_behaves_like '[APIログイン中/削除予約済み][member]権限がない', :reader
      it_behaves_like '[APIログイン中/削除予約済み][member]権限がない', nil
    end
    shared_examples_for '[ログイン中/削除予約済み]modelがmember（spaceが存在しない）' do
      let(:params) { { model: 'member', space_code: space_not.code, output_items: nil, 'output_items_user.name': '1' } }
      let(:attributes) { valid_attributes.merge(params) }
      it_behaves_like 'ToNG(html)', 404
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中/削除予約済み]modelがmember（spaceが存在しない）' do
      let(:params) { { model: 'member', space_code: space_not.code, output_items: nil, 'output_items_user.name': '1' } }
      let(:attributes) { valid_attributes.merge(params) }
      it_behaves_like 'ToNG(html)', 404 # NOTE: HTMLもログイン状態になる
      it_behaves_like 'ToNG(json)', 404, { space_code: [get_locale('errors.messages.param.not_exist')] }, 'errors.messages.not_saved.one'
    end
    shared_examples_for '[ログイン中/削除予約済み]modelがmember（spaceがない）' do
      let(:params) { { model: 'member', space_code: nil, output_items: nil, 'output_items_user.name': '1' } }
      let(:attributes) { valid_attributes.merge(params) }
      it_behaves_like 'ToNG(html)', 404
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中/削除予約済み]modelがmember（spaceがない）' do
      let(:params) { { model: 'member', space_code: nil, output_items: nil, 'output_items_user.name': '1' } }
      let(:attributes) { valid_attributes.merge(params) }
      it_behaves_like 'ToNG(html)', 404 # NOTE: HTMLもログイン状態になる
      it_behaves_like 'ToNG(json)', 404, { space_code: [get_locale('errors.messages.param.blank')] }, 'errors.messages.not_saved.one'
    end
    shared_examples_for '[ログイン中/削除予約済み]modelが存在しない' do
      let(:params) { { model: 'xxx' } }
      let(:attributes) { valid_attributes.merge(params) }
      it_behaves_like 'ToNG(html)', 404
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中/削除予約済み]modelが存在しない' do
      let(:params) { { model: 'xxx' } }
      let(:attributes) { valid_attributes.merge(params) }
      it_behaves_like 'ToNG(html)', 404 # NOTE: HTMLもログイン状態になる
      it_behaves_like 'ToNG(json)', 404, { model: [get_locale('errors.messages.param.not_exist')] }, 'errors.messages.not_saved.one'
    end
    shared_examples_for '[ログイン中/削除予約済み]modelがない' do
      let(:params) { { model: nil } }
      let(:attributes) { valid_attributes.merge(params) }
      it_behaves_like 'ToNG(html)', 404
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中/削除予約済み]modelがない' do
      let(:params) { { model: nil } }
      let(:attributes) { valid_attributes.merge(params) }
      it_behaves_like 'ToNG(html)', 404 # NOTE: HTMLもログイン状態になる
      it_behaves_like 'ToNG(json)', 404, { model: [get_locale('errors.messages.param.blank')] }, 'errors.messages.not_saved.one'
    end

    shared_examples_for '[ログイン中/削除予約済み]' do
      it_behaves_like '[ログイン中/削除予約済み]modelがmember（spaceが存在する）'
      it_behaves_like '[ログイン中/削除予約済み]modelがmember（spaceが存在しない）'
      it_behaves_like '[ログイン中/削除予約済み]modelがmember（spaceがない）'
      it_behaves_like '[ログイン中/削除予約済み]modelが存在しない'
      it_behaves_like '[ログイン中/削除予約済み]modelがない'
    end
    shared_examples_for '[APIログイン中/削除予約済み]' do
      it_behaves_like '[APIログイン中/削除予約済み]modelがmember（spaceが存在する）'
      it_behaves_like '[APIログイン中/削除予約済み]modelがmember（spaceが存在しない）'
      it_behaves_like '[APIログイン中/削除予約済み]modelがmember（spaceがない）'
      it_behaves_like '[APIログイン中/削除予約済み]modelが存在しない'
      it_behaves_like '[APIログイン中/削除予約済み]modelがない'
    end

    context '未ログイン' do
      include_context '未ログイン処理'
      include_context 'valid_condition'
      it_behaves_like 'NG(html)'
      it_behaves_like 'NG(json)'
      it_behaves_like 'ToLogin(html)'
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
