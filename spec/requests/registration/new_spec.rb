require 'rails_helper'

RSpec.describe 'Registration', type: :request do
  # GET /registration/member（ベースドメイン） メンバー登録
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   招待完了日時: ない（未登録）, ある（登録済み） → データ作成
  #   トークン: 存在する, 存在しない, ない → データ作成
  #   ベースドメイン, 存在するサブドメイン, 存在しないサブドメイン → 事前にデータ作成
  describe 'GET #new' do
    include_context 'リクエストスペース作成'

    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get new_member_registration_path(invitation_token: invitation_token), headers: headers
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToTop' do |alert, notice|
      it 'トップページにリダイレクト' do
        get new_member_registration_path(invitation_token: invitation_token), headers: headers
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToLogin' do |alert, notice|
      it 'ログインにリダイレクト' do
        get new_member_registration_path(invitation_token: invitation_token), headers: headers
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToBase' do |alert, notice|
      it 'ベースドメインにリダイレクト' do
        get new_member_registration_path(invitation_token: invitation_token), headers: headers
        expect(response).to redirect_to("//#{Settings['base_domain']}#{new_member_registration_path(invitation_token: invitation_token)}")
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[未ログイン][未登録][存在する]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[ログイン中/削除予約済み][未登録][存在する]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToTop', 'alert.user.invitation_token.already_sign_in'
    end
    shared_examples_for '[未ログイン][*][存在する/しない]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToLogin', 'alert.user.invitation_token.invalid', nil
    end
    shared_examples_for '[ログイン中/削除予約済み][登録済み][存在する/しない]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToTop', 'alert.user.invitation_token.invalid'
    end
    shared_examples_for '[未ログイン][未登録][ない]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToLogin', 'alert.user.invitation_token.blank', nil
    end
    shared_examples_for '[ログイン中/削除予約済み][未登録][ない]ベースドメイン' do
      let!(:headers) { BASE_HEADER }
      it_behaves_like 'ToTop', 'alert.user.invitation_token.blank'
    end
    shared_examples_for '[*][*][*]存在するサブドメイン' do
      let!(:headers) { @space_header }
      it_behaves_like 'ToBase', nil, nil
    end
    shared_examples_for '[*][*][*]存在しないサブドメイン' do
      let!(:headers) { NOT_SPACE_HEADER }
      it_behaves_like 'ToBase', nil, nil
    end

    shared_examples_for '[未ログイン][未登録]トークンが存在する' do
      include_context '招待トークン作成'
      it_behaves_like '[未ログイン][未登録][存在する]ベースドメイン'
      it_behaves_like '[*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][未登録]トークンが存在する' do
      include_context '招待トークン作成'
      it_behaves_like '[ログイン中/削除予約済み][未登録][存在する]ベースドメイン'
      it_behaves_like '[*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][登録済み]トークンが存在する' do
      include_context '招待トークン作成'
      it_behaves_like '[未ログイン][*][存在する/しない]ベースドメイン'
      it_behaves_like '[*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][登録済み]トークンが存在する' do
      include_context '招待トークン作成'
      it_behaves_like '[ログイン中/削除予約済み][登録済み][存在する/しない]ベースドメイン'
      it_behaves_like '[*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][未登録]トークンが存在しない' do
      let!(:invitation_token) { NOT_TOKEN }
      it_behaves_like '[未ログイン][*][存在する/しない]ベースドメイン'
      it_behaves_like '[*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][未登録]トークンが存在しない' do
      let!(:invitation_token) { NOT_TOKEN }
      it_behaves_like '[ログイン中/削除予約済み][登録済み][存在する/しない]ベースドメイン'
      it_behaves_like '[*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[未ログイン][未登録]トークンがない' do
      let!(:invitation_token) { NO_TOKEN }
      it_behaves_like '[未ログイン][未登録][ない]ベースドメイン'
      it_behaves_like '[*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*]存在しないサブドメイン'
    end
    shared_examples_for '[ログイン中/削除予約済み][未登録]トークンがない' do
      let!(:invitation_token) { NO_TOKEN }
      it_behaves_like '[ログイン中/削除予約済み][未登録][ない]ベースドメイン'
      it_behaves_like '[*][*][*]存在するサブドメイン'
      it_behaves_like '[*][*][*]存在しないサブドメイン'
    end

    shared_examples_for '[未ログイン]招待完了日時がない（未登録）' do
      let!(:completed) { false }
      it_behaves_like '[未ログイン][未登録]トークンが存在する'
      it_behaves_like '[未ログイン][未登録]トークンが存在しない'
      it_behaves_like '[未ログイン][未登録]トークンがない'
    end
    shared_examples_for '[ログイン中/削除予約済み]招待完了日時がない（未登録）' do
      let!(:completed) { false }
      it_behaves_like '[ログイン中/削除予約済み][未登録]トークンが存在する'
      it_behaves_like '[ログイン中/削除予約済み][未登録]トークンが存在しない'
      it_behaves_like '[ログイン中/削除予約済み][未登録]トークンがない'
    end
    shared_examples_for '[未ログイン]招待完了日時がある（登録済み）' do
      let!(:completed) { true }
      it_behaves_like '[未ログイン][登録済み]トークンが存在する'
      # it_behaves_like '[未ログイン][登録済み]トークンが存在しない' # Tips: トークンが存在しない為、招待完了日時がない（未登録）
      # it_behaves_like '[未ログイン][登録済み]トークンがない' # Tips: トークンがない為、招待完了日時がない（未登録）
    end
    shared_examples_for '[ログイン中/削除予約済み]招待完了日時がある（登録済み）' do
      let!(:completed) { true }
      it_behaves_like '[ログイン中/削除予約済み][登録済み]トークンが存在する'
      # it_behaves_like '[ログイン中/削除予約済み][登録済み]トークンが存在しない' # Tips: トークンが存在しない為、招待完了日時がない（未登録）
      # it_behaves_like '[ログイン中/削除予約済み][登録済み]トークンがない' # Tips: トークンがない為、招待完了日時がない（未登録）
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]招待完了日時がない（未登録）'
      it_behaves_like '[未ログイン]招待完了日時がある（登録済み）'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中/削除予約済み]招待完了日時がない（未登録）'
      it_behaves_like '[ログイン中/削除予約済み]招待完了日時がある（登録済み）'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[ログイン中/削除予約済み]招待完了日時がない（未登録）'
      it_behaves_like '[ログイン中/削除予約済み]招待完了日時がある（登録済み）'
    end
  end
end
