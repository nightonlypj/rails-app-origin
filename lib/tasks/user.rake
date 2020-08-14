require './lib/tasks/application.rb'

namespace :user do
  desc '削除予定日時を過ぎたユーザーのアカウントを削除'
  task :destroy, [:dry_run] => :environment do |_, args|
    args.with_defaults(dry_run: 'true')
    dry_run = (args.dry_run != 'false')

    logger = Logger.new("log/user_destroy_#{Rails.env}.log")
    logger.info('=== START ===')
    logger_info_and_puts(dry_run, logger, "dry_run: #{dry_run}")

    users = User.where('destroy_schedule_at <= ?', Time.current).order(:destroy_schedule_at).order(:id)
    logger.debug(users)

    count = users.count
    logger_info_and_puts(dry_run, logger, "count: #{count}")

    users.each.with_index(1) do |user, index|
      target = "[#{index}/#{count}] id: #{user.id}, destroy_requested_at: #{user.destroy_requested_at}, destroy_schedule_at: #{user.destroy_schedule_at}"
      if dry_run
        logger_info_and_puts(dry_run, logger, "#{target} ... Target of destroy")
        next
      end

      logger_info_and_puts(dry_run, logger, "#{target} ... Destroy")
      unless user.destroy
        logger.error('User destroy')
        next
      end

      # TODO: メール送信
    end

    logger.info('=== END ===')
  end
end
