class DownloadJob < ApplicationJob
  include MembersConcern
  queue_as :default
  rescue_from StandardError, with: :status_failure

  # ダウンロードファイル作成
  def perform(download)
    @download = download
    logger.info("=== START #{self.class.name}.#{__method__}(#{download.id}) ===")

    ActiveRecord::Base.connection_pool.with_connection do
      @download.status = :processing
      @download.save!

      # sleep(10) # NOTE: デバッグ用
      output_items = eval(@download.output_items)
      DownloadFile.create!(download: @download, body: change_char_code(file_header(output_items) + file_data(output_items)))

      @download.attributes = { status: :success, completed_at: Time.current }
      @download.save!
    end

    logger.info("=== END #{self.class.name}.#{__method__}(#{download.id}) ===")
  end

  # ステータスを失敗に変更 # NOTE: テストの為、publicに記載
  def status_failure(error)
    # 例外通知
    ExceptionNotifier.notify_exception(error)

    if @download.present?
      @download.attributes = { status: :failure, error_message: error&.message, completed_at: Time.current }
      logger.warn("[WARN]Failed save: download.id = #{@download.id}, error_message = #{error&.message}") unless @download.save(validate: false)
    end
  end

  private

  def file_header(output_items)
    header = []
    items = I18n.t("items.#{@download.model}")
    output_items.each do |output_item|
      value = items[output_item.to_sym]
      raise "output_item not found.(#{output_item})" if value.blank?

      header.push(value)
    end

    header.to_csv(col_sep: @download.col_sep, row_sep: @download.row_sep)
  end

  def file_data(output_items)
    case @download.model.to_sym
    when :member
      set_space_current_member
      member_file_data(output_items)
    else
      # :nocov:
      raise "model not found.(#{model})"
      # :nocov:
    end
  end

  def set_space_current_member
    @space = @download.space
    raise 'space not found.' if @space.blank?

    @current_member = Member.where(space: @space, user: @download.user)&.first
    raise 'current_member not found.' if @current_member.blank?
    raise 'power not found.' unless @current_member.power_admin?
  end

  def change_char_code(result)
    case @download.char_code.to_sym
    when :sjis
      result.encode('Windows-31J', invalid: :replace, undef: :replace)
    when :eucjp
      result.encode('EUC-JP', invalid: :replace, undef: :replace)
    when :utf8
      result
    else
      # :nocov:
      raise "char_code not found.(#{char_code})"
      # :nocov:
    end
  end
end
