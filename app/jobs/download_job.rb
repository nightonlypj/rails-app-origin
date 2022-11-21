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

      DownloadFile.create!(download: @download, body: file_body)
      @download.status = :success
      @download.completed_at = Time.current
      @download.save!
    end

    logger.info("=== END #{self.class.name}.#{__method__}(#{download.id}) ===")
  end

  private

  def status_failure(error)
    @download.status = :failure
    @download.error_message = error.message
    @download.completed_at = Time.current
    @download.save!
  end

  def file_body
    output_items = eval(@download.output_items)

    case @download.model.to_sym
    when :member
      set_space
      file_data = member_file_data(output_items)
    else
      raise 'model not found.'
    end

    change_char(file_header(output_items) + file_data)
  end

  def set_space
    @space = @download.space
    @current_member = Member.where(space: @space, user: @download.user)&.first
    raise 'current_member not found.' if @current_member.blank?
  end

  def file_header(output_items)
    header = []
    items = I18n.t("items.#{@download.model}")
    output_items.each do |output_item|
      value = items[output_item.to_sym]
      raise 'output_item not found.' if value.blank?

      header.push(value)
    end

    header.to_csv(col_sep: @download.col_sep, row_sep: @download.row_sep)
  end

  def change_char(result)
    case @download.char.to_sym
    when :sjis
      result.encode('Windows-31J', invalid: :replace, undef: :replace)
    when :eucjp
      result.encode('EUC-JP', invalid: :replace, undef: :replace)
    when :utf8
      result
    else
      raise 'char not found.'
    end
  end
end
