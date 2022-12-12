json.code user.code
json.upload_image current_user.image?
json.image_url do
  json.mini "#{Settings['base_image_url']}#{user.image_url(:mini)}"
  json.small "#{Settings['base_image_url']}#{user.image_url(:small)}"
  json.medium "#{Settings['base_image_url']}#{user.image_url(:medium)}"
  json.large "#{Settings['base_image_url']}#{user.image_url(:large)}"
  json.xlarge "#{Settings['base_image_url']}#{user.image_url(:xlarge)}"
end
json.name user.name
json.email user.email if use_email
