namespace :space do
  desc 'スペース削除（削除予定日時以降）'
  task(:destroy, [:dry_run] => :environment) do |task, args|
    args.with_defaults(dry_run: 'true')
    dry_run = (args.dry_run != 'false')

    logger = new_logger(task.name)
    logger.info("=== START #{task.name} ===")
    logger.info("dry_run: #{dry_run}")

    ActiveRecord::Base.connection_pool.with_connection do # NOTE: 念の為（PG::UnableToSend: no connection to the server対策）
      spaces = Space.destroy_target
      logger.debug(spaces)

      count = spaces.count
      logger.info("count: #{count}")

      spaces.find_each.with_index(1) do |space, index|
        logger.info("[#{index}/#{count}] id: #{space.id}, destroy_schedule_at: #{space.destroy_schedule_at}")
        raise '削除予定日時が不正' if space.destroy_schedule_at.blank? || space.destroy_schedule_at > Time.current
        next if dry_run

        space.destroy!
      end
    end

    logger.info("=== END #{task.name} ===")
  end
end
