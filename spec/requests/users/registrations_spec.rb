require 'rails_helper'

RSpec.describe 'Users::Registrations', type: :request do
  # GET /users/sign_up アカウント登録
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  describe 'GET /new' do
    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get new_user_registration_path
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToTop' do |alert, notice|
      it 'トップページにリダイレクト' do
        get new_user_registration_path
        expect(response).to redirect_to(root_path)
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
      include_context 'ログイン処理', true
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
  end

  # POST /users/sign_up アカウント登録(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   有効なパラメータ, 無効なパラメータ → 事前にデータ作成
  describe 'POST /create' do
    let!(:valid_attributes) { FactoryBot.attributes_for(:user) }
    let!(:invalid_attributes) { FactoryBot.attributes_for(:user, email: nil) }

    # テスト内容
    shared_examples_for 'OK' do
      it '作成される' do
        expect do
          post create_user_registration_path, params: { user: attributes }
        end.to change(User, :count).by(1)
      end
    end
    shared_examples_for 'NG' do
      it '作成されない' do
        expect do
          post create_user_registration_path, params: { user: attributes }
        end.to change(User, :count).by(0)
      end
    end

    shared_examples_for 'ToError' do
      it '成功ステータス' do # Tips: 再入力
        post create_user_registration_path, params: { user: attributes }
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToTop' do |alert, notice|
      it 'トップページにリダイレクト' do
        post create_user_registration_path, params: { user: attributes }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToLogin' do |alert, notice|
      it 'ログインにリダイレクト' do
        post create_user_registration_path, params: { user: attributes }
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      it_behaves_like 'ToLogin', nil, 'devise.registrations.signed_up_but_unconfirmed'
    end
    shared_examples_for '[ログイン中/削除予約済み]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end
    shared_examples_for '[未ログイン]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToError'
    end
    shared_examples_for '[ログイン中/削除予約済み]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'devise.failure.already_authenticated', nil
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]有効なパラメータ'
      it_behaves_like '[未ログイン]無効なパラメータ'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ'
      it_behaves_like '[ログイン中/削除予約済み]無効なパラメータ'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[ログイン中/削除予約済み]有効なパラメータ'
      it_behaves_like '[ログイン中/削除予約済み]無効なパラメータ'
    end
  end

  # GET /users/edit 登録情報変更
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  describe 'GET /edit' do
    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get edit_user_registration_path
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToTop' do |alert, notice|
      it 'トップページにリダイレクト' do
        get edit_user_registration_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToLogin' do |alert, notice|
      it 'ログインにリダイレクト' do
        get edit_user_registration_path
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    context '未ログイン' do
      it_behaves_like 'ToLogin', 'devise.failure.unauthenticated', nil
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'ToOK'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like 'ToTop', 'alert.user.destroy_reserved', nil
    end
  end

  # PUT(PATCH) /users/edit 登録情報変更(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   有効なパラメータ, 無効なパラメータ → 事前にデータ作成
  describe 'PUT /update' do
    let!(:valid_attributes) { FactoryBot.attributes_for(:user) }
    let!(:invalid_attributes) { FactoryBot.attributes_for(:user, email: nil) }

    # テスト内容
    shared_examples_for 'OK' do
      it '氏名が変更される' do
        put update_user_registration_path, params: { user: attributes.merge(current_password: current_password) }
        expect(User.find(user.id).name).to eq(attributes[:name])
      end
    end
    shared_examples_for 'NG' do
      it '氏名が変更されない' do
        put update_user_registration_path, params: { user: attributes.merge(current_password: current_password) }
        expect(User.find(user.id).name).to eq(user.name)
      end
    end

    shared_examples_for 'ToError' do
      it '成功ステータス' do # Tips: 再入力
        put update_user_registration_path, params: { user: attributes.merge(current_password: current_password) }
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToTop' do |alert, notice|
      it 'トップページにリダイレクト' do
        put update_user_registration_path, params: { user: attributes.merge(current_password: current_password) }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToLogin' do |alert, notice|
      it 'ログインにリダイレクト' do
        put update_user_registration_path, params: { user: attributes.merge(current_password: current_password) }
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      # it_behaves_like 'NG' # Tips: 未ログインの為、対象がない
      it_behaves_like 'ToLogin', 'devise.failure.unauthenticated', nil
    end
    shared_examples_for '[ログイン中]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      it_behaves_like 'ToTop', nil, 'devise.registrations.update_needs_confirmation'
    end
    shared_examples_for '[削除予約済み]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'alert.user.destroy_reserved', nil
    end
    shared_examples_for '[未ログイン]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      # it_behaves_like 'NG' # Tips: 未ログインの為、対象がない
      it_behaves_like 'ToLogin', 'devise.failure.unauthenticated', nil
    end
    shared_examples_for '[ログイン中]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToError'
    end
    shared_examples_for '[削除予約済み]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'alert.user.destroy_reserved', nil
    end

    context '未ログイン' do
      let!(:current_password) { nil }
      it_behaves_like '[未ログイン]有効なパラメータ'
      it_behaves_like '[未ログイン]無効なパラメータ'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      include_context '画像登録処理'
      let!(:current_password) { user.password }
      it_behaves_like '[ログイン中]有効なパラメータ'
      it_behaves_like '[ログイン中]無効なパラメータ'
      include_context '画像削除処理'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      include_context '画像登録処理'
      let!(:current_password) { user.password }
      it_behaves_like '[削除予約済み]有効なパラメータ'
      it_behaves_like '[削除予約済み]無効なパラメータ'
      include_context '画像削除処理'
    end
  end

  # PUT(PATCH) /users/image 画像変更(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  #   有効なパラメータ, 無効なパラメータ → 事前にデータ作成
  describe 'PUT /image_update' do
    let!(:valid_attributes) { { image: fixture_file_upload(TEST_IMAGE_FILE, TEST_IMAGE_TYPE) } }
    let!(:invalid_attributes) { nil }

    # テスト内容
    shared_examples_for 'OK' do
      it '画像が変更される' do
        put update_user_image_registration_path, params: { user: attributes }
        after_user = User.find(user.id)
        expect(after_user.image.url).not_to eq(user.image.url)
        after_user.remove_image!
        after_user.save!
      end
    end
    shared_examples_for 'NG' do
      it '画像が変更されない' do
        put update_user_image_registration_path, params: { user: attributes }
        expect(User.find(user.id).image.url).to eq(user.image.url)
      end
    end

    shared_examples_for 'ToError' do
      it '成功ステータス' do # Tips: 再入力
        put update_user_image_registration_path, params: { user: attributes }
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToTop' do |alert, notice|
      it 'トップページにリダイレクト' do
        put update_user_image_registration_path, params: { user: attributes }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToLogin' do |alert, notice|
      it 'ログインにリダイレクト' do
        put update_user_image_registration_path, params: { user: attributes }
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToEdit' do |alert, notice|
      it '登録情報変更にリダイレクト' do
        put update_user_image_registration_path, params: { user: attributes }
        expect(response).to redirect_to(edit_user_registration_path)
        after_user = User.find(user.id)
        after_user.remove_image!
        after_user.save!
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      # it_behaves_like 'NG' # Tips: 未ログインの為、対象がない
      it_behaves_like 'ToLogin', 'devise.failure.unauthenticated', nil
    end
    shared_examples_for '[ログイン中]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      it_behaves_like 'ToEdit', nil, 'notice.user.image_update'
    end
    shared_examples_for '[削除予約済み]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'alert.user.destroy_reserved', nil
    end
    shared_examples_for '[未ログイン]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      # it_behaves_like 'NG' # Tips: 未ログインの為、対象がない
      it_behaves_like 'ToLogin', 'devise.failure.unauthenticated', nil
    end
    shared_examples_for '[ログイン中]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToError'
    end
    shared_examples_for '[削除予約済み]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
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
      include_context 'ログイン処理', true
      it_behaves_like '[削除予約済み]有効なパラメータ'
      it_behaves_like '[削除予約済み]無効なパラメータ'
    end
  end

  # DELETE /users/image 画像削除(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  describe 'DELETE /image_destroy' do
    # テスト内容
    shared_examples_for 'OK' do
      it '画像が削除される' do
        delete delete_user_image_registration_path
        expect(User.find(user.id).image.url).to be_nil
      end
    end
    shared_examples_for 'NG' do
      it '画像が変更されない' do
        delete delete_user_image_registration_path
        expect(User.find(user.id).image.url).to eq(user.image.url)
      end
    end

    shared_examples_for 'ToTop' do |alert, notice|
      it 'トップページにリダイレクト' do
        delete delete_user_image_registration_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToLogin' do |alert, notice|
      it 'ログインにリダイレクト' do
        delete delete_user_image_registration_path
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToEdit' do |alert, notice|
      it '登録情報変更にリダイレクト' do
        delete delete_user_image_registration_path
        expect(response).to redirect_to(edit_user_registration_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    context '未ログイン' do
      # it_behaves_like 'NG' # Tips: 未ログインの為、対象がない
      it_behaves_like 'ToLogin', 'devise.failure.unauthenticated', nil
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      include_context '画像登録処理'
      it_behaves_like 'OK'
      it_behaves_like 'ToEdit', nil, 'notice.user.image_destroy'
      include_context '画像削除処理'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      include_context '画像登録処理'
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'alert.user.destroy_reserved', nil
      include_context '画像削除処理'
    end
  end

  # GET /users/delete アカウント削除
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  describe 'GET /delete' do
    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get delete_user_registration_path
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToTop' do |alert, notice|
      it 'トップページにリダイレクト' do
        get delete_user_registration_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToLogin' do |alert, notice|
      it 'ログインにリダイレクト' do
        get delete_user_registration_path
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    context '未ログイン' do
      it_behaves_like 'ToLogin', 'devise.failure.unauthenticated', nil
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'ToOK'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like 'ToTop', 'alert.user.destroy_reserved', nil
    end
  end

  # DELETE /users/delete アカウント削除(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  describe 'DELETE /destroy' do
    # テスト内容
    shared_examples_for 'OK' do
      let!(:start_time) { Time.current - 1.second }
      it '削除依頼日時が現在日時に変更される' do
        delete destroy_user_registration_path
        expect(user.destroy_requested_at).to be_between(start_time, Time.current)
      end
      it "削除予定日時が#{Settings['destroy_schedule_days']}日後に変更される" do
        delete destroy_user_registration_path
        expect(user.destroy_schedule_at).to be_between(start_time + Settings['destroy_schedule_days'].days,
                                                       Time.current + Settings['destroy_schedule_days'].days)
      end
    end
    shared_examples_for 'NG' do
      let!(:before_user) { user }
      it '削除依頼日時が変更されない' do
        delete destroy_user_registration_path
        expect(user.destroy_requested_at).to eq(before_user.destroy_requested_at)
      end
      it '削除予定日時が変更されない' do
        delete destroy_user_registration_path
        expect(user.destroy_schedule_at).to eq(before_user.destroy_schedule_at)
      end
    end

    shared_examples_for 'ToTop' do |alert, notice|
      it 'トップページにリダイレクト' do
        delete destroy_user_registration_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToLogin' do |alert, notice|
      it 'ログインにリダイレクト' do
        delete destroy_user_registration_path
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
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
      include_context 'ログイン処理', true
      it_behaves_like 'NG'
      it_behaves_like 'ToTop', 'alert.user.destroy_reserved', nil
    end
  end

  # GET /users/undo_delete アカウント削除取り消し
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  describe 'GET /undo_delete' do
    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get delete_undo_user_registration_path
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToTop' do |alert, notice|
      it 'トップページにリダイレクト' do
        get delete_undo_user_registration_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToLogin' do |alert, notice|
      it 'ログインにリダイレクト' do
        get delete_undo_user_registration_path
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end

    # テストケース
    context '未ログイン' do
      it_behaves_like 'ToLogin', 'devise.failure.unauthenticated', nil
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'ToTop', 'alert.user.not_destroy_reserved', nil
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like 'ToOK'
    end
  end

  # DELETE /users/undo_delete アカウント削除取り消し(処理)
  # 前提条件
  #   なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み） → データ＆状態作成
  describe 'DELETE /undo_destroy' do
    # テスト内容
    shared_examples_for 'OK' do
      it '削除依頼日時がなしに変更される' do
        delete destroy_undo_user_registration_path
        expect(user.destroy_requested_at).to be_nil
      end
      it '削除予定日時がなしに変更される' do
        delete destroy_undo_user_registration_path
        expect(user.destroy_schedule_at).to be_nil
      end
    end
    shared_examples_for 'NG' do
      let!(:before_user) { user }
      it '削除依頼日時が変更されない' do
        delete destroy_undo_user_registration_path
        expect(user.destroy_requested_at).to eq(before_user.destroy_requested_at)
      end
      it '削除予定日時が変更されない' do
        delete destroy_undo_user_registration_path
        expect(user.destroy_schedule_at).to eq(before_user.destroy_schedule_at)
      end
    end

    shared_examples_for 'ToTop' do |alert, notice|
      it 'トップページにリダイレクト' do
        delete destroy_undo_user_registration_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
      end
    end
    shared_examples_for 'ToLogin' do |alert, notice|
      it 'ログインにリダイレクト' do
        delete destroy_undo_user_registration_path
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
        expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
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
      include_context 'ログイン処理', true
      it_behaves_like 'OK'
      it_behaves_like 'ToTop', nil, 'devise.registrations.undo_destroy_reserved'
    end
  end
end
