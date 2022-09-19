json.success true
json.infomation do
  json.partial! 'infomations/infomation', infomation: @infomation, use_body: true
end
