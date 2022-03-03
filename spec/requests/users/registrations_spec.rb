require 'rails_helper'

RSpec.describe 'Users::Registrations', type: :request do
  # テスト内容（共通）
  shared_examples_for 'ToOK' do
    it 'HTTPステータスが200' do
      is_expected.to eq(200)
    end
  end
  shared_examples_for 'ToError' do |error_msg|
    it 'HTTPステータスが200。対象のエラーメッセージが含まれる' do # Tips: 再入力
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
  shared_examples_for 'ToEdit' do |alert, notice|
    it '登録情報変更にリダイレクトする' do
      is_expected.to redirect_to(edit_user_registration_path)
      expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
      expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
    end
  end

  # GET /users/sign_up アカウント登録
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中
  describe 'GET #new' do
    subject { get new_user_registration_path }

    # テストケース
    context '未ログイン' do
      it_behaves_like 'ToOK'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
  end

  # POST /users/sign_up アカウント登録(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中
  #   有効なパラメータ, 無効なパラメータ
  describe 'POST #create' do
    subject { post create_user_registration_path, params: { user: attributes } }
    let(:new_user)   { FactoryBot.attributes_for(:user) }
    let(:exist_user) { FactoryBot.create(:user) }
    let(:valid_attributes)   { { name: new_user[:name], email: new_user[:email], password: new_user[:password] } }
    let(:invalid_attributes) { { name: exist_user.name, email: exist_user.email, password: exist_user.password } }
    let(:current_user) { User.find_by!(email: attributes[:email]) }

    # テスト内容
    shared_examples_for 'OK' do
      let(:url) { "http://#{Settings['base_domain']}#{user_confirmation_path}" }
      it '作成・対象項目が設定される。メールが送信される' do
        expect do
          subject
          expect(current_user.name).to eq(attributes[:name]) # メールアドレス、氏名

          expect(ActionMailer::Base.deliveries.count).to eq(1)
          expect(ActionMailer::Base.deliveries[0].subject).to eq(get_subject('devise.mailer.confirmation_instructions.subject')) # メールアドレス確認のお願い
          expect(ActionMailer::Base.deliveries[0].html_part.body).to include(url)
          expect(ActionMailer::Base.deliveries[0].text_part.body).to include(url)
        end.to change(User, :count).by(1)
      end
    end
    shared_examples_for 'NG' do
      it '作成されない。メールが送信されない' do
        expect { subject }.to change(User, :count).by(0) && change(ActionMailer::Base.deliveries, :count).by(0)
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      it_behaves_like 'ToLogin', nil, 'devise.registrations.signed_up_but_unconfirmed'
    end
    shared_examples_for '[ログイン中]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToError', 'activerecord.errors.models.user.attributes.email.taken'
    end
    shared_examples_for '[ログイン中]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]有効なパラメータ'
      it_behaves_like '[未ログイン]無効なパラメータ'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中]有効なパラメータ'
      it_behaves_like '[ログイン中]無効なパラメータ'
    end
  end

  # GET /users/edit 登録情報変更
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（メールアドレス変更中, 削除予約済み）
  describe 'GET #edit' do
    subject { get edit_user_registration_path }

    # テストケース
    context '未ログイン' do
      it_behaves_like 'ToLogin', 'devise.failure.unauthenticated', nil
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'ToOK'
    end
    context 'ログイン中（メールアドレス変更中）' do
      include_context 'ログイン処理', :user_email_changed
      it_behaves_like 'ToOK'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', :user_destroy_reserved
      it_behaves_like 'ToTop', 'alert.user.destroy_reserved', nil
    end
  end

  # PUT /users/edit 登録情報変更(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（メールアドレス変更中, 削除予約済み）
  #   有効なパラメータ（変更なし, あり）, 無効なパラメータ
  describe 'PUT #update' do
    subject { put update_user_registration_path, params: { user: attributes.merge(current_password: current_password) } }
    let(:new_user)   { FactoryBot.attributes_for(:user) }
    let(:exist_user) { FactoryBot.create(:user) }
    let(:nochange_attributes) { { name: user.name, email: user.email, password: user.password } }
    let(:valid_attributes)    { { name: new_user[:name], email: new_user[:email], password: new_user[:password] } }
    let(:invalid_attributes)  { { name: exist_user.name, email: exist_user.email, password: exist_user.password } }
    let(:current_user) { User.find(user.id) }

    # テスト内容
    shared_examples_for 'OK' do |change_email|
      let(:url) { "http://#{Settings['base_domain']}#{user_confirmation_path}" }
      it '対象項目が変更される。メールが送信される' do
        subject
        expect(current_user.unconfirmed_email).to change_email ? eq(attributes[:email]) : eq(user.unconfirmed_email) # 確認待ちメールアドレス
        expect(current_user.name).to eq(attributes[:name]) # 氏名
        expect(current_user.image.url).to eq(user.image.url) # 画像 # Tips: 変更されない

        expect(ActionMailer::Base.deliveries.count).to eq(change_email ? 3 : 1)
        expect(ActionMailer::Base.deliveries[0].subject).to eq(get_subject('devise.mailer.email_changed.subject')) if change_email # メールアドレス変更受け付けのお知らせ
        expect(ActionMailer::Base.deliveries[change_email ? 1 : 0].subject).to eq(get_subject('devise.mailer.password_change.subject')) # パスワード変更完了のお知らせ
        if change_email
          expect(ActionMailer::Base.deliveries[2].subject).to eq(get_subject('devise.mailer.confirmation_instructions.subject')) # メールアドレス確認のお願い
          expect(ActionMailer::Base.deliveries[2].html_part.body).to include(url)
          expect(ActionMailer::Base.deliveries[2].text_part.body).to include(url)
        end
      end
    end
    shared_examples_for 'NG' do
      it '対象項目が変更されない。メールが送信されない' do
        subject
        expect(current_user.unconfirmed_email).to eq(user.unconfirmed_email) # 確認待ちメールアドレス
        expect(current_user.name).to eq(user.name) # 氏名
        expect(current_user.image.url).to eq(user.image.url) # 画像

        expect(ActionMailer::Base.deliveries.count).to eq(0)
      end
    end

    # テストケース
    shared_examples_for '[ログイン中]有効なパラメータ（変更なし）' do
      let(:attributes) { nochange_attributes }
      it_behaves_like 'OK', false
      it_behaves_like 'ToTop', nil, 'devise.registrations.updated'
    end
    shared_examples_for '[削除予約済み]有効なパラメータ（変更なし）' do
      let(:attributes) { nochange_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'alert.user.destroy_reserved', nil
    end
    shared_examples_for '[未ログイン]有効なパラメータ（変更あり）' do
      let(:attributes) { valid_attributes }
      # it_behaves_like 'NG' # Tips: 未ログインの為、対象がない
      it_behaves_like 'ToLogin', 'devise.failure.unauthenticated', nil
    end
    shared_examples_for '[ログイン中]有効なパラメータ（変更あり）' do
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK', true
      it_behaves_like 'ToTop', nil, 'devise.registrations.update_needs_confirmation'
    end
    shared_examples_for '[削除予約済み]有効なパラメータ（変更あり）' do
      let(:attributes) { valid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'alert.user.destroy_reserved', nil
    end
    shared_examples_for '[未ログイン]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      # it_behaves_like 'NG' # Tips: 未ログインの為、対象がない
      it_behaves_like 'ToLogin', 'devise.failure.unauthenticated', nil
    end
    shared_examples_for '[ログイン中]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      # it_behaves_like 'OK', true
      it_behaves_like 'NG'
      # it_behaves_like 'ToTop', nil, 'devise.registrations.update_needs_confirmation'
      it_behaves_like 'ToError', 'activerecord.errors.models.user.attributes.email.exist'
    end
    shared_examples_for '[削除予約済み]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'alert.user.destroy_reserved', nil
    end

    context '未ログイン' do
      let(:current_password) { nil }
      # it_behaves_like '[未ログイン]有効なパラメータ（変更なし）' # Tips: 未ログインの為、対象がない
      it_behaves_like '[未ログイン]有効なパラメータ（変更あり）'
      it_behaves_like '[未ログイン]無効なパラメータ'
    end
    context 'ログイン中' do
      include_context 'ログイン処理', :user, true
      let(:current_password) { user.password }
      it_behaves_like '[ログイン中]有効なパラメータ（変更なし）'
      it_behaves_like '[ログイン中]有効なパラメータ（変更あり）'
      it_behaves_like '[ログイン中]無効なパラメータ'
    end
    context 'ログイン中（メールアドレス変更中）' do
      include_context 'ログイン処理', :user_email_changed, true
      let(:current_password) { user.password }
      it_behaves_like '[ログイン中]有効なパラメータ（変更なし）'
      it_behaves_like '[ログイン中]有効なパラメータ（変更あり）'
      it_behaves_like '[ログイン中]無効なパラメータ'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', :user_destroy_reserved, true
      let(:current_password) { user.password }
      it_behaves_like '[削除予約済み]有効なパラメータ（変更なし）'
      it_behaves_like '[削除予約済み]有効なパラメータ（変更あり）'
      it_behaves_like '[削除予約済み]無効なパラメータ'
    end
  end

  # POST /users/image/update 画像変更(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）
  #   有効なパラメータ, 無効なパラメータ
  describe 'POST #image_update' do
    subject { post update_user_image_registration_path, params: { user: attributes } }
    let(:valid_attributes)   { { image: fixture_file_upload(TEST_IMAGE_FILE, TEST_IMAGE_TYPE) } }
    let(:invalid_attributes) { nil }
    let(:current_user) { User.find(user.id) }

    # テスト内容
    shared_examples_for 'OK' do
      it '画像が変更される' do
        subject
        expect(current_user.image.url).not_to eq(user.image.url)
      end
    end
    shared_examples_for 'NG' do
      it '画像が変更されない' do
        subject
        expect(current_user.image.url).to eq(user.image.url)
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      # it_behaves_like 'NG' # Tips: 未ログインの為、対象がない
      it_behaves_like 'ToLogin', 'devise.failure.unauthenticated', nil
    end
    shared_examples_for '[ログイン中]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      it_behaves_like 'ToEdit', nil, 'notice.user.image_update'
      after do
        current_user.remove_image!
        current_user.save!
      end
    end
    shared_examples_for '[削除予約済み]有効なパラメータ' do
      let(:attributes) { valid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'alert.user.destroy_reserved', nil
    end
    shared_examples_for '[未ログイン]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      # it_behaves_like 'NG' # Tips: 未ログインの為、対象がない
      it_behaves_like 'ToLogin', 'devise.failure.unauthenticated', nil
    end
    shared_examples_for '[ログイン中]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToError', 'errors.messages.image_update_blank'
    end
    shared_examples_for '[削除予約済み]無効なパラメータ' do
      let(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'alert.user.destroy_reserved', nil
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]有効なパラメータ'
      it_behaves_like '[未ログイン]無効なパラメータ'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中]有効なパラメータ'
      it_behaves_like '[ログイン中]無効なパラメータ'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', :user_destroy_reserved
      it_behaves_like '[削除予約済み]有効なパラメータ'
      it_behaves_like '[削除予約済み]無効なパラメータ'
    end
  end

  # POST /users/image/destroy 画像削除(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）
  describe 'POST #image_destroy' do
    subject { post delete_user_image_registration_path }
    let(:current_user) { User.find(user.id) }

    # テスト内容
    shared_examples_for 'OK' do
      it '画像が削除される' do
        subject
        expect(current_user.image.url).to be_nil
      end
    end
    shared_examples_for 'NG' do
      it '画像が変更されない' do
        subject
        expect(current_user.image.url).to eq(user.image.url)
      end
    end

    # テストケース
    context '未ログイン' do
      # it_behaves_like 'NG' # Tips: 未ログインの為、対象がない
      it_behaves_like 'ToLogin', 'devise.failure.unauthenticated', nil
    end
    context 'ログイン中' do
      include_context 'ログイン処理', :user, true
      it_behaves_like 'OK'
      it_behaves_like 'ToEdit', nil, 'notice.user.image_destroy'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', :user_destroy_reserved, true
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'alert.user.destroy_reserved', nil
    end
  end

  # GET /users/delete アカウント削除
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）
  describe 'GET #delete' do
    subject { get delete_user_registration_path }

    # テストケース
    context '未ログイン' do
      it_behaves_like 'ToLogin', 'devise.failure.unauthenticated', nil
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'ToOK'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', :user_destroy_reserved
      it_behaves_like 'ToTop', 'alert.user.destroy_reserved', nil
    end
  end

  # POST /users/delete アカウント削除(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）
  describe 'POST #destroy' do
    subject { post destroy_user_registration_path }
    let(:current_user) { User.find(user.id) }

    # テスト内容
    shared_examples_for 'OK' do
      let!(:start_time) { Time.current.floor }
      let(:url) { "http://#{Settings['base_domain']}#{delete_undo_user_registration_path}" }
      it "削除依頼日時が現在日時に、削除予定日時が#{Settings['destroy_schedule_days']}日後に変更される。メールが送信される" do
        subject
        expect(current_user.destroy_requested_at).to be_between(start_time, Time.current)
        expect(current_user.destroy_schedule_at).to be_between(start_time + Settings['destroy_schedule_days'].days,
                                                               Time.current + Settings['destroy_schedule_days'].days)
        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect(ActionMailer::Base.deliveries[0].subject).to eq(get_subject('mailer.user.destroy_reserved.subject')) # アカウント削除受け付けのお知らせ
        expect(ActionMailer::Base.deliveries[0].html_part.body).to include(url)
        expect(ActionMailer::Base.deliveries[0].text_part.body).to include(url)
      end
    end
    shared_examples_for 'NG' do
      let!(:before_destroy_requested_at) { user.destroy_requested_at }
      let!(:before_destroy_schedule_at)  { user.destroy_schedule_at }
      it '削除依頼日時・削除予定日時が変更されない。メールが送信されない' do
        subject
        expect(current_user.destroy_requested_at).to eq(before_destroy_requested_at)
        expect(current_user.destroy_schedule_at).to eq(before_destroy_schedule_at)
        expect(ActionMailer::Base.deliveries.count).to eq(0)
      end
    end

    # テストケース
    context '未ログイン' do
      # it_behaves_like 'NG' # Tips: 未ログインの為、対象がない
      it_behaves_like 'ToLogin', 'devise.failure.unauthenticated', nil
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'OK'
      it_behaves_like 'ToLogin', nil, 'devise.registrations.destroy_reserved'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', :user_destroy_reserved
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'alert.user.destroy_reserved', nil
    end
  end

  # GET /users/undo_delete アカウント削除取り消し
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）
  describe 'GET #undo_delete' do
    subject { get delete_undo_user_registration_path }

    # テストケース
    context '未ログイン' do
      it_behaves_like 'ToLogin', 'devise.failure.unauthenticated', nil
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'ToTop', 'alert.user.not_destroy_reserved', nil
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', :user_destroy_reserved
      it_behaves_like 'ToOK'
    end
  end

  # POST /users/undo_delete アカウント削除取り消し(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）
  describe 'POST #undo_destroy' do
    subject { post destroy_undo_user_registration_path }
    let(:current_user) { User.find(user.id) }

    # テスト内容
    shared_examples_for 'OK' do
      it '削除依頼日時・削除予定日時がなしに変更される。メールが送信される' do
        subject
        expect(current_user.destroy_requested_at).to be_nil
        expect(current_user.destroy_schedule_at).to be_nil
        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect(ActionMailer::Base.deliveries[0].subject).to eq(get_subject('mailer.user.undo_destroy_reserved.subject')) # アカウント削除取り消し完了のお知らせ
      end
    end
    shared_examples_for 'NG' do
      it '削除依頼日時・削除予定日時が変更されない。メールが送信されない' do
        subject
        expect(current_user.destroy_requested_at).to eq(user.destroy_requested_at)
        expect(current_user.destroy_schedule_at).to eq(user.destroy_schedule_at)
        expect(ActionMailer::Base.deliveries.count).to eq(0)
      end
    end

    # テストケース
    context '未ログイン' do
      # it_behaves_like 'NG' # Tips: 未ログインの為、対象がない
      it_behaves_like 'ToLogin', 'devise.failure.unauthenticated', nil
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'alert.user.not_destroy_reserved', nil
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', :user_destroy_reserved
      it_behaves_like 'OK'
      it_behaves_like 'ToTop', nil, 'devise.registrations.undo_destroy_reserved'
    end
  end
end
