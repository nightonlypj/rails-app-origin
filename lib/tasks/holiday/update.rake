# 国民の祝日について - 内閣府
#  https://www8.cao.go.jp/chosei/shukujitsu/gaiyou.html
HOLIDAY_CSV_URL = 'https://www8.cao.go.jp/chosei/shukujitsu/syukujitsu.csv'.freeze
HOLIDAY_HEADER_DATE = '国民の祝日・休日月日'.freeze
HOLIDAY_HEADER_NAME = '国民の祝日・休日名称'.freeze

namespace :holiday do
  require 'open-uri'
  require 'nkf'
  require 'csv'

  desc '祝日データ更新（前年の2月に元データが更新される） -> tool:create_yamlでseed更新'
  task :update, [:dry_run] => :environment do |task, args|
    dry_run = args['dry_run'].to_s != 'false'

    logger = new_logger(task.name)
    logger.info "=== START #{task.name}[#{dry_run}] ==="

    datas = {}
    body = OpenURI.open_uri(HOLIDAY_CSV_URL).read
    body.force_encoding(NKF.guess(body))
    CSV.parse(body.encode(Encoding::UTF_8), headers: true) do |row|
      datas[row[HOLIDAY_HEADER_DATE].to_date] = row[HOLIDAY_HEADER_NAME].strip
    end

    datas_count = datas.count
    insert_datas = []
    update_datas = []
    start_time = Time.current
    ActiveRecord::Base.connection_pool.with_connection do # NOTE: 念の為（PG::UnableToSend: no connection to the server対策）
      holidays = Holiday.where(date: datas.keys).index_by(&:date)
      datas.each.with_index(1) do |(key, value), index|
        logger.info "[#{index}/#{datas_count}] key: #{key}, value: #{value}"
        if holidays[key].present? && holidays[key].name == value
          logger.info '...Skip'
          next
        end

        if holidays[key].blank?
          insert_datas.push(date: key, name: value, created_at: start_time, updated_at: start_time)
        else
          update_datas.push(holidays[key].attributes.symbolize_keys.merge(name: value, updated_at: start_time))
        end
      end

      next if dry_run

      Holiday.insert_all!(insert_datas) if insert_datas.present?
      Holiday.upsert_all(update_datas) if update_datas.present?
    end

    logger.info "=== END #{task.name} (Total count: #{datas_count}, insert: #{insert_datas.count}, update: #{update_datas.count}) ==="
  end
end
