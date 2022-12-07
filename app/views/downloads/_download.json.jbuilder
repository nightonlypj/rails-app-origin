json.id download.id
json.status download.status
json.status_i18n download.status_i18n
json.requested_at l(download.requested_at, format: :json)
json.completed_at l(download.completed_at, format: :json, default: nil)
json.last_downloaded_at l(download.last_downloaded_at, format: :json, default: nil)

json.model download.model
json.model_i18n download.model_i18n
if download.model.to_sym == :member
  json.space do
    json.partial! './spaces/space', space: download.space
  end
end

json.target download.target
json.target_i18n download.target_i18n
json.format download.format
json.format_i18n download.format_i18n
json.char_code download.char_code
json.char_code_i18n download.char_code_i18n
json.newline_code download.newline_code
json.newline_code_i18n download.newline_code_i18n
