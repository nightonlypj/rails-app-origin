namespace :user do
  desc 'ユーザーアカウント削除（削除予定日時以降）'
  task :destroy, [:dry_run] => :environment do |task, args|
    dry_run = args['dry_run'].to_s != 'false'

    logger = new_logger(task.name)
    logger.info "=== START #{task.name}[#{dry_run}] ==="

    users_count = 0
    ActiveRecord::Base.connection_pool.with_connection do # NOTE: 念の為（PG::UnableToSend: no connection to the server対策）
      users = User.destroy_target
      logger.debug { users }

      users_count = users.count
      users.find_each.with_index(1) do |user, index|
        logger.info "[#{index}/#{users_count}] id: #{user.id}, destroy_schedule_at: #{user.destroy_schedule_at}"
        # :nocov:
        raise '削除予定日時が不正' if user.destroy_schedule_at.blank? || user.destroy_schedule_at > Time.current
        # :nocov:
        next if dry_run

        user.destroy!
        # :nocov:
        UserMailer.with(user:).destroy_completed.deliver_now if Settings.sendmail_destroy_completed
        # :nocov:
      end
    end

    logger.info "=== END #{task.name} (count: #{users_count}) ==="
  end
end
