# :nocov:
namespace :tool do
  desc 'DBの値をyamlファイルに出力（seed作成・更新に使用） 例: rails "tool:create_yaml[db/seed/holidays.yml,Holiday,id,date,name]"'
  task(:create_yaml, %w[file model] => :environment) do |_, args|
    file = args.file
    model = args.model&.constantize
    columns = args.extras.compact
    raise '出力ファイル名を指定してください。' if file.blank?
    raise 'モデルが存在しません。' if model.blank?
    raise '出力カラムを指定してください。' if columns.count.zero? || columns == ['']

    body = ''
    contents = model.order(model.primary_key)
    contents.each do |content|
      columns.each_with_index do |column, index|
        if content[column].nil?
          data = 'null'
        elsif %i[integer float decimal timestamp boolean].include?(model.columns_hash[column].type)
          data = content[column]
        else
          data = format('"%s"', content[column].to_s.gsub(/"/, '\"').gsub(/\r/, '\\r').gsub(/\n/, '\\n'))
        end
        body += (index.zero? ? '- ' : '  ') + "#{column}: #{data}\n"
      end
    end

    File.write(file, body, mode: 'w')
  end
end
# :nocov:
