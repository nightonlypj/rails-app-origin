require 'rails_helper'

RSpec.describe 'Users::Unlocks', type: :request do
  # GET /users/unlock/new アカウントロック解除[メール再送]
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  describe 'GET #new' do
    subject { get new_user_unlock_path }

    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        is_expected.to eq(200)
      end
    end
    shared_examples_for 'ToTop' do |alert, notice|
      it 'トップページにリダイレクトする' do
        is_expected.to redirect_to(root_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    context '未ログイン' do
      it_behaves_like 'ToOK'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', :user_destroy_reserved
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
  end

  # POST /users/unlock/new アカウントロック解除[メール再送](処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   有効なパラメータ（ロック中, 未ロック）, 無効なパラメータ → 事前にデータ作成
  describe 'POST #create' do
    subject { post create_user_unlock_path, params: { user: attributes } }
    let(:send_user_locked)   { FactoryBot.create(:user_locked) }
    let(:send_user_unlocked) { FactoryBot.create(:user) }
    let(:not_user)           { FactoryBot.attributes_for(:user) }
    let(:valid_attributes)   { { email: send_user.email } }
    let(:invalid_attributes) { { email: not_user[:email] } }

    # テスト内容
    shared_examples_for 'OK' do
      it 'メールが送信される' do
        subject
        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect(ActionMailer::Base.deliveries[0].subject).to eq(get_subject('devise.mailer.unlock_instructions.subject')) # アカウントロックのお知らせ
      end
    end
    shared_examples_for 'NG' do
      it 'メールが送信されない' do
        expect { subject }.to change(ActionMailer::Base.deliveries, :count).by(0)
      end
    end

    shared_examples_for 'ToError' do |error_msg|
      it '成功ステータス。対象のエラーメッセージが含まれる' do # Tips: 再入力
        is_expected.to eq(200)
        expect(response.body).to include(I18n.t(error_msg))
      end
    end
    shared_examples_for 'ToTop' do |alert, notice|
      it 'トップページにリダイレクトする' do
        is_expected.to redirect_to(root_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToLogin' do |alert, notice|
      it 'ログインにリダイレクトする' do
        is_expected.to redirect_to(new_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]有効なパラメータ（ロック中）' do
      let(:send_user)  { send_user_locked }
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      it_behaves_like 'ToLogin', nil, 'devise.unlocks.send_instructions'
    end
    shared_examples_for '[ログイン中/削除予約済み]有効なパラメータ（ロック中）' do
      let(:send_user)  { send_user_locked }
      let(:attributes) { valid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]有効なパラメータ（未ロック）' do
      let(:send_user)  { send_user_unlocked }
      let(:attributes) { valid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToError', 'errors.messages.not_locked', nil
    end
    shared_examples_for '[ログイン中/削除予約済み]有効なパラメータ（未ロック）' do
      let(:send_user)  { send_user_unlocked }
      let(:attributes) { valid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToError', 'errors.messages.not_found'
    end
    shared_examples_for '[ログイン中/削除予約済み]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]有効なパラメータ（ロック中）'
      it_behaves_like '[未ログイン]有効なパラメータ（未ロック）'
      it_behaves_like '[未ログイン]無効なパラメータ'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ（ロック中）'
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ（未ロック）'
      it_behaves_like '[ログイン中/削除予約済み]無効なパラメータ'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', :user_destroy_reserved
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ（ロック中）'
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ（未ロック）'
      it_behaves_like '[ログイン中/削除予約済み]無効なパラメータ'
    end
  end

  # GET /users/unlock アカウントロック解除(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   トークン: 存在する, 存在しない, ない → データ作成
  #   ロック日時: ない（未ロック）, ある（ロック中） → データ作成
  describe 'GET #show' do
    subject { get user_unlock_path(unlock_token: unlock_token) }

    # テスト内容
    shared_examples_for 'OK' do
      it 'アカウントロック日時がなしに変更される' do
        subject
        expect(User.find(send_user.id).locked_at).to be_nil
      end
    end
    shared_examples_for 'NG' do
      it 'アカウントロック日時が変更されない' do
        subject
        expect(User.find(send_user.id).locked_at).to eq(send_user.locked_at)
      end
    end

    shared_examples_for 'ToError' do |error_msg|
      it '成功ステータス。対象のエラーメッセージが含まれる' do # Tips: 再入力
        is_expected.to eq(200)
        expect(response.body).to include(I18n.t(error_msg))
      end
    end
    shared_examples_for 'ToTop' do |alert, notice|
      it 'トップページにリダイレクトする' do
        is_expected.to redirect_to(root_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToLogin' do |alert, notice|
      it 'ログインにリダイレクトする' do
        is_expected.to redirect_to(new_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[未ログイン][存在する]ロック日時がない（未ロック）' do
      include_context 'アカウントロック解除トークン作成', false
      # it_behaves_like 'NG' # Tips: 元々、ロック日時がない
      it_behaves_like 'ToLogin', nil, 'devise.unlocks.unlocked' # Tips: 既に解除済み
    end
    shared_examples_for '[ログイン中/削除予約済み][存在する]ロック日時がない（未ロック）' do
      include_context 'アカウントロック解除トークン作成', false
      # it_behaves_like 'NG' # Tips: 元々、ロック日時がない
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン][存在しない]ロック日時がない（未ロック）' do
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、ロック日時がない
      it_behaves_like 'ToError', 'activerecord.errors.models.user.attributes.unlock_token.invalid'
    end
    shared_examples_for '[ログイン中/削除予約済み][存在しない]ロック日時がない（未ロック）' do
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、ロック日時がない
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン][ない]ロック日時がない（未ロック）' do
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、ロック日時がない
      it_behaves_like 'ToError', 'activerecord.errors.models.user.attributes.unlock_token.blank'
    end
    shared_examples_for '[ログイン中/削除予約済み][ない]ロック日時がない（未ロック）' do
      # it_behaves_like 'NG' # Tips: トークンが存在しない為、ロック日時がない
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン][存在する]ロック日時がある（ロック中）' do
      include_context 'アカウントロック解除トークン作成', true
      it_behaves_like 'OK'
      it_behaves_like 'ToLogin', nil, 'devise.unlocks.unlocked'
    end
    shared_examples_for '[ログイン中/削除予約済み][存在する]ロック日時がある（ロック中）' do
      include_context 'アカウントロック解除トークン作成', true
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end

    shared_examples_for '[未ログイン]トークンが存在する' do
      it_behaves_like '[未ログイン][存在する]ロック日時がない（未ロック）'
      it_behaves_like '[未ログイン][存在する]ロック日時がある（ロック中）'
    end
    shared_examples_for '[ログイン中/削除予約済み]トークンが存在する' do
      it_behaves_like '[ログイン中/削除予約済み][存在する]ロック日時がない（未ロック）'
      it_behaves_like '[ログイン中/削除予約済み][存在する]ロック日時がある（ロック中）'
    end
    shared_examples_for '[未ログイン]トークンが存在しない' do
      let(:unlock_token) { NOT_TOKEN }
      it_behaves_like '[未ログイン][存在しない]ロック日時がない（未ロック）'
      # it_behaves_like '[未ログイン][存在しない]ロック日時がある（ロック中）' # Tips: トークンが存在しない為、ロック日時がない
    end
    shared_examples_for '[ログイン中/削除予約済み]トークンが存在しない' do
      let(:unlock_token) { NOT_TOKEN }
      it_behaves_like '[ログイン中/削除予約済み][存在しない]ロック日時がない（未ロック）'
      # it_behaves_like '[ログイン中/削除予約済み][存在しない]ロック日時がある（ロック中）' # Tips: トークンが存在しない為、ロック日時がない
    end
    shared_examples_for '[未ログイン]トークンがない' do
      let(:unlock_token) { nil }
      it_behaves_like '[未ログイン][ない]ロック日時がない（未ロック）'
      # it_behaves_like '[未ログイン][ない]ロック日時がある（ロック中）' # Tips: トークンが存在しない為、ロック日時がない
    end
    shared_examples_for '[ログイン中/削除予約済み]トークンがない' do
      let(:unlock_token) { nil }
      it_behaves_like '[ログイン中/削除予約済み][ない]ロック日時がない（未ロック）'
      # it_behaves_like '[ログイン中/削除予約済み][ない]ロック日時がある（ロック中）' # Tips: トークンが存在しない為、ロック日時がない
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]トークンが存在する'
      it_behaves_like '[未ログイン]トークンが存在しない'
      it_behaves_like '[未ログイン]トークンがない'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中/削除予約済み]トークンが存在する'
      it_behaves_like '[ログイン中/削除予約済み]トークンが存在しない'
      it_behaves_like '[ログイン中/削除予約済み]トークンがない'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', :user_destroy_reserved
      it_behaves_like '[ログイン中/削除予約済み]トークンが存在する'
      it_behaves_like '[ログイン中/削除予約済み]トークンが存在しない'
      it_behaves_like '[ログイン中/削除予約済み]トークンがない'
    end
  end
end
