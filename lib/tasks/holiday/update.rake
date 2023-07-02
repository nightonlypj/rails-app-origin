# 国民の祝日について - 内閣府
#  https://www8.cao.go.jp/chosei/shukujitsu/gaiyou.html
HOLIDAY_CSV_URL = 'https://www8.cao.go.jp/chosei/shukujitsu/syukujitsu.csv'.freeze
HOLIDAY_HEADER_DATE = '国民の祝日・休日月日'.freeze
HOLIDAY_HEADER_NAME = '国民の祝日・休日名称'.freeze

namespace :holiday do
  require 'open-uri'
  require 'nkf'
  require 'csv'

  desc '祝日データ更新（前年の2月に元データが更新される） → tool:create_yamlでseed更新'
  task(:update, [:dry_run] => :environment) do |task, args|
    args.with_defaults(dry_run: 'true')
    dry_run = (args.dry_run != 'false')

    logger = new_logger(task.name)
    logger.info("=== START #{task.name} ===")
    logger.info("dry_run: #{dry_run}")

    datas = {}
    body = OpenURI.open_uri(HOLIDAY_CSV_URL).read
    body.force_encoding(NKF.guess(body))
    CSV.parse(body.encode(Encoding::UTF_8), headers: true) do |row|
      datas[row[HOLIDAY_HEADER_DATE].to_date] = row[HOLIDAY_HEADER_NAME].strip
    end

    insert_datas = []
    update_datas = []
    now = Time.current
    ActiveRecord::Base.connection_pool.with_connection do # NOTE: 念の為（PG::UnableToSend: no connection to the server対策）
      holidays = Holiday.where(date: datas.keys).index_by(&:date)
      datas.each do |key, value|
        next if holidays[key].present? && holidays[key].name == value

        if holidays[key].blank?
          insert_datas.push(date: key, name: value, created_at: now, updated_at: now)
        else
          update_datas.push(holidays[key].attributes.merge(name: value, updated_at: now))
        end
      end

      unless dry_run
        Holiday.insert_all!(insert_datas) if insert_datas.present?
        Holiday.upsert_all(update_datas) if update_datas.present?
      end
    end

    logger.info("Complete! ... Total count: #{datas.count}, insert: #{insert_datas.count}, update: #{update_datas.count}")
    logger.info("=== END #{task.name} ===")
  end
end
