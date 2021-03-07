require 'rails_helper'

RSpec.describe 'Spaces', type: :request do
  # GET /spaces/edit（サブドメイン） スペース情報変更
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   権限: ある(Owner, Admin), ない(Member含む) → データ作成
  #   ベースドメイン, 存在するサブドメイン, 存在しないサブドメイン → 事前にデータ作成
  describe 'GET /edit' do
    include_context 'リクエストスペース作成'

    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get edit_space_path, headers: headers
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToNot' do
      it '存在しないステータス' do
        get edit_space_path, headers: headers
        expect(response).to be_not_found
      end
    end
    shared_examples_for 'ToTop' do |alert, notice|
      it 'トップページにリダイレクト' do
        get edit_space_path, headers: headers
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToLogin' do |alert, notice|
      it 'ログインにリダイレクト' do
        get edit_space_path, headers: headers
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[*][*]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToNot'
    end
    shared_examples_for '[ログイン中][ある]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[削除予約済み][ある]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'ToTop', nil, 'notice.user.destroy_reserved'
    end
    shared_examples_for '[*][Member]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'ToTop', 'alert.space.not_update_power', nil
    end
    shared_examples_for '[*][ない]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'ToNot'
    end
    shared_examples_for '[未ログイン][ない]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'ToLogin', 'devise.failure.unauthenticated', nil
    end
    shared_examples_for '[*][*]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      it_behaves_like 'ToNot'
    end

    shared_examples_for '[ログイン中]権限がある' do |power|
      include_context '顧客・ユーザー紐付け', Time.current, power
      it_behaves_like '[*][*]ベースドメイン'
      it_behaves_like '[ログイン中][ある]存在するサブドメイン'
      it_behaves_like '[*][*]存在しないサブドメイン'
    end
    shared_examples_for '[削除予約済み]権限がある' do |power|
      include_context '顧客・ユーザー紐付け', Time.current, power
      it_behaves_like '[*][*]ベースドメイン'
      it_behaves_like '[削除予約済み][ある]存在するサブドメイン'
      it_behaves_like '[*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中]権限がMember' do
      include_context '顧客・ユーザー紐付け', Time.current, :Member
      it_behaves_like '[*][*]ベースドメイン'
      it_behaves_like '[*][Member]存在するサブドメイン'
      it_behaves_like '[*][*]存在しないサブドメイン'
    end
    shared_examples_for '[削除予約済み]権限がMember' do
      include_context '顧客・ユーザー紐付け', Time.current, :Member
      it_behaves_like '[*][*]ベースドメイン'
      it_behaves_like '[*][Member]存在するサブドメイン'
      it_behaves_like '[*][*]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン]権限がない' do
      it_behaves_like '[*][*]ベースドメイン'
      it_behaves_like '[未ログイン][ない]存在するサブドメイン'
      it_behaves_like '[*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中]権限がない' do
      it_behaves_like '[*][*]ベースドメイン'
      it_behaves_like '[*][ない]存在するサブドメイン'
      it_behaves_like '[*][*]存在しないサブドメイン'
    end
    shared_examples_for '[削除予約済み]権限がない' do
      it_behaves_like '[*][*]ベースドメイン'
      it_behaves_like '[*][ない]存在するサブドメイン'
      it_behaves_like '[*][*]存在しないサブドメイン'
    end

    context '未ログイン' do
      # it_behaves_like '[未ログイン]権限がある', :Owner # Tips: 未ログインの為、権限がない
      # it_behaves_like '[未ログイン]権限がある', :Admin # Tips: 未ログインの為、権限がない
      # it_behaves_like '[未ログイン]権限がMember' # Tips: 未ログインの為、権限がない
      it_behaves_like '[未ログイン]権限がない'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中]権限がある', :Owner
      it_behaves_like '[ログイン中]権限がある', :Admin
      it_behaves_like '[ログイン中]権限がMember'
      it_behaves_like '[ログイン中]権限がない'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[削除予約済み]権限がある', :Owner
      it_behaves_like '[削除予約済み]権限がある', :Admin
      it_behaves_like '[削除予約済み]権限がMember'
      it_behaves_like '[削除予約済み]権限がない'
    end
  end
end
