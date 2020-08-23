# log出力と、ドライランのみ標準出力
def logger_info_and_puts(dry_run, logger, message)
  logger.info(message)
  p message if dry_run
end
