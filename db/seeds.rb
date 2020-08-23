# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

paths = ['', "#{Rails.env}/"]
paths.each do |path|
  Dir.glob("#{Rails.root}/db/seed/#{path}*.yml").each do |filename|
    p "filename: #{filename}"

    target_model = File.basename(filename, '.yml').classify.constantize
    p "model: #{target_model}"

    File.open(filename) do |file_contents|
      yaml_contents = YAML.safe_load(file_contents)
      count = yaml_contents.count
      p "count: #{count}"

      yaml_contents.each.with_index(1) do |yaml_record, index|
        id = yaml_record['id']
        target = "[#{index}/#{count}] id: #{id}"

        if target_model.find_by(id: id)
          p "#{target} ... Skip create"
          next
        end

        p "#{target} ... Create"
        target_model.create(yaml_record)
      end
    end
  end
end
