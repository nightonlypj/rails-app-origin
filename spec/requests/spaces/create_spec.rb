require 'rails_helper'

# TODO
RSpec.describe 'Spaces', type: :request do
=begin
  include_context '共通ヘッダー'
  let!(:customer) { FactoryBot.create(:customer) }
  let!(:valid_attributes) { FactoryBot.attributes_for(:space, customer_id: customer.id) }
  let!(:invalid_attributes) { FactoryBot.attributes_for(:space, customer_id: customer.id, name: nil) }

  # POST /spaces（ベースドメイン） スペース作成(処理)
  # POST /spaces.json（ベースドメイン） スペース作成API
  describe 'POST /create' do
    # テスト内容
    shared_examples_for '有効なパラメータ' do
      it '作成される' do
        expect do
          post space_path, params: { space: valid_attributes }, headers: base_headers
        end.to change(Space, :count).by(1)
      end
      it '作成したスペースのトップページ（サブドメイン）にリダイレクト' do
        post space_path, params: { space: valid_attributes }, headers: base_headers
        expect(response).to redirect_to("//#{valid_attributes[:subdomain]}.#{Settings['base_domain']}")
      end
      it '(json)created(201)ステータス' do
        post space_path, params: valid_attributes, as: :json, headers: base_headers.merge(json_headers)
        expect(response).to be_created
      end
      it '(json)エラー件数が0と一致' do
        post space_path, params: valid_attributes, as: :json, headers: base_headers.merge(json_headers)
        expect(JSON.parse(response.body)['error_count']).to eq(0)
      end
      it '(json)エラーメッセージの項目が存在しない' do
        post space_path, params: valid_attributes, as: :json, headers: base_headers.merge(json_headers)
        expect(JSON.parse(response.body)['errors'].present?).to eq(false)
      end
    end
    shared_examples_for '無効なパラメータ' do
      it '作成されない' do
        expect do
          post space_path, params: { space: invalid_attributes }, headers: base_headers
        end.to change(Space, :count).by(0)
      end
      it '成功ステータス' do # Tips: 再入力の為
        post space_path, params: { space: invalid_attributes }, headers: base_headers
        expect(response).to be_successful
      end
      it '(json)unprocessable(422)ステータス' do
        post space_path, params: invalid_attributes, as: :json, headers: base_headers.merge(json_headers)
        expect(response).to be_unprocessable
      end
      it '(json)エラー件数が1と一致' do
        post space_path, params: invalid_attributes, as: :json, headers: base_headers.merge(json_headers)
        expect(JSON.parse(response.body)['error_count']).to eq(1)
      end
      it '(json)エラーメッセージの項目が存在する' do
        post space_path, params: invalid_attributes, as: :json, headers: base_headers.merge(json_headers)
        expect(JSON.parse(response.body)['errors'].present?).to eq(true)
      end
    end

    shared_examples_for 'サブドメイン' do
      it 'スペース作成（ベースドメイン）にリダイレクト' do
        post space_path, params: { space: valid_attributes }, headers: @space_headers
        expect(response).to redirect_to("//#{Settings['base_domain']}#{new_space_path}")
      end
      it '(json)存在しないステータス' do
        post space_path, params: valid_attributes, as: :json, headers: @space_headers.merge(json_headers)
        expect(response).to be_not_found
      end
    end

    # 子テストケース
    shared_examples_for 'ベースドメイン' do
      it_behaves_like '有効なパラメータ'
      it_behaves_like '無効なパラメータ'
    end
    shared_examples_for '存在するサブドメイン' do
      include_context 'リクエストスペース作成'
      it_behaves_like 'サブドメイン'
    end
    shared_examples_for '存在しないサブドメイン' do
      include_context '存在しないリクエストスペース'
      it_behaves_like 'サブドメイン'
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
=end
end
