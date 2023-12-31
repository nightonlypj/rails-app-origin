require 'rails_helper'

RSpec.describe 'Members', type: :request do
  let(:response_json) { response.body.present? ? JSON.parse(response.body) : {} }

  # GET /members/:space_code/result メンバー招待（結果）
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）, APIログイン中, APIログイン中（削除予約済み）
  #   スペース: 存在しない, 公開, 非公開
  #   権限: ある（管理者）, ない（投稿者, 閲覧者, なし）
  #   flash: ある（3件, 0件）, ない
  #   ＋URLの拡張子: ない, .json
  #   ＋Acceptヘッダ: HTMLが含まれる, JSONが含まれる
  describe 'GET #result' do
    subject { get result_member_path(space_code: space.code, format: subject_format), headers: auth_headers.merge(accept_headers) }
    let_it_be(:created_user) { FactoryBot.create(:user) }

    shared_context 'valid_condition' do
      let_it_be(:space) { FactoryBot.create(:space, :public, created_user:) }
      before_all { FactoryBot.create(:member, space:, user:) if user.present? }
      include_context 'set_flash_data'
    end
    shared_context 'set_flash_data' do
      let(:emails) { ['user1@example.com', 'user2@example.com', 'user3@example.com'] }
      let(:exist_user_mails)  { ['user1@example.com'] }
      let(:create_user_mails) { ['user2@example.com'] }
    end
    shared_context 'set_flash_data_blank' do
      let(:emails) { [] }
      let(:exist_user_mails)  { [] }
      let(:create_user_mails) { [] }
    end

    # テスト内容
    shared_examples_for 'ToOK(html/*)' do
      let(:power) { :admin }
      before do
        allow_any_instance_of(MembersController).to receive(:flash).and_return(
          { emails:, exist_user_mails:, create_user_mails:, power: }
        )
      end
      it 'HTTPステータスが200。対象項目が含まれる' do
        is_expected.to eq(200)
        expect_space_html(response, space)

        expect(response.body).to include("#{emails.count}名中")
        expect(response.body).to include("招待: #{create_user_mails.count}名")
        expect(response.body).to include("参加中: #{exist_user_mails.count}名")
        expect(response.body).to include("未登録: #{emails.count - create_user_mails.count - exist_user_mails.count}名")

        emails.each do |email|
          expect(response.body).to include(email)
        end
        if create_user_mails.count > 0
          expect(response.body).to include('招待しました。')
          expect(response.body).to include(Member.powers_i18n[:admin])
        else
          expect(response.body).not_to include('招待しました。')
        end
        if exist_user_mails.count > 0
          expect(response.body).to include('既に参加しています。')
        else
          expect(response.body).not_to include('既に参加しています。')
        end
        if (emails.count - create_user_mails.count - exist_user_mails.count) > 0
          expect(response.body).to include('アカウントが存在しません。登録後に招待してください。')
        else
          expect(response.body).not_to include('アカウントが存在しません。登録後に招待してください。')
        end
      end
    end

    # テストケース
    if Settings.api_only_mode
      include_context 'APIログイン処理'
      include_context 'valid_condition'
      it_behaves_like 'ToNG(html)', 406
      it_behaves_like 'ToNG(json)', 406
      next
    end

    shared_examples_for '[ログイン中][*][ある]flashがある（3件）' do
      include_context 'set_flash_data'
      it_behaves_like 'ToOK(html)'
      it_behaves_like 'ToNG(json)', 406
    end
    shared_examples_for '[ログイン中][*][ある]flashがある（0件）' do
      include_context 'set_flash_data_blank'
      it_behaves_like 'ToOK(html)'
      it_behaves_like 'ToNG(json)', 406
    end
    shared_examples_for '[ログイン中][*][ある]flashがない' do
      it_behaves_like 'ToMembers(html)'
      it_behaves_like 'ToNG(json)', 406
    end

    shared_examples_for '[ログイン中][*]権限がある' do |power|
      before_all { FactoryBot.create(:member, power, space:, user:) }
      it_behaves_like '[ログイン中][*][ある]flashがある（3件）'
      it_behaves_like '[ログイン中][*][ある]flashがある（0件）'
      it_behaves_like '[ログイン中][*][ある]flashがない'
    end
    shared_examples_for '[ログイン中][*]権限がない' do |power|
      before_all { FactoryBot.create(:member, power, space:, user:) if power.present? }
      it_behaves_like 'ToNG(html)', 403
      it_behaves_like 'ToNG(json)', 406
    end

    shared_examples_for '[ログイン中]スペースが存在しない' do
      let_it_be(:space) { FactoryBot.build_stubbed(:space) }
      it_behaves_like 'ToNG(html)', 404
      it_behaves_like 'ToNG(json)', 406
    end
    shared_examples_for '[ログイン中]スペースが公開' do
      let_it_be(:space) { FactoryBot.create(:space, :public, created_user:) }
      it_behaves_like '[ログイン中][*]権限がある', :admin
      it_behaves_like '[ログイン中][*]権限がない', :writer
      it_behaves_like '[ログイン中][*]権限がない', :reader
      it_behaves_like '[ログイン中][*]権限がない', nil
    end
    shared_examples_for '[ログイン中]スペースが非公開' do
      let_it_be(:space) { FactoryBot.create(:space, :private, created_user:) }
      it_behaves_like '[ログイン中][*]権限がある', :admin
      it_behaves_like '[ログイン中][*]権限がない', :writer
      it_behaves_like '[ログイン中][*]権限がない', :reader
      it_behaves_like '[ログイン中][*]権限がない', nil
    end

    context '未ログイン' do
      include_context '未ログイン処理'
      include_context 'valid_condition'
      it_behaves_like 'ToLogin(html)'
      it_behaves_like 'ToNG(json)', 406
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中]スペースが存在しない'
      it_behaves_like '[ログイン中]スペースが公開'
      it_behaves_like '[ログイン中]スペースが非公開'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', :destroy_reserved
      include_context 'valid_condition'
      it_behaves_like 'ToMembers(html)', 'alert.user.destroy_reserved'
      it_behaves_like 'ToNG(json)', 406
    end
    context 'APIログイン中' do
      include_context 'APIログイン処理'
      include_context 'valid_condition'
      it_behaves_like 'ToOK(html)' # NOTE: HTMLもログイン状態になる
      it_behaves_like 'ToNG(json)', 406
    end
    context 'APIログイン中（削除予約済み）' do
      include_context 'APIログイン処理', :destroy_reserved
      include_context 'valid_condition'
      it_behaves_like 'ToMembers(html)', 'alert.user.destroy_reserved' # NOTE: HTMLもログイン状態になる
      it_behaves_like 'ToNG(json)', 406
    end
  end
end
