module DownloadsHelper
  # ダウンロード結果一覧のクラス名を返却
  def download_lists_class_name(download)
    if download.status.to_sym == :success
      return download.last_downloaded_at.present? ? ' row_inactive' : ' row_active'
    end

    return ' row_active' if download.id == params[:id].to_i
    return ' row_inactive' if download.status.to_sym == :failure

    nil
  end
end
