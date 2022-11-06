class DownloadJob < ApplicationJob
  include MembersDownloadConcern
  queue_as :default
  rescue_from StandardError, with: :status_failure

  # ダウンロードファイル作成
  def perform(download)
    @download = download
    logger.info("=== START #{self.class.name}.#{__method__}(#{download.id}) ===")

    ActiveRecord::Base.connection_pool.with_connection do
      @download.status = :processing
      @download.save!

      DownloadFile.create!(download: @download, file: download_file)
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

  def download_file
    output_items = eval(@download.output_items)

    case @download.model.to_sym
    when :member
      set_space
      result = members_file(output_items)
    else
      raise 'model not found.'
    end

    change_char(file_header(output_items) + result)
  end

  def set_space
    @space = @download.space
    @current_member = Member.where(space: @space, user: @download.user)&.first
    raise 'current_member not found.' if @current_member.blank?
  end

  def file_header(output_items)
    header = []
    items = I18n.t("items.#{@download.model}")
    output_items.each { |output_item| header.push(items[output_item.to_sym]) }

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
