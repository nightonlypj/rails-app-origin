shared_context 'ダウンロード結果一覧作成' do |waiting_count, processing_count, success_count, failure_count, downloaded_count|
  let_it_be(:space) { FactoryBot.create(:space) }
  let_it_be(:downloads) do
    FactoryBot.create_list(:download, waiting_count, :waiting, model: 'member', space: space, user: user, target: :select, select_items: '["code000000000000000000001", "code000000000000000000002"]') +
      FactoryBot.create_list(:download, processing_count, :processing, model: 'member', space: space, user: user, target: :search, search_params: '{"text"=>"aaa"}') +
      FactoryBot.create_list(:download, success_count, :success, model: 'member', space: space, user: user, format: :csv, char_code: :sjis, newline_code: :crlf) +
      FactoryBot.create_list(:download, failure_count, :failure, model: 'member', space: space, user: user, format: :tsv, char_code: :eucjp, newline_code: :lf) +
      FactoryBot.create_list(:download, downloaded_count, :downloaded, model: 'member', space: space, user: user, target: :all, char_code: :utf8, newline_code: :cr)
  end
  before_all { FactoryBot.create(:download, :success, model: 'member', space: space) } # NOTE: 対象外
end

# テスト内容（共通）
def expect_download_json(response_json_download, download)
  result = 16
  expect(response_json_download['id']).to eq(download.id)
  expect(response_json_download['status']).to eq(download.status)
  expect(response_json_download['status_i18n']).to eq(download.status_i18n)
  expect(response_json_download['requested_at']).to eq(I18n.l(download.requested_at, format: :json))
  expect(response_json_download['completed_at']).to eq(I18n.l(download.completed_at, format: :json, default: nil))
  expect(response_json_download['last_downloaded_at']).to eq(I18n.l(download.last_downloaded_at, format: :json, default: nil))

  expect(response_json_download['model']).to eq(download.model)
  expect(response_json_download['model_i18n']).to eq(download.model_i18n)

  data = response_json_download['space']
  case download.model.to_sym
  when :member
    count = expect_space_basic_json(data, download.space)
    expect(data.count).to eq(count)
    result += 1
  else
    # :nocov:
    raise "model not found.(#{model})"
    # :nocov:
  end

  expect(response_json_download['target']).to eq(download.target)
  expect(response_json_download['target_i18n']).to eq(download.target_i18n)
  expect(response_json_download['format']).to eq(download.format)
  expect(response_json_download['format_i18n']).to eq(download.format_i18n)
  expect(response_json_download['char_code']).to eq(download.char_code)
  expect(response_json_download['char_code_i18n']).to eq(download.char_code_i18n)
  expect(response_json_download['newline_code']).to eq(download.newline_code)
  expect(response_json_download['newline_code_i18n']).to eq(download.newline_code_i18n)

  result
end
