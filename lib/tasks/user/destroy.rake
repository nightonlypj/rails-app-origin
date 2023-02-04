namespace :user do
  desc 'ユーザーアカウント削除（削除予定日時以降）'
  task(:destroy, [:dry_run] => :environment) do |task, args|
    args.with_defaults(dry_run: 'true')
    dry_run = (args.dry_run != 'false')

    logger = new_logger(task.name)
    logger.info("=== START #{task.name} ===")
    logger.info("dry_run: #{dry_run}")

    ActiveRecord::Base.connection_pool.with_connection do # NOTE: 念の為（PG::UnableToSend: no connection to the server対策）
      users = User.destroy_target
      logger.debug(users)

      count = users.count
      logger.info("count: #{count}")

      users.find_each.with_index(1) do |user, index|
        logger.info("[#{index}/#{count}] id: #{user.id}, destroy_schedule_at: #{user.destroy_schedule_at}")
        raise '削除予定日時が不正' if user.destroy_schedule_at.blank? || user.destroy_schedule_at > Time.current
        next if dry_run

        user.destroy!
        UserMailer.with(user: user).destroy_completed.deliver_now if Settings.sendmail_destroy_completed
      end
    end

    logger.info("=== END #{task.name} ===")
  end
end
