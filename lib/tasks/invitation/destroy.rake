namespace :invitation do
  desc "招待削除（削除予定日時または終了日時か参加日時から#{Settings.invitation_destroy_schedule_days}日後以降）"
  task(:destroy, [:dry_run] => :environment) do |task, args|
    args.with_defaults(dry_run: 'true')
    dry_run = (args.dry_run != 'false')

    logger = new_logger(task.name)
    logger.info("=== START #{task.name} ===")
    logger.info("dry_run: #{dry_run}")

    ActiveRecord::Base.connection_pool.with_connection do # NOTE: 念の為（PG::UnableToSend: no connection to the server対策）
      invitations = Invitation.destroy_target
      logger.debug(invitations)

      count = invitations.count
      logger.info("count: #{count}")

      schedule_date = Time.current - Settings.invitation_destroy_schedule_days.days
      invitations.find_each.with_index(1) do |invitation, index|
        logger.info("[#{index}/#{count}] id: #{invitation.id}, destroy_schedule_at: #{invitation.destroy_schedule_at}, " \
          + "ended_at: #{invitation.ended_at}, email_joined_at: #{invitation.email_joined_at}")

        if invitation.destroy_schedule_at.present?
          raise '削除予定日時が不正' if invitation.destroy_schedule_at > Time.current
        else
          target_ended = invitation.ended_at.present? && invitation.ended_at <= schedule_date
          target_email_joined = invitation.email_joined_at.present? && invitation.email_joined_at <= schedule_date
          raise '終了日時または参加日時が不正' if !target_ended && !target_email_joined
        end
        next if dry_run

        invitation.destroy!
      end
    end

    logger.info("=== END #{task.name} ===")
  end
end
