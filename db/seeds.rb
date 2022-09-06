# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).

BULK_MAX_COUNT = 1000

# シーケンス更新 # Tips: id指定でinsert_allした場合、シーケンスが更新されない為(PostgreSQL)
def update_sequence
  return if @model.connection_db_config.configuration_hash[:adapter] != 'postgresql'

  @model.connection.execute(
    "SELECT setval(pg_get_serial_sequence('#{@model.table_name}', 'id'), (SELECT MAX(id) FROM #{@model.table_name}))"
  )
end

# 登録処理
def insert_contents(bulk_insert)
  count = 0
  insert_datas = []
  datas = @model.where(id: @ids)
  data = @model.new
  now = Time.current

  (@ids - datas.ids).each do |id|
    content = @contents[id]
    unless bulk_insert
      @model.create!(content)
      count += 1
      next
    end

    content['created_at'] = now if content['created_at'].blank?
    content['updated_at'] = now if content['updated_at'].blank?
    insert_datas.push(data.attributes.merge(content))
    next if insert_datas.count < BULK_MAX_COUNT

    @model.insert_all!(insert_datas)
    count += insert_datas.count
    insert_datas = []
  end
  if insert_datas.present?
    @model.insert_all!(insert_datas)
    count += insert_datas.count
  end

  update_sequence if count.positive?

  count
end

# 変更チェック
def data_changed?(content, data, new_model)
  content.each do |key, value|
    next if data[key] == value

    new_model[key] = value # Tips: 日付やenum等のフォーマット違いに対応
    return true if data[key] != new_model[key]
  end

  false
end

# 更新処理
def update_contents(bulk_update, exclude_update_column)
  count = 0
  update_datas = []
  datas = @model.where(id: @ids)
  new_model = @model.new
  now = Time.current

  datas.find_each do |data|
    content = @contents[data.id]
    next if content.blank?

    exclude_update_column.each { |key| content.delete(key) } if exclude_update_column.present?

    unless bulk_update
      data.assign_attributes(content)
      data.save!(validate: false)
      count += 1 if data.updated_at > now
      next
    end

    next unless data_changed?(content, data, new_model)

    content['updated_at'] = now if content['updated_at'].blank?
    update_datas.push(data.attributes.merge(content))
    next if update_datas.count < BULK_MAX_COUNT

    @model.upsert_all(update_datas)
    count += update_datas.count
    update_datas = []
  end
  if update_datas.present?
    @model.upsert_all(update_datas)
    count += update_datas.count
  end

  count
end

# 削除処理
def delete_contents(destroy)
  datas = @model.where.not(id: @ids)
  count = datas.count
  if destroy
    datas.destroy_all
  else
    datas.delete_all
  end

  count
end

total_insert_count = 0
total_update_count = 0
total_delete_count = 0
File.open("#{Rails.root}/db/seeds.yml") do |seed_body|
  YAML.safe_load(seed_body).each do |seed|
    if seed['env'][Rails.env] != true
      p "== file: #{seed['file']} ... Skip"
      next
    end

    p "== file: #{seed['file']}"
    File.open("#{Rails.root}/db/#{seed['file']}") do |file_body|
      yaml = YAML.safe_load(file_body)
      @contents = yaml.index_by { |content| content['id'] }
      raise 'idが重複しています。' if yaml.count != @contents.count

      @ids = @contents.keys
      @model = seed['model'].constantize
      p "count: #{@contents.count}, model: #{@model}"

      option = seed['option'].present? ? seed['option'] : {}
      insert_count = seed['insert'] == true ? insert_contents(option['bulk_insert'] == true) : nil
      update_count = seed['update'] == true ? update_contents(option['bulk_update'] == true, option['exclude_update_column']) : nil
      delete_count = seed['delete'] == true ? delete_contents(option['destroy'] == true) : nil
      p "insert: #{insert_count.present? ? insert_count : '-'}, " \
        "update: #{update_count.present? ? update_count : '-'}, " \
        "delete: #{delete_count.present? ? delete_count : '-'}"

      total_insert_count += insert_count if insert_count.present?
      total_update_count += update_count if update_count.present?
      total_delete_count += delete_count if delete_count.present?
    end
  end
end
p "Complete! ... Total insert: #{total_insert_count}, update: #{total_update_count}, delete: #{total_delete_count}"
