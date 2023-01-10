require 'rails_helper'

RSpec.describe 'Members', type: :request do
  let(:response_json) { JSON.parse(response.body) }

  # GET /members/:space_code/detail/:user_code(.json) メンバー詳細API
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）, APIログイン中, APIログイン中（削除予約済み）
  #   スペース: 存在しない, 公開, 非公開
  #   権限: ある（管理者, 投稿者, 閲覧者）, ない
  #   対象メンバー: いる, いない
  #   ＋URLの拡張子: ない, .json
  #   ＋Acceptヘッダ: HTMLが含まれる, JSONが含まれる
  describe 'GET #index' do
    subject { get member_path(space_code: space.code, user_code: show_user.code, format: subject_format), headers: auth_headers.merge(accept_headers) }

    shared_context 'valid_condition' do
      let_it_be(:space)     { FactoryBot.create(:space) }
      let_it_be(:show_user) { FactoryBot.create(:user) }
      let_it_be(:member)    { FactoryBot.create(:member, space: space, user: show_user) }
    end

    # テスト内容
    shared_examples_for 'ToOK(json/json)' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it 'HTTPステータスが200。対象項目が一致する' do
        is_expected.to eq(200)
        expect(response_json['success']).to eq(true)
        expect(response_json['alert']).to be_nil
        expect(response_json['notice']).to be_nil
        expect_member_json(response_json['member'], member, user_power)
      end
    end

    # テストケース
    shared_examples_for '[APIログイン中/削除予約済み][*][ある]対象メンバーがいる' do
      let_it_be(:member) { FactoryBot.create(:member, space: space, user: show_user) }
      it_behaves_like 'ToNG(html)', 406
      it_behaves_like 'ToOK(json)'
    end
    shared_examples_for '[APIログイン中/削除予約済み][*][ある]対象メンバーがいない' do
      it_behaves_like 'ToNG(html)', 406
      it_behaves_like 'ToNG(json)', 404
    end

    shared_examples_for '[APIログイン中/削除予約済み][*]権限がある' do |power|
      let(:user_power) { power }
      before_all { FactoryBot.create(:member, power, space: space, user: user) }
      let_it_be(:show_user) { FactoryBot.create(:user) }
      it_behaves_like '[APIログイン中/削除予約済み][*][ある]対象メンバーがいる', power
      it_behaves_like '[APIログイン中/削除予約済み][*][ある]対象メンバーがいない', power
    end
    shared_examples_for '[APIログイン中/削除予約済み][*]権限がない' do
      let_it_be(:show_user) { FactoryBot.create(:user) }
      let_it_be(:member)    { FactoryBot.create(:member, space: space, user: show_user) }
      it_behaves_like 'ToNG(html)', 406
      it_behaves_like 'ToNG(json)', 403
    end

    shared_examples_for '[APIログイン中/削除予約済み]スペースが存在しない' do
      let_it_be(:space) { FactoryBot.build_stubbed(:space) }
      let_it_be(:show_user) { FactoryBot.create(:user) }
      it_behaves_like 'ToNG(html)', 406
      it_behaves_like 'ToNG(json)', 404
    end
    shared_examples_for '[APIログイン中/削除予約済み]スペースが公開' do
      let_it_be(:space) { FactoryBot.create(:space, :public) }
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がある', :admin
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がある', :writer
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がある', :reader
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がない'
    end
    shared_examples_for '[APIログイン中/削除予約済み]スペースが非公開' do
      let_it_be(:space) { FactoryBot.create(:space, :private) }
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がある', :admin
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がある', :writer
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がある', :reader
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がない'
    end

    shared_examples_for '[ログイン中/削除予約済み]' do
      include_context 'valid_condition'
      it_behaves_like 'ToNG(html)', 406
      it_behaves_like 'ToNG(json)', 401 # NOTE: APIは未ログイン扱い
    end
    shared_examples_for '[APIログイン中/削除予約済み]' do
      it_behaves_like '[APIログイン中/削除予約済み]スペースが存在しない'
      it_behaves_like '[APIログイン中/削除予約済み]スペースが公開'
      it_behaves_like '[APIログイン中/削除予約済み]スペースが非公開'
    end

    context '未ログイン' do
      include_context '未ログイン処理'
      include_context 'valid_condition'
      it_behaves_like 'ToNG(html)', 406
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
