require 'rails_helper'

RSpec.describe 'AdminUsers::Unlocks', type: :request do
  # GET /admin/unlock/resend アカウントロック解除[メール再送]
  # テストパターン
  #   未ログイン, ログイン中
  describe 'GET #new' do
    subject { get new_admin_user_unlock_path }

    # テストケース
    context '未ログイン' do
      it_behaves_like 'ToOK[status]'
    end
    context 'ログイン中' do
      include_context 'ログイン処理（管理者）'
      it_behaves_like 'ToAdmin', 'devise.failure.already_authenticated', nil
    end
  end

  # POST /admin/unlock/resend アカウントロック解除[メール再送](処理)
  # テストパターン
  #   未ログイン, ログイン中
  #   有効なパラメータ（ロック中, 未ロック）, 無効なパラメータ
  describe 'POST #create' do
    subject { post create_admin_user_unlock_path, params: { admin_user: attributes } }
    let_it_be(:send_admin_user_locked)   { FactoryBot.create(:admin_user, :locked) }
    let_it_be(:send_admin_user_unlocked) { FactoryBot.create(:admin_user) }
    let_it_be(:not_admin_user)           { FactoryBot.attributes_for(:admin_user) }
    let(:valid_attributes)   { { email: send_admin_user.email } }
    let(:invalid_attributes) { { email: not_admin_user[:email] } }

    # テスト内容
    shared_examples_for 'OK' do
      let(:url) { "http://#{Settings.base_domain}#{admin_user_unlock_path}" }
      it 'メールが送信される' do
        subject
        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect(ActionMailer::Base.deliveries[0].subject).to eq(get_subject('devise.mailer.unlock_instructions.admin_user_subject')) # アカウントロックのお知らせ
        expect(ActionMailer::Base.deliveries[0].html_part.body).to include(url)
        expect(ActionMailer::Base.deliveries[0].text_part.body).to include(url)
      end
    end
    shared_examples_for 'NG' do
      it 'メールが送信されない' do
        expect { subject }.to change(ActionMailer::Base.deliveries, :count).by(0)
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]有効なパラメータ（ロック中）' do
      let(:send_admin_user) { send_admin_user_locked }
      let(:attributes)      { valid_attributes }
      it_behaves_like 'OK'
      it_behaves_like 'ToAdminLogin', nil, 'devise.unlocks.send_instructions'
    end
    shared_examples_for '[ログイン中]有効なパラメータ（ロック中）' do
      let(:send_admin_user) { send_admin_user_locked }
      let(:attributes)      { valid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToAdmin', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]有効なパラメータ（未ロック）' do
      let(:send_admin_user) { send_admin_user_unlocked }
      let(:attributes)      { valid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToError', 'errors.messages.not_locked', nil
    end
    shared_examples_for '[ログイン中]有効なパラメータ（未ロック）' do
      let(:send_admin_user) { send_admin_user_unlocked }
      let(:attributes)      { valid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToAdmin', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToError', 'errors.messages.not_found'
    end
    shared_examples_for '[ログイン中]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToAdmin', 'devise.failure.already_authenticated', nil
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]有効なパラメータ（ロック中）'
      it_behaves_like '[未ログイン]有効なパラメータ（未ロック）'
      it_behaves_like '[未ログイン]無効なパラメータ'
    end
    context 'ログイン中' do
      include_context 'ログイン処理（管理者）'
      it_behaves_like '[ログイン中]有効なパラメータ（ロック中）'
      it_behaves_like '[ログイン中]有効なパラメータ（未ロック）'
      it_behaves_like '[ログイン中]無効なパラメータ'
    end
  end

  # GET /admin/unlock アカウントロック解除(処理)
  # テストパターン
  #   未ログイン, ログイン中
  #   トークン: 存在する, 存在しない, ない
  #   ロック日時: ない（未ロック）, 期限内（ロック中）, 期限切れ（未ロック）
  describe 'GET #show' do
    subject { get admin_user_unlock_path(unlock_token:) }
    let(:current_admin_user) { AdminUser.find(send_admin_user.id) }

    # テスト内容
    shared_examples_for 'OK' do
      it 'アカウントロック日時がなしに回数が0に変更される' do
        subject
        expect(current_admin_user.locked_at).to be_nil
        expect(current_admin_user.failed_attempts).to eq(0)
      end
    end
    shared_examples_for 'NG' do
      it 'アカウントロック日時・回数が変更されない' do
        subject
        expect(current_admin_user.locked_at).to eq(send_admin_user.locked_at)
        expect(current_admin_user.failed_attempts).to eq(send_admin_user.failed_attempts)
      end
    end

    # テストケース
    shared_examples_for '[未ログイン][存在する]ロック日時がない（未ロック）' do
      include_context 'アカウントロック解除トークン作成（管理者）', false
      it_behaves_like 'NG'
      it_behaves_like 'ToAdminLogin', nil, 'devise.unlocks.unlocked' # NOTE: 既に解除済み
    end
    shared_examples_for '[ログイン中][存在する]ロック日時がない（未ロック）' do
      include_context 'アカウントロック解除トークン作成（管理者）', false
      it_behaves_like 'NG'
      it_behaves_like 'ToAdmin', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン][存在しない]ロック日時がない（未ロック）' do
      # it_behaves_like 'NG' # NOTE: トークンが存在しない為、ロック日時がない
      it_behaves_like 'ToError', 'activerecord.errors.models.admin_user.attributes.unlock_token.invalid'
    end
    shared_examples_for '[ログイン中][存在しない]ロック日時がない（未ロック）' do
      # it_behaves_like 'NG' # NOTE: トークンが存在しない為、ロック日時がない
      it_behaves_like 'ToAdmin', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン][ない]ロック日時がない（未ロック）' do
      # it_behaves_like 'NG' # NOTE: トークンが存在しない為、ロック日時がない
      it_behaves_like 'ToError', 'activerecord.errors.models.admin_user.attributes.unlock_token.blank'
    end
    shared_examples_for '[ログイン中][ない]ロック日時がない（未ロック）' do
      # it_behaves_like 'NG' # NOTE: トークンが存在しない為、ロック日時がない
      it_behaves_like 'ToAdmin', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン][存在する]ロック日時が期限内（ロック中）' do
      include_context 'アカウントロック解除トークン作成（管理者）', true
      it_behaves_like 'OK'
      it_behaves_like 'ToAdminLogin', nil, 'devise.unlocks.unlocked'
    end
    shared_examples_for '[ログイン中][存在する]ロック日時が期限内（ロック中）' do
      include_context 'アカウントロック解除トークン作成（管理者）', true
      it_behaves_like 'NG'
      it_behaves_like 'ToAdmin', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン][存在する]ロック日時が期限切れ（未ロック）' do
      include_context 'アカウントロック解除トークン作成（管理者）', true, true
      it_behaves_like 'OK'
      it_behaves_like 'ToAdminLogin', nil, 'devise.unlocks.unlocked' # NOTE: 解除されても良さそう
    end
    shared_examples_for '[ログイン中][存在する]ロック日時が期限切れ（未ロック）' do
      include_context 'アカウントロック解除トークン作成（管理者）', true, true
      it_behaves_like 'NG'
      it_behaves_like 'ToAdmin', 'devise.failure.already_authenticated', nil
    end

    shared_examples_for '[未ログイン]トークンが存在する' do
      it_behaves_like '[未ログイン][存在する]ロック日時がない（未ロック）'
      it_behaves_like '[未ログイン][存在する]ロック日時が期限内（ロック中）'
      it_behaves_like '[未ログイン][存在する]ロック日時が期限切れ（未ロック）'
    end
    shared_examples_for '[ログイン中]トークンが存在する' do
      it_behaves_like '[ログイン中][存在する]ロック日時がない（未ロック）'
      it_behaves_like '[ログイン中][存在する]ロック日時が期限内（ロック中）'
      it_behaves_like '[ログイン中][存在する]ロック日時が期限切れ（未ロック）'
    end
    shared_examples_for '[未ログイン]トークンが存在しない' do
      let(:unlock_token) { NOT_TOKEN }
      it_behaves_like '[未ログイン][存在しない]ロック日時がない（未ロック）'
      # it_behaves_like '[未ログイン][存在しない]ロック日時が期限内（ロック中）' # NOTE: トークンが存在しない為、ロック日時がない
      # it_behaves_like '[未ログイン][存在しない]ロック日時が期限切れ（未ロック）' # NOTE: トークンが存在しない為、ロック日時がない
    end
    shared_examples_for '[ログイン中]トークンが存在しない' do
      let(:unlock_token) { NOT_TOKEN }
      it_behaves_like '[ログイン中][存在しない]ロック日時がない（未ロック）'
      # it_behaves_like '[ログイン中][存在しない]ロック日時が期限内（ロック中）' # NOTE: トークンが存在しない為、ロック日時がない
      # it_behaves_like '[ログイン中][存在しない]ロック日時が期限切れ（未ロック）' # NOTE: トークンが存在しない為、ロック日時がない
    end
    shared_examples_for '[未ログイン]トークンがない' do
      let(:unlock_token) { nil }
      it_behaves_like '[未ログイン][ない]ロック日時がない（未ロック）'
      # it_behaves_like '[未ログイン][ない]ロック日時が期限内（ロック中）' # NOTE: トークンが存在しない為、ロック日時がない
      # it_behaves_like '[未ログイン][ない]ロック日時が期限切れ（未ロック）' # NOTE: トークンが存在しない為、ロック日時がない
    end
    shared_examples_for '[ログイン中]トークンがない' do
      let(:unlock_token) { nil }
      it_behaves_like '[ログイン中][ない]ロック日時がない（未ロック）'
      # it_behaves_like '[ログイン中][ない]ロック日時が期限内（ロック中）' # NOTE: トークンが存在しない為、ロック日時がない
      # it_behaves_like '[ログイン中][ない]ロック日時が期限切れ（未ロック）' # NOTE: トークンが存在しない為、ロック日時がない
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]トークンが存在する'
      it_behaves_like '[未ログイン]トークンが存在しない'
      it_behaves_like '[未ログイン]トークンがない'
    end
    context 'ログイン中' do
      include_context 'ログイン処理（管理者）'
      it_behaves_like '[ログイン中]トークンが存在する'
      it_behaves_like '[ログイン中]トークンが存在しない'
      it_behaves_like '[ログイン中]トークンがない'
    end
  end
end
