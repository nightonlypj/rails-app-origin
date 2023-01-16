namespace :download do
  desc "ダウンロード削除（完了日時か依頼日時の#{Settings['download_destroy_schedule_days']}日後以降）"
  task(:destroy, [:dry_run] => :environment) do |task, args|
    args.with_defaults(dry_run: 'true')
    dry_run = (args.dry_run != 'false')

    logger = new_logger(task.name)
    logger.info("=== START #{task.name} ===")
    logger.info("dry_run: #{dry_run}")

    ActiveRecord::Base.connection_pool.with_connection do # NOTE: 念の為（PG::UnableToSend: no connection to the server対策）
      downloads = Download.destroy_target
      logger.debug(downloads)

      count = downloads.count
      logger.info("count: #{count}")

      schedule_date = Time.current - Settings['download_destroy_schedule_days'].days
      downloads.find_each.with_index(1) do |download, index|
        logger.info("[#{index}/#{count}] id: #{download.id}, completed_at: #{download.completed_at}, requested_at: #{download.requested_at}")

        target_completed = download.completed_at.present? && download.completed_at <= schedule_date
        target_requested = download.completed_at.blank? && download.requested_at <= schedule_date
        raise '完了日時または依頼日時が不正' if !target_completed && !target_requested
        next if dry_run

        download.destroy!
      end
    end

    logger.info("=== END #{task.name} ===")
  end
end
