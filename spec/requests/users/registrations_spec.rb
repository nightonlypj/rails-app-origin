require 'rails_helper'

RSpec.describe 'Users::Registrations', type: :request do
  include_context '共通ヘッダー'
  include_context 'リクエストスペース作成'
  let!(:valid_attributes) { FactoryBot.attributes_for(:user) }
  let!(:invalid_attributes) { FactoryBot.attributes_for(:user, email: nil) }
  let!(:valid_image) { fixture_file_upload(TEST_IMAGE_FILE, TEST_IMAGE_TYPE) }

  # GET /users/sign_up アカウント登録
  describe 'GET /new' do
    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get new_user_registration_path, headers: headers
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToTop' do
      it 'トップページにリダイレクト' do
        get new_user_registration_path, headers: headers
        expect(response).to redirect_to(root_path)
      end
    end
    shared_examples_for 'ToBase' do
      it 'ベースドメインにリダイレクト' do
        get new_user_registration_path, headers: headers
        expect(response).to redirect_to("//#{Settings['base_domain']}#{new_user_registration_path}")
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]ベースドメイン' do
      let!(:headers) { base_headers }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[ログイン中]ベースドメイン' do
      let!(:headers) { base_headers }
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[未ログイン]存在するサブドメイン' do
      let!(:headers) { @space_headers }
      it_behaves_like 'ToBase'
    end
    shared_examples_for '[ログイン中]存在するサブドメイン' do
      let!(:headers) { @space_headers }
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[未ログイン]存在しないサブドメイン' do
      let!(:headers) { not_space_headers }
      it_behaves_like 'ToBase'
    end
    shared_examples_for '[ログイン中]存在しないサブドメイン' do
      let!(:headers) { not_space_headers }
      it_behaves_like 'ToTop'
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]ベースドメイン'
      it_behaves_like '[未ログイン]存在するサブドメイン'
      it_behaves_like '[未ログイン]存在しないサブドメイン'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中]ベースドメイン'
      it_behaves_like '[ログイン中]存在するサブドメイン'
      it_behaves_like '[ログイン中]存在しないサブドメイン'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[ログイン中]ベースドメイン'
      it_behaves_like '[ログイン中]存在するサブドメイン'
      it_behaves_like '[ログイン中]存在しないサブドメイン'
    end
  end

  # POST /users アカウント登録(処理)
  describe 'POST /create' do
    # テスト内容
    shared_examples_for 'OK' do
      it '作成される' do
        expect do
          post user_registration_path, params: { user: attributes }, headers: headers
        end.to change(User, :count).by(1)
      end
    end
    shared_examples_for 'NG' do
      it '作成されない' do
        expect do
          post user_registration_path, params: { user: attributes }, headers: headers
        end.to change(User, :count).by(0)
      end
    end

    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        post user_registration_path, params: { user: attributes }, headers: headers
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToNG' do
      it '存在しないステータス' do
        post user_registration_path, params: { user: attributes }, headers: headers
        expect(response).to be_not_found
      end
    end
    shared_examples_for 'ToTop' do
      it 'トップページにリダイレクト' do
        post user_registration_path, params: { user: attributes }, headers: headers
        expect(response).to redirect_to(root_path)
      end
    end
    shared_examples_for 'ToLogin' do
      it 'ログインにリダイレクト' do
        post user_registration_path, params: { user: attributes }, headers: headers
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    # テストケース
    shared_examples_for '[未ログイン][ベースドメイン]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '[未ログイン][サブドメイン]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG'
    end
    shared_examples_for '[未ログイン][ベースドメイン]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToOK' # Tips: 再入力の為
    end
    shared_examples_for '[未ログイン][サブドメイン]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG'
    end
    shared_examples_for '[ログイン中]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[ログイン中]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop'
    end

    shared_examples_for '[未ログイン]ベースドメイン' do
      let!(:headers) { base_headers }
      it_behaves_like '[未ログイン][ベースドメイン]有効なパラメータ'
      it_behaves_like '[未ログイン][ベースドメイン]無効なパラメータ'
    end
    shared_examples_for '[ログイン中]ベースドメイン' do
      let!(:headers) { base_headers }
      it_behaves_like '[ログイン中]有効なパラメータ'
      it_behaves_like '[ログイン中]無効なパラメータ'
    end
    shared_examples_for '[未ログイン]存在するサブドメイン' do
      let!(:headers) { @space_headers }
      it_behaves_like '[未ログイン][サブドメイン]有効なパラメータ'
      it_behaves_like '[未ログイン][サブドメイン]無効なパラメータ'
    end
    shared_examples_for '[ログイン中]存在するサブドメイン' do
      let!(:headers) { @space_headers }
      it_behaves_like '[ログイン中]有効なパラメータ'
      it_behaves_like '[ログイン中]無効なパラメータ'
    end
    shared_examples_for '[未ログイン]存在しないサブドメイン' do
      let!(:headers) { not_space_headers }
      it_behaves_like '[未ログイン][サブドメイン]有効なパラメータ'
      it_behaves_like '[未ログイン][サブドメイン]無効なパラメータ'
    end
    shared_examples_for '[ログイン中]存在しないサブドメイン' do
      let!(:headers) { not_space_headers }
      it_behaves_like '[ログイン中]有効なパラメータ'
      it_behaves_like '[ログイン中]無効なパラメータ'
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]ベースドメイン'
      it_behaves_like '[未ログイン]存在するサブドメイン'
      it_behaves_like '[未ログイン]存在しないサブドメイン'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中]ベースドメイン'
      it_behaves_like '[ログイン中]存在するサブドメイン'
      it_behaves_like '[ログイン中]存在しないサブドメイン'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[ログイン中]ベースドメイン'
      it_behaves_like '[ログイン中]存在するサブドメイン'
      it_behaves_like '[ログイン中]存在しないサブドメイン'
    end
  end

  # GET /users/edit 登録情報変更
  describe 'GET /edit' do
    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get edit_user_registration_path, headers: headers
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToTop' do
      it 'トップページにリダイレクト' do
        get edit_user_registration_path, headers: headers
        expect(response).to redirect_to(root_path)
      end
    end
    shared_examples_for 'ToLogin' do
      it 'ログインにリダイレクト' do
        get edit_user_registration_path, headers: headers
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    shared_examples_for 'ToBase' do
      it 'ベースドメインにリダイレクト' do
        get edit_user_registration_path, headers: headers
        expect(response).to redirect_to("//#{Settings['base_domain']}#{edit_user_registration_path}")
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]ベースドメイン' do
      let!(:headers) { base_headers }
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '[ログイン中]ベースドメイン' do
      let!(:headers) { base_headers }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[削除予約済み]ベースドメイン' do
      let!(:headers) { base_headers }
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[未ログイン]存在するサブドメイン' do
      let!(:headers) { @space_headers }
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '[ログイン中]存在するサブドメイン' do
      let!(:headers) { @space_headers }
      it_behaves_like 'ToBase'
    end
    shared_examples_for '[削除予約済み]存在するサブドメイン' do
      let!(:headers) { @space_headers }
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[未ログイン]存在しないサブドメイン' do
      let!(:headers) { not_space_headers }
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '[ログイン中]存在しないサブドメイン' do
      let!(:headers) { not_space_headers }
      it_behaves_like 'ToBase'
    end
    shared_examples_for '[削除予約済み]存在しないサブドメイン' do
      let!(:headers) { not_space_headers }
      it_behaves_like 'ToTop'
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]ベースドメイン'
      it_behaves_like '[未ログイン]存在するサブドメイン'
      it_behaves_like '[未ログイン]存在しないサブドメイン'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中]ベースドメイン'
      it_behaves_like '[ログイン中]存在するサブドメイン'
      it_behaves_like '[ログイン中]存在しないサブドメイン'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[削除予約済み]ベースドメイン'
      it_behaves_like '[削除予約済み]存在するサブドメイン'
      it_behaves_like '[削除予約済み]存在しないサブドメイン'
    end
  end

  # PUT /users 登録情報変更(処理)
  describe 'PUT /update' do
    # テスト内容
    shared_examples_for 'OK' do
      it '表示名が変更される' do
        put user_registration_path, params: { user: attributes.merge(current_password: current_password) }, headers: headers
        expect(User.find(user.id).name).to eq(attributes[:name])
      end
    end
    shared_examples_for 'NG' do
      it '表示名が変更されない' do
        put user_registration_path, params: { user: attributes.merge(current_password: current_password) }, headers: headers
        expect(User.find(user.id).name).to eq(user.name)
      end
    end

    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        put user_registration_path, params: { user: attributes.merge(current_password: current_password) }, headers: headers
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToNG' do
      it '存在しないステータス' do
        put user_registration_path, params: { user: attributes.merge(current_password: current_password) }, headers: headers
        expect(response).to be_not_found
      end
    end
    shared_examples_for 'ToTop' do
      it 'トップページにリダイレクト' do
        put user_registration_path, params: { user: attributes.merge(current_password: current_password) }, headers: headers
        expect(response).to redirect_to(root_path)
      end
    end
    shared_examples_for 'ToLogin' do
      it 'ログインにリダイレクト' do
        put user_registration_path, params: { user: attributes.merge(current_password: current_password) }, headers: headers
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '[未ログイン]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '[ログイン中][ベースドメイン]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like 'OK'
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[ログイン中][サブドメイン]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG'
    end
    shared_examples_for '[ログイン中][ベースドメイン]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToOK' # Tips: 再入力の為
    end
    shared_examples_for '[ログイン中][サブドメイン]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG'
    end
    shared_examples_for '[削除予約済み]有効なパラメータ' do
      let!(:attributes) { valid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[削除予約済み]無効なパラメータ' do
      let!(:attributes) { invalid_attributes }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop'
    end

    shared_examples_for '[未ログイン]ベースドメイン' do
      let!(:headers) { base_headers }
      it_behaves_like '[未ログイン]有効なパラメータ'
      it_behaves_like '[未ログイン]無効なパラメータ'
    end
    shared_examples_for '[ログイン中]ベースドメイン' do
      let!(:headers) { base_headers }
      it_behaves_like '[ログイン中][ベースドメイン]有効なパラメータ'
      it_behaves_like '[ログイン中][ベースドメイン]無効なパラメータ'
    end
    shared_examples_for '[削除予約済み]ベースドメイン' do
      let!(:headers) { base_headers }
      it_behaves_like '[削除予約済み]有効なパラメータ'
      it_behaves_like '[削除予約済み]無効なパラメータ'
    end
    shared_examples_for '[未ログイン]存在するサブドメイン' do
      let!(:headers) { @space_headers }
      it_behaves_like '[未ログイン]有効なパラメータ'
      it_behaves_like '[未ログイン]無効なパラメータ'
    end
    shared_examples_for '[ログイン中]存在するサブドメイン' do
      let!(:headers) { @space_headers }
      it_behaves_like '[ログイン中][サブドメイン]有効なパラメータ'
      it_behaves_like '[ログイン中][サブドメイン]無効なパラメータ'
    end
    shared_examples_for '[削除予約済み]存在するサブドメイン' do
      let!(:headers) { @space_headers }
      it_behaves_like '[削除予約済み]有効なパラメータ'
      it_behaves_like '[削除予約済み]無効なパラメータ'
    end
    shared_examples_for '[未ログイン]存在しないサブドメイン' do
      let!(:headers) { not_space_headers }
      it_behaves_like '[未ログイン]有効なパラメータ'
      it_behaves_like '[未ログイン]無効なパラメータ'
    end
    shared_examples_for '[ログイン中]存在しないサブドメイン' do
      let!(:headers) { not_space_headers }
      it_behaves_like '[ログイン中][サブドメイン]有効なパラメータ'
      it_behaves_like '[ログイン中][サブドメイン]無効なパラメータ'
    end
    shared_examples_for '[削除予約済み]存在しないサブドメイン' do
      let!(:headers) { not_space_headers }
      it_behaves_like '[削除予約済み]有効なパラメータ'
      it_behaves_like '[削除予約済み]無効なパラメータ'
    end

    context '未ログイン' do
      let!(:current_password) { nil }
      it_behaves_like '[未ログイン]ベースドメイン'
      it_behaves_like '[未ログイン]存在するサブドメイン'
      it_behaves_like '[未ログイン]存在しないサブドメイン'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      include_context '画像登録処理'
      let!(:current_password) { user.password }
      it_behaves_like '[ログイン中]ベースドメイン'
      it_behaves_like '[ログイン中]存在するサブドメイン'
      it_behaves_like '[ログイン中]存在しないサブドメイン'
      include_context '画像削除処理'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      include_context '画像登録処理'
      let!(:current_password) { user.password }
      it_behaves_like '[削除予約済み]ベースドメイン'
      it_behaves_like '[削除予約済み]存在するサブドメイン'
      it_behaves_like '[削除予約済み]存在しないサブドメイン'
      include_context '画像削除処理'
    end
  end

  # PUT /users/image 画像変更(処理)
  describe 'PUT /image_update' do
    # テスト内容
    shared_examples_for 'OK' do
      it '画像が変更される' do
        put users_image_path, params: { user: attributes }, headers: headers
        after_user = User.find(user.id)
        expect(after_user.image.url).not_to eq(user.image.url)
        after_user.remove_image!
        after_user.save!
      end
    end
    shared_examples_for 'NG' do
      it '画像が変更されない' do
        put users_image_path, params: { user: attributes }, headers: headers
        expect(User.find(user.id).image.url).to eq(user.image.url)
      end
    end

    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        put users_image_path, params: { user: attributes }, headers: headers
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToNG' do
      it '存在しないステータス' do
        put users_image_path, params: { user: attributes }, headers: headers
        expect(response).to be_not_found
      end
    end
    shared_examples_for 'ToTop' do
      it 'トップページにリダイレクト' do
        put users_image_path, params: { user: attributes }, headers: headers
        expect(response).to redirect_to(root_path)
      end
    end
    shared_examples_for 'ToLogin' do
      it 'ログインにリダイレクト' do
        put users_image_path, params: { user: attributes }, headers: headers
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    shared_examples_for 'ToEdit' do
      it '登録情報変更にリダイレクト' do
        put users_image_path, params: { user: attributes }, headers: headers
        expect(response).to redirect_to(edit_user_registration_path)
        after_user = User.find(user.id)
        after_user.remove_image!
        after_user.save!
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]有効なパラメータ' do
      let!(:attributes) { { image: valid_image } }
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '[未ログイン]無効なパラメータ' do
      let!(:attributes) { nil }
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '[ログイン中][ベースドメイン]有効なパラメータ' do
      let!(:attributes) { { image: valid_image } }
      it_behaves_like 'OK'
      it_behaves_like 'ToEdit'
    end
    shared_examples_for '[ログイン中][サブドメイン]有効なパラメータ' do
      let!(:attributes) { { image: valid_image } }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG'
    end
    shared_examples_for '[ログイン中][ベースドメイン]無効なパラメータ' do
      let!(:attributes) { nil }
      it_behaves_like 'NG'
      it_behaves_like 'ToOK' # Tips: 再入力の為
    end
    shared_examples_for '[ログイン中][サブドメイン]無効なパラメータ' do
      let!(:attributes) { nil }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG'
    end
    shared_examples_for '[削除予約済み]有効なパラメータ' do
      let!(:attributes) { { image: valid_image } }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[削除予約済み]無効なパラメータ' do
      let!(:attributes) { nil }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop'
    end

    shared_examples_for '[未ログイン]ベースドメイン' do
      let!(:headers) { base_headers }
      it_behaves_like '[未ログイン]有効なパラメータ'
      it_behaves_like '[未ログイン]無効なパラメータ'
    end
    shared_examples_for '[ログイン中]ベースドメイン' do
      let!(:headers) { base_headers }
      it_behaves_like '[ログイン中][ベースドメイン]有効なパラメータ'
      it_behaves_like '[ログイン中][ベースドメイン]無効なパラメータ'
    end
    shared_examples_for '[削除予約済み]ベースドメイン' do
      let!(:headers) { base_headers }
      it_behaves_like '[削除予約済み]有効なパラメータ'
      it_behaves_like '[削除予約済み]無効なパラメータ'
    end
    shared_examples_for '[未ログイン]存在するサブドメイン' do
      let!(:headers) { @space_headers }
      it_behaves_like '[未ログイン]有効なパラメータ'
      it_behaves_like '[未ログイン]無効なパラメータ'
    end
    shared_examples_for '[ログイン中]存在するサブドメイン' do
      let!(:headers) { @space_headers }
      it_behaves_like '[ログイン中][サブドメイン]有効なパラメータ'
      it_behaves_like '[ログイン中][サブドメイン]無効なパラメータ'
    end
    shared_examples_for '[削除予約済み]存在するサブドメイン' do
      let!(:headers) { @space_headers }
      it_behaves_like '[削除予約済み]有効なパラメータ'
      it_behaves_like '[削除予約済み]無効なパラメータ'
    end
    shared_examples_for '[未ログイン]存在しないサブドメイン' do
      let!(:headers) { not_space_headers }
      it_behaves_like '[未ログイン]有効なパラメータ'
      it_behaves_like '[未ログイン]無効なパラメータ'
    end
    shared_examples_for '[ログイン中]存在しないサブドメイン' do
      let!(:headers) { not_space_headers }
      it_behaves_like '[ログイン中][サブドメイン]有効なパラメータ'
      it_behaves_like '[ログイン中][サブドメイン]無効なパラメータ'
    end
    shared_examples_for '[削除予約済み]存在しないサブドメイン' do
      let!(:headers) { not_space_headers }
      it_behaves_like '[削除予約済み]有効なパラメータ'
      it_behaves_like '[削除予約済み]無効なパラメータ'
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]ベースドメイン'
      it_behaves_like '[未ログイン]存在するサブドメイン'
      it_behaves_like '[未ログイン]存在しないサブドメイン'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中]ベースドメイン'
      it_behaves_like '[ログイン中]存在するサブドメイン'
      it_behaves_like '[ログイン中]存在しないサブドメイン'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[削除予約済み]ベースドメイン'
      it_behaves_like '[削除予約済み]存在するサブドメイン'
      it_behaves_like '[削除予約済み]存在しないサブドメイン'
    end
  end

  # DELETE /users/image 画像削除(処理)
  describe 'DELETE /image_destroy' do
    # テスト内容
    shared_examples_for 'OK' do
      it '画像が削除される' do
        delete users_image_path, headers: headers
        expect(User.find(user.id).image.url).to be_nil
      end
    end
    shared_examples_for 'NG' do
      it '画像が変更されない' do
        delete users_image_path, headers: headers
        expect(User.find(user.id).image.url).to eq(user.image.url)
      end
    end

    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        delete users_image_path, headers: headers
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToNG' do
      it '存在しないステータス' do
        delete users_image_path, headers: headers
        expect(response).to be_not_found
      end
    end
    shared_examples_for 'ToTop' do
      it 'トップページにリダイレクト' do
        delete users_image_path, headers: headers
        expect(response).to redirect_to(root_path)
      end
    end
    shared_examples_for 'ToLogin' do
      it 'ログインにリダイレクト' do
        delete users_image_path, headers: headers
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    shared_examples_for 'ToEdit' do
      it '登録情報変更にリダイレクト' do
        delete users_image_path, headers: headers
        expect(response).to redirect_to(edit_user_registration_path)
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]ベースドメイン' do
      let!(:headers) { base_headers }
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '[ログイン中]ベースドメイン' do
      let!(:headers) { base_headers }
      it_behaves_like 'OK'
      it_behaves_like 'ToEdit'
    end
    shared_examples_for '[削除予約済み]ベースドメイン' do
      let!(:headers) { base_headers }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[未ログイン]存在するサブドメイン' do
      let!(:headers) { @space_headers }
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '[ログイン中]存在するサブドメイン' do
      let!(:headers) { @space_headers }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG'
    end
    shared_examples_for '[削除予約済み]存在するサブドメイン' do
      let!(:headers) { @space_headers }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[未ログイン]存在しないサブドメイン' do
      let!(:headers) { not_space_headers }
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '[ログイン中]存在しないサブドメイン' do
      let!(:headers) { not_space_headers }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG'
    end
    shared_examples_for '[削除予約済み]存在しないサブドメイン' do
      let!(:headers) { not_space_headers }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop'
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]ベースドメイン'
      it_behaves_like '[未ログイン]存在するサブドメイン'
      it_behaves_like '[未ログイン]存在しないサブドメイン'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      include_context '画像登録処理'
      it_behaves_like '[ログイン中]ベースドメイン'
      it_behaves_like '[ログイン中]存在するサブドメイン'
      it_behaves_like '[ログイン中]存在しないサブドメイン'
      include_context '画像削除処理'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      include_context '画像登録処理'
      it_behaves_like '[削除予約済み]ベースドメイン'
      it_behaves_like '[削除予約済み]存在するサブドメイン'
      it_behaves_like '[削除予約済み]存在しないサブドメイン'
      include_context '画像削除処理'
    end
  end

  # GET /users/delete アカウント削除
  describe 'GET /delete' do
    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get users_delete_path, headers: headers
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToTop' do
      it 'トップページにリダイレクト' do
        get users_delete_path, headers: headers
        expect(response).to redirect_to(root_path)
      end
    end
    shared_examples_for 'ToLogin' do
      it 'ログインにリダイレクト' do
        get users_delete_path, headers: headers
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    shared_examples_for 'ToBase' do
      it 'ベースドメインにリダイレクト' do
        get users_delete_path, headers: headers
        expect(response).to redirect_to("//#{Settings['base_domain']}#{users_delete_path}")
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]ベースドメイン' do
      let!(:headers) { base_headers }
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '[ログイン中]ベースドメイン' do
      let!(:headers) { base_headers }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[削除予約済み]ベースドメイン' do
      let!(:headers) { base_headers }
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[未ログイン]存在するサブドメイン' do
      let!(:headers) { @space_headers }
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '[ログイン中]存在するサブドメイン' do
      let!(:headers) { @space_headers }
      it_behaves_like 'ToBase'
    end
    shared_examples_for '[削除予約済み]存在するサブドメイン' do
      let!(:headers) { @space_headers }
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[未ログイン]存在しないサブドメイン' do
      let!(:headers) { not_space_headers }
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '[ログイン中]存在しないサブドメイン' do
      let!(:headers) { not_space_headers }
      it_behaves_like 'ToBase'
    end
    shared_examples_for '[削除予約済み]存在しないサブドメイン' do
      let!(:headers) { not_space_headers }
      it_behaves_like 'ToTop'
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]ベースドメイン'
      it_behaves_like '[未ログイン]存在するサブドメイン'
      it_behaves_like '[未ログイン]存在しないサブドメイン'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中]ベースドメイン'
      it_behaves_like '[ログイン中]存在するサブドメイン'
      it_behaves_like '[ログイン中]存在しないサブドメイン'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[削除予約済み]ベースドメイン'
      it_behaves_like '[削除予約済み]存在するサブドメイン'
      it_behaves_like '[削除予約済み]存在しないサブドメイン'
    end
  end

  # DELETE /users アカウント削除(処理)
  describe 'DELETE /destroy' do
    # テスト内容
    shared_examples_for 'OK' do
      let!(:start_time) { Time.current }
      it '削除依頼日時が現在日時に変更される' do
        delete user_registration_path, headers: headers
        expect(user.destroy_requested_at).to be_between(start_time, Time.current)
      end
      it "削除予定日時が#{Settings['destroy_schedule_days']}日後に変更される" do
        delete user_registration_path, headers: headers
        expect(user.destroy_schedule_at).to be_between(start_time + Settings['destroy_schedule_days'].days,
                                                       Time.current + Settings['destroy_schedule_days'].days)
      end
    end
    shared_examples_for 'NG' do
      let!(:before_user) { user }
      it '削除依頼日時が変更されない' do
        delete user_registration_path, headers: headers
        expect(user.destroy_requested_at).to eq(before_user.destroy_requested_at)
      end
      it '削除予定日時が変更されない' do
        delete user_registration_path, headers: headers
        expect(user.destroy_schedule_at).to eq(before_user.destroy_schedule_at)
      end
    end

    shared_examples_for 'ToNG' do
      it '存在しないステータス' do
        delete user_registration_path, headers: headers
        expect(response).to be_not_found
      end
    end
    shared_examples_for 'ToTop' do
      it 'トップページにリダイレクト' do
        delete user_registration_path, headers: headers
        expect(response).to redirect_to(root_path)
      end
    end
    shared_examples_for 'ToLogin' do
      it 'ログインにリダイレクト' do
        delete user_registration_path, headers: headers
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]ベースドメイン' do
      let!(:headers) { base_headers }
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '[ログイン中]ベースドメイン' do
      let!(:headers) { base_headers }
      it_behaves_like 'OK'
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '[削除予約済み]ベースドメイン' do
      let!(:headers) { base_headers }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[未ログイン]存在するサブドメイン' do
      let!(:headers) { @space_headers }
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '[ログイン中]存在するサブドメイン' do
      let!(:headers) { @space_headers }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG'
    end
    shared_examples_for '[削除予約済み]存在するサブドメイン' do
      let!(:headers) { @space_headers }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[未ログイン]存在しないサブドメイン' do
      let!(:headers) { not_space_headers }
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '[ログイン中]存在しないサブドメイン' do
      let!(:headers) { not_space_headers }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG'
    end
    shared_examples_for '[削除予約済み]存在しないサブドメイン' do
      let!(:headers) { not_space_headers }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop'
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]ベースドメイン'
      it_behaves_like '[未ログイン]存在するサブドメイン'
      it_behaves_like '[未ログイン]存在しないサブドメイン'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中]ベースドメイン'
      it_behaves_like '[ログイン中]存在するサブドメイン'
      it_behaves_like '[ログイン中]存在しないサブドメイン'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[削除予約済み]ベースドメイン'
      it_behaves_like '[削除予約済み]存在するサブドメイン'
      it_behaves_like '[削除予約済み]存在しないサブドメイン'
    end
  end

  # GET /users/undo_delete アカウント削除取り消し
  describe 'GET /undo_delete' do
    # テスト内容
    shared_examples_for 'ToOK' do
      it '成功ステータス' do
        get users_undo_delete_path, headers: headers
        expect(response).to be_successful
      end
    end
    shared_examples_for 'ToTop' do
      it 'トップページにリダイレクト' do
        get users_undo_delete_path, headers: headers
        expect(response).to redirect_to(root_path)
      end
    end
    shared_examples_for 'ToLogin' do
      it 'ログインにリダイレクト' do
        get users_undo_delete_path, headers: headers
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    shared_examples_for 'ToBase' do
      it 'ベースドメインにリダイレクト' do
        get users_undo_delete_path, headers: headers
        expect(response).to redirect_to("//#{Settings['base_domain']}#{users_undo_delete_path}")
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]ベースドメイン' do
      let!(:headers) { base_headers }
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '[ログイン中]ベースドメイン' do
      let!(:headers) { base_headers }
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[削除予約済み]ベースドメイン' do
      let!(:headers) { base_headers }
      it_behaves_like 'ToOK'
    end
    shared_examples_for '[未ログイン]存在するサブドメイン' do
      let!(:headers) { @space_headers }
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '[ログイン中]存在するサブドメイン' do
      let!(:headers) { @space_headers }
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[削除予約済み]存在するサブドメイン' do
      let!(:headers) { @space_headers }
      it_behaves_like 'ToBase'
    end
    shared_examples_for '[未ログイン]存在しないサブドメイン' do
      let!(:headers) { not_space_headers }
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '[ログイン中]存在しないサブドメイン' do
      let!(:headers) { not_space_headers }
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[削除予約済み]存在しないサブドメイン' do
      let!(:headers) { not_space_headers }
      it_behaves_like 'ToBase'
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]ベースドメイン'
      it_behaves_like '[未ログイン]存在するサブドメイン'
      it_behaves_like '[未ログイン]存在しないサブドメイン'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中]ベースドメイン'
      it_behaves_like '[ログイン中]存在するサブドメイン'
      it_behaves_like '[ログイン中]存在しないサブドメイン'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[削除予約済み]ベースドメイン'
      it_behaves_like '[削除予約済み]存在するサブドメイン'
      it_behaves_like '[削除予約済み]存在しないサブドメイン'
    end
  end

  # DELETE /users/undo_delete アカウント削除取り消し(処理)
  describe 'DELETE /undo_destroy' do
    # テスト内容
    shared_examples_for 'OK' do
      it '削除依頼日時が空に変更される' do
        delete users_undo_delete_path, headers: headers
        expect(user.destroy_requested_at).to be_nil
      end
      it '削除予定日時が空に変更される' do
        delete users_undo_delete_path, headers: headers
        expect(user.destroy_schedule_at).to be_nil
      end
    end
    shared_examples_for 'NG' do
      let!(:before_user) { user }
      it '削除依頼日時が変更されない' do
        delete users_undo_delete_path, headers: headers
        expect(user.destroy_requested_at).to eq(before_user.destroy_requested_at)
      end
      it '削除予定日時が変更されない' do
        delete users_undo_delete_path, headers: headers
        expect(user.destroy_schedule_at).to eq(before_user.destroy_schedule_at)
      end
    end

    shared_examples_for 'ToNG' do
      it '存在しないステータス' do
        delete users_undo_delete_path, headers: headers
        expect(response).to be_not_found
      end
    end
    shared_examples_for 'ToTop' do
      it 'トップページにリダイレクト' do
        delete users_undo_delete_path, headers: headers
        expect(response).to redirect_to(root_path)
      end
    end
    shared_examples_for 'ToLogin' do
      it 'ログインにリダイレクト' do
        delete users_undo_delete_path, headers: headers
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    # テストケース
    shared_examples_for '[未ログイン]ベースドメイン' do
      let!(:headers) { base_headers }
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '[ログイン中]ベースドメイン' do
      let!(:headers) { base_headers }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[削除予約済み]ベースドメイン' do
      let!(:headers) { base_headers }
      it_behaves_like 'OK'
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[未ログイン]存在するサブドメイン' do
      let!(:headers) { @space_headers }
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '[ログイン中]存在するサブドメイン' do
      let!(:headers) { @space_headers }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[削除予約済み]存在するサブドメイン' do
      let!(:headers) { @space_headers }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG'
    end
    shared_examples_for '[未ログイン]存在しないサブドメイン' do
      let!(:headers) { not_space_headers }
      it_behaves_like 'ToLogin'
    end
    shared_examples_for '[ログイン中]存在しないサブドメイン' do
      let!(:headers) { not_space_headers }
      it_behaves_like 'NG'
      it_behaves_like 'ToTop'
    end
    shared_examples_for '[削除予約済み]存在しないサブドメイン' do
      let!(:headers) { not_space_headers }
      it_behaves_like 'NG'
      it_behaves_like 'ToNG'
    end

    context '未ログイン' do
      it_behaves_like '[未ログイン]ベースドメイン'
      it_behaves_like '[未ログイン]存在するサブドメイン'
      it_behaves_like '[未ログイン]存在しないサブドメイン'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like '[ログイン中]ベースドメイン'
      it_behaves_like '[ログイン中]存在するサブドメイン'
      it_behaves_like '[ログイン中]存在しないサブドメイン'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', true
      it_behaves_like '[削除予約済み]ベースドメイン'
      it_behaves_like '[削除予約済み]存在するサブドメイン'
      it_behaves_like '[削除予約済み]存在しないサブドメイン'
    end
  end
end
