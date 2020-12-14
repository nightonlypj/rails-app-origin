require 'rails_helper'

# TODO: private未対応
RSpec.describe 'Spaces', type: :request do
  include_context '共通ヘッダー'
  include_context 'リクエストスペース作成'
  let!(:valid_attributes) { FactoryBot.attributes_for(:space, customer_id: @request_space.customer_id) }
  let!(:invalid_attributes) { FactoryBot.attributes_for(:space, customer_id: @request_space.customer_id, name: nil) }

  # PATCH/PUT /spaces（サブドメイン） スペース更新(処理)
  # PATCH/PUT /spaces.json（サブドメイン） スペース更新API
  describe 'PATCH /update' do
    # テスト内容
    shared_examples_for '有効なパラメータ' do
      it '更新される' do
        patch space_path, params: { space: valid_attributes }, headers: @space_headers
        expect(Space.find(@request_space.id).name).to eq(valid_attributes[:name])
      end
      it '更新したスペースのトップページ（サブドメイン）にリダイレクト' do
        patch space_path, params: { space: valid_attributes }, headers: @space_headers
        expect(response).to redirect_to("//#{valid_attributes[:subdomain]}.#{Settings['base_domain']}")
      end
      it '(json)ok(200)ステータス' do
        patch space_path, params: valid_attributes, as: :json, headers: @space_headers.merge(json_headers)
        expect(response).to be_ok
      end
      it '(json)エラー件数が0と一致' do
        patch space_path, params: valid_attributes, as: :json, headers: @space_headers.merge(json_headers)
        expect(JSON.parse(response.body)['error_count']).to eq(0)
      end
      it '(json)エラーメッセージの項目が存在しない' do
        patch space_path, params: valid_attributes, as: :json, headers: @space_headers.merge(json_headers)
        expect(JSON.parse(response.body)['errors'].present?).to eq(false)
      end
    end
    shared_examples_for '無効なパラメータ' do
      it '更新されない' do
        patch space_path, params: { space: invalid_attributes }, headers: @space_headers
        expect(Space.find(@request_space.id).name).to eq(@request_space.name)
      end
      it '成功ステータス' do # Tips: 再入力の為
        patch space_path, params: { space: invalid_attributes }, headers: @space_headers
        expect(response).to be_successful
      end
      it '(json)unprocessable(422)ステータス' do
        patch space_path, params: invalid_attributes, as: :json, headers: @space_headers.merge(json_headers)
        expect(response).to be_unprocessable
      end
      it '(json)エラー件数が1と一致' do
        patch space_path, params: invalid_attributes, as: :json, headers: @space_headers.merge(json_headers)
        expect(JSON.parse(response.body)['error_count']).to eq(1)
      end
      it '(json)エラーメッセージの項目が存在する' do
        patch space_path, params: invalid_attributes, as: :json, headers: @space_headers.merge(json_headers)
        expect(JSON.parse(response.body)['errors'].present?).to eq(true)
      end
    end

    shared_examples_for 'ベースドメイン' do
      it '存在しないステータス' do
        patch space_path, params: { space: valid_attributes }, headers: base_headers
        expect(response).to be_not_found
      end
      it '(json)存在しないステータス' do
        patch space_path, params: { space: valid_attributes }, as: :json, headers: base_headers.merge(json_headers)
        expect(response).to be_not_found
      end
    end
    shared_examples_for '存在しないサブドメイン' do
      it '存在しないステータス' do
        patch space_path, params: { space: valid_attributes }, headers: not_space_headers
        expect(response).to be_not_found
      end
      it '(json)存在しないステータス' do
        patch space_path, params: { space: valid_attributes }, as: :json, headers: not_space_headers.merge(json_headers)
        expect(response).to be_not_found
      end
    end

    # 子テストケース
    shared_examples_for '存在するサブドメイン' do
      it_behaves_like '有効なパラメータ'
      it_behaves_like '無効なパラメータ'
    end

    # テストケース
    context '未ログイン' do
      it_behaves_like 'ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'ベースドメイン'
      it_behaves_like '存在するサブドメイン'
      it_behaves_like '存在しないサブドメイン'
    end
  end
end
