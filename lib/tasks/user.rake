namespace :user do
  desc '削除予定日時を過ぎたユーザーのアカウントを削除'
  task(:destroy, [:dry_run] => :environment) do |task, args|
    args.with_defaults(dry_run: 'true')
    dry_run = (args.dry_run != 'false')

    logger = new_logger(task.name)
    logger.info("=== START #{task.name} ===")
    logger.info("dry_run: #{dry_run}")

    ActiveRecord::Base.connection_pool.with_connection do # NOTE: 念の為（PG::UnableToSend: no connection to the server対策）
      users = User.by_destroy_reserved
      logger.debug(users)

      count = users.count
      logger.info("count: #{count}")

      users.find_each.with_index(1) do |user, index|
        logger.info("[#{index}/#{count}] id: #{user.id}, destroy_schedule_at: #{user.destroy_schedule_at}")
        raise '削除予定日時が不正' if user.destroy_schedule_at > Time.current
        next if dry_run

        unless user.destroy
          logger.error('削除失敗')
          next
        end

        UserMailer.with(user: user).destroy_completed.deliver_now if Settings['sendmail_destroy_completed']
      end
    end

    logger.info("=== END #{task.name} ===")
  end
end
