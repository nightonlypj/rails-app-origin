require 'rails_helper'

RSpec.describe 'Holidays', type: :request do
  let(:response_parsed_body_sym) { response.parsed_body.deep_symbolize_keys }

  # 祝日一覧API
  # テストパターン
  #   URLの拡張子: ない, .json
  #   Acceptヘッダ: HTMLが含まれる, JSONが含まれる
  #   未ログイン, ログイン中, ログイン中（削除予約済み）, APIログイン中, APIログイン中（削除予約済み）
  #   パラメータ: ない, 有効, 無効
  describe 'GET #index' do
    subject { get holidays_path(format: subject_format), params:, headers: auth_headers.merge(accept_headers) }
    let(:params) { { start_date:, end_date: } }
    let(:start_date) { current_start_date }
    let(:end_date)   { current_end_date }

    let_it_be(:current_start_date) { Time.zone.today.beginning_of_year }
    let_it_be(:current_end_date)   { Time.zone.today.end_of_year }
    before_all do
      FactoryBot.create(:holiday, name: '開始日前の祝日', date: current_start_date - 1.day)
      FactoryBot.create(:holiday, name: '開始日の祝日', date: current_start_date)
      FactoryBot.create(:holiday, name: '終了日の祝日', date: current_end_date)
      FactoryBot.create(:holiday, name: '終了日後の祝日', date: current_end_date + 1.day)
    end

    shared_examples 'アクセス拒否' do
      it 'HTTPステータスが406' do
        is_expected.to eq(406)
        expect(response.body).to eq('')
      end
    end

    shared_examples '正常なレスポンス(JSON)' do
      it 'HTTPステータスが200。対象項目が一致する' do
        is_expected.to eq(200)
        expect(response_parsed_body_sym).to eq(expect_response)
      end
    end

    context 'URLの拡張子がない' do
      let(:subject_format) { nil }
      include_context '未ログイン処理'

      context 'AcceptヘッダにHTMLが含まれる' do
        let(:accept_headers) { ACCEPT_INC_HTML }

        it_behaves_like 'アクセス拒否'
      end
      context 'AcceptヘッダにJSONが含まれる' do
        let(:accept_headers) { ACCEPT_INC_JSON }

        it_behaves_like 'アクセス拒否'
      end
    end
    context 'URLの拡張子が.json' do
      let(:subject_format) { :json }

      context 'AcceptヘッダにHTMLが含まれる' do
        let(:accept_headers) { ACCEPT_INC_HTML }
        include_context '未ログイン処理'

        it_behaves_like 'アクセス拒否'
      end
      context 'AcceptヘッダにJSONが含まれる' do
        let(:accept_headers) { ACCEPT_INC_JSON }

        shared_examples 'パラメータ' do
          let(:expect_response) do
            {
              success: true,
              search_params: {
                start_date: I18n.l(current_start_date, format: :json),
                end_date: I18n.l(current_end_date, format: :json)
              },
              holidays: [
                { date: I18n.l(current_start_date, format: :json), name: '開始日の祝日' },
                { date: I18n.l(current_end_date, format: :json), name: '終了日の祝日' }
              ]
            }
          end

          context 'ない' do
            let(:params) { nil }

            it_behaves_like '正常なレスポンス(JSON)'
          end
          context '有効' do
            it_behaves_like '正常なレスポンス(JSON)'
          end
          context '無効' do
            let(:start_date) { '' }
            let(:end_date)   { 'x' }

            it_behaves_like '正常なレスポンス(JSON)'
          end
        end

        context '未ログイン' do
          include_context '未ログイン処理'

          it_behaves_like 'パラメータ'
        end
        context 'ログイン中' do
          include_context 'ログイン処理'

          it_behaves_like 'パラメータ'
        end
        context 'ログイン中（削除予約済み）' do
          include_context 'ログイン処理', :destroy_reserved

          it_behaves_like 'パラメータ'
        end
        context 'APIログイン中' do
          include_context 'APIログイン処理'

          it_behaves_like 'パラメータ'
        end
        context 'APIログイン中（削除予約済み）' do
          include_context 'APIログイン処理', :destroy_reserved

          it_behaves_like 'パラメータ'
        end
      end
    end
  end
end
