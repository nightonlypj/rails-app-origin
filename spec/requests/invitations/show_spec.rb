require 'rails_helper'

RSpec.describe 'Invitations', type: :request do
  let(:response_json) { JSON.parse(response.body) }
  let(:response_json_invitation) { response_json['invitation'] }

  # GET /invitations/:space_code/detail/:code(.json) 招待URL詳細API
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）, APIログイン中, APIログイン中（削除予約済み）
  #   スペース: 存在しない, 公開, 非公開
  #   権限: ある（管理者）, ない（投稿者, 閲覧者, なし）
  #   招待コード: 存在する（有効, 期限切れ, 削除済み, 参加済み）, 存在しない
  #   ＋URLの拡張子: ない, .json
  #   ＋Acceptヘッダ: HTMLが含まれる, JSONが含まれる
  describe 'GET #show' do
    subject { get invitation_path(space_code: space.code, code: invitation.code, format: subject_format), headers: auth_headers.merge(accept_headers) }

    let_it_be(:created_user) { FactoryBot.create(:user) }
    shared_context 'valid_condition' do
      let_it_be(:space) { FactoryBot.create(:space, :public, created_user:) }
      let_it_be(:invitation) { FactoryBot.create(:invitation, :active, space:, created_user:) }
    end

    # テスト内容
    shared_examples_for 'ToOK(json/json)' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it 'HTTPステータスが200。対象項目が一致する' do
        is_expected.to eq(200)
        expect(response_json['success']).to be(true)

        count = expect_invitation_json(response_json_invitation, invitation)
        ## 招待削除の猶予期間
        expect(response_json_invitation['destroy_schedule_days']).to eq(Settings.invitation_destroy_schedule_days)
        expect(response_json_invitation.count).to eq(count + 1)

        expect(response_json.count).to eq(2)
      end
    end

    # テストケース
    shared_examples_for '[APIログイン中/削除予約済み][*][ある]招待コードが存在する' do |status|
      let_it_be(:invitation) { FactoryBot.create(:invitation, status, space:, created_user:) }
      it_behaves_like 'ToNG(html)', 406
      it_behaves_like 'ToOK(json)'
    end
    shared_examples_for '[APIログイン中/削除予約済み][*][ある]招待コードが存在しない' do
      let_it_be(:invitation) { FactoryBot.build_stubbed(:invitation) }
      it_behaves_like 'ToNG(html)', 406
      it_behaves_like 'ToNG(json)', 404
    end

    shared_examples_for '[APIログイン中/削除予約済み][*]権限がある' do |power|
      before_all { FactoryBot.create(:member, power, space:, user:) }
      it_behaves_like '[APIログイン中/削除予約済み][*][ある]招待コードが存在する', :active
      it_behaves_like '[APIログイン中/削除予約済み][*][ある]招待コードが存在する', :expired
      it_behaves_like '[APIログイン中/削除予約済み][*][ある]招待コードが存在する', :deleted
      it_behaves_like '[APIログイン中/削除予約済み][*][ある]招待コードが存在する', :email_joined
      it_behaves_like '[APIログイン中/削除予約済み][*][ある]招待コードが存在しない'
    end
    shared_examples_for '[APIログイン中/削除予約済み][*]権限がない' do |power|
      before_all { FactoryBot.create(:member, power, space:, user:) if power.present? }
      let_it_be(:invitation) { FactoryBot.create(:invitation, :active, space:, created_user:) }
      it_behaves_like 'ToNG(html)', 406
      it_behaves_like 'ToNG(json)', 403
    end

    shared_examples_for '[APIログイン中/削除予約済み]スペースが存在しない' do
      let_it_be(:space) { FactoryBot.build_stubbed(:space) }
      let_it_be(:invitation) { FactoryBot.build_stubbed(:invitation) }
      it_behaves_like 'ToNG(html)', 406
      it_behaves_like 'ToNG(json)', 404
    end
    shared_examples_for '[APIログイン中/削除予約済み]スペースが公開' do
      let_it_be(:space) { FactoryBot.create(:space, :public, created_user:) }
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がある', :admin
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がない', :writer
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がない', :reader
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がない', nil
    end
    shared_examples_for '[APIログイン中/削除予約済み]スペースが非公開' do
      let_it_be(:space) { FactoryBot.create(:space, :private, created_user:) }
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がある', :admin
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がない', :writer
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がない', :reader
      it_behaves_like '[APIログイン中/削除予約済み][*]権限がない', nil
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