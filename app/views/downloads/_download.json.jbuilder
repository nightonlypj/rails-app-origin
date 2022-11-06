json.id download.id
json.status download.status
json.status_i18n download.status_i18n
json.requested_at l(download.requested_at, format: :json)
json.completed_at download.completed_at.present? ? l(download.completed_at, format: :json) : nil
json.last_downloaded_at download.last_downloaded_at.present? ? l(download.last_downloaded_at, format: :json) : nil

json.model download.model
json.model_i18n download.model_i18n
if download.model.to_sym == :member
  json.space do
    json.partial! 'spaces/space', space: download.space
  end
end

json.target download.target
json.target_i18n download.target_i18n
json.format download.format
json.format_i18n download.format_i18n
json.char download.char
json.char_i18n download.char_i18n
json.newline download.newline
json.newline_i18n download.newline_i18n
