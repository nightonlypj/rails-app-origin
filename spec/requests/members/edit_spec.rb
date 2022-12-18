require 'rails_helper'

RSpec.describe 'Members', type: :request do
  let(:response_json) { response.body.present? ? JSON.parse(response.body) : {} }

  # GET /members/:code/update/:user_code メンバー情報変更
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）, APIログイン中, APIログイン中（削除予約済み）
  #   スペース: 存在しない, 公開, 非公開
  #   権限: ある（管理者）, ない（投稿者, 閲覧者, なし）
  #   対象メンバー: いる（他人, 自分）, いない
  #   ＋URLの拡張子: ない, .json
  #   ＋Acceptヘッダ: HTMLが含まれる, JSONが含まれる
  describe 'GET #edit' do
    subject { get edit_member_path(code: space.code, user_code: show_user.code, format: subject_format), headers: auth_headers.merge(accept_headers) }

    shared_context 'valid_condition' do
      let_it_be(:space)     { FactoryBot.create(:space) }
      let_it_be(:show_user) { FactoryBot.create(:user) }
      before_all do
        FactoryBot.create(:member, :admin, space: space, user: user) if user.present?
        FactoryBot.create(:member, space: space, user: show_user)
      end
    end

    # テストケース
    shared_examples_for 'ToOK(html/*)' do
      it_behaves_like 'ToOK[status]'
    end

    shared_examples_for '[ログイン中][*][ある]対象メンバーがいる（他人）' do
      let_it_be(:show_user) { FactoryBot.create(:user) }
      before_all            { FactoryBot.create(:member, space: space, user: show_user) }
      it_behaves_like 'ToOK(html)'
      it_behaves_like 'ToNG(json)', 406
    end
    shared_examples_for '[ログイン中][*][ある]対象メンバーがいる（自分）' do
      let_it_be(:show_user) { user }
      it_behaves_like 'ToNG(html)', 403
      it_behaves_like 'ToNG(json)', 406
    end
    shared_examples_for '[ログイン中][*][ある]対象メンバーがいない' do
      let_it_be(:show_user) { FactoryBot.create(:user) }
      it_behaves_like 'ToNG(html)', 404
      it_behaves_like 'ToNG(json)', 406
    end

    shared_examples_for '[ログイン中][*]権限がある' do |power|
      let(:user_power) { power }
      before_all { FactoryBot.create(:member, power: power, space: space, user: user) }
      it_behaves_like '[ログイン中][*][ある]対象メンバーがいる（他人）'
      it_behaves_like '[ログイン中][*][ある]対象メンバーがいる（自分）'
      it_behaves_like '[ログイン中][*][ある]対象メンバーがいない'
    end
    shared_examples_for '[ログイン中][*]権限がない' do |power|
      let(:user_power) { power }
      let_it_be(:show_user) { FactoryBot.create(:user) }
      before_all do
        FactoryBot.create(:member, power: power, space: space, user: user) if power.present?
        FactoryBot.create(:member, space: space, user: show_user)
      end
      it_behaves_like 'ToNG(html)', 403
      it_behaves_like 'ToNG(json)', 406
    end

    shared_examples_for '[ログイン中]スペースが存在しない' do
      let_it_be(:space)     { FactoryBot.build_stubbed(:space) }
      let_it_be(:show_user) { FactoryBot.create(:user) }
      it_behaves_like 'ToNG(html)', 404
      it_behaves_like 'ToNG(json)', 406
    end
    shared_examples_for '[ログイン中]スペースが公開' do
      let_it_be(:space) { FactoryBot.create(:space, :public) }
      it_behaves_like '[ログイン中][*]権限がある', :admin
      it_behaves_like '[ログイン中][*]権限がない', :writer
      it_behaves_like '[ログイン中][*]権限がない', :reader
      it_behaves_like '[ログイン中][*]権限がない', nil
    end
    shared_examples_for '[ログイン中]スペースが非公開' do
      let_it_be(:space) { FactoryBot.create(:space, :private) }
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
      it_behaves_like '[ログイン中]スペースが存在しない' # NOTE: HTMLもログイン状態になる
      it_behaves_like '[ログイン中]スペースが公開'
      it_behaves_like '[ログイン中]スペースが非公開'
    end
    context 'APIログイン中（削除予約済み）' do
      include_context 'APIログイン処理', :destroy_reserved
      include_context 'valid_condition'
      it_behaves_like 'ToMembers(html)', 'alert.user.destroy_reserved' # NOTE: HTMLもログイン状態になる
      it_behaves_like 'ToNG(json)', 406
    end
  end
end
