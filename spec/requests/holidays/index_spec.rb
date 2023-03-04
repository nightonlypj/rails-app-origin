require 'rails_helper'

RSpec.describe 'Holidays', type: :request do
  let(:response_json) { JSON.parse(response.body) }
  let(:response_json_holidays) { response_json['holidays'] }

  # GET /holidays(.json) 祝日一覧API
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）, APIログイン中, APIログイン中（削除予約済み）
  #   パラメータなし, 有効なパラメータ, 無効なパラメータ
  #   ＋URLの拡張子: .json, ない
  #   ＋Acceptヘッダ: JSONが含まれる, JSONが含まれない
  describe 'GET #index' do
    subject { get holidays_path(format: subject_format), params: params, headers: auth_headers.merge(accept_headers) }
    let_it_be(:start_date) { Time.current.to_date.beginning_of_year }
    let_it_be(:end_date)   { Time.current.to_date.end_of_year }

    before_all { FactoryBot.create(:holiday, date: start_date - 1.day) }
    let_it_be(:holidays) do
      [
        FactoryBot.create(:holiday, date: start_date),
        FactoryBot.create(:holiday, date: end_date)
      ]
    end
    before_all { FactoryBot.create(:holiday, date: end_date + 1.day) }

    # テスト内容
    shared_examples_for 'ToOK(json/json)' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it 'HTTPステータスが200。対象項目が一致する' do
        is_expected.to eq(200)
        expect(response_json['success']).to eq(true)

        search_params = { start_date: I18n.l(start_date, format: :json), end_date: I18n.l(end_date, format: :json) }
        expect(response_json['search_params']).to eq(search_params.stringify_keys)

        expect(response_json_holidays.count).to eq(holidays.count)
        holidays.each_with_index do |holiday, index|
          expect(response_json_holidays[index]['date']).to eq(I18n.l(holiday.date, format: :json))
          expect(response_json_holidays[index]['name']).to eq(holiday.name)
        end
      end
    end

    # テストケース
    shared_examples_for 'パラメータなし' do
      let(:params) { nil }
      it_behaves_like 'ToNG(html)', 406
      it_behaves_like 'ToOK(json)'
    end
    shared_examples_for '有効なパラメータ' do
      let(:params) { { start_date: start_date, end_date: end_date } }
      it_behaves_like 'ToNG(html)', 406
      it_behaves_like 'ToOK(json)'
    end
    shared_examples_for '無効なパラメータ' do
      let(:params) { { start_date: '', end_date: 'x' } }
      it_behaves_like 'ToNG(html)', 406
      it_behaves_like 'ToOK(json)'
    end

    shared_examples_for 'OK' do
      it_behaves_like 'パラメータなし'
      it_behaves_like '有効なパラメータ'
      it_behaves_like '無効なパラメータ'
    end

    context '未ログイン' do
      include_context '未ログイン処理'
      it_behaves_like 'OK'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'OK'
    end
    context 'ログイン中（削除予約済み）' do
      include_context 'ログイン処理', :destroy_reserved
      it_behaves_like 'OK'
    end
    context 'APIログイン中' do
      include_context 'APIログイン処理'
      it_behaves_like 'OK'
    end
    context 'APIログイン中（削除予約済み）' do
      include_context 'APIログイン処理', :destroy_reserved
      it_behaves_like 'OK'
    end
  end
end
