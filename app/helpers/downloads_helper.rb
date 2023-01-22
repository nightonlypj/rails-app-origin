module DownloadsHelper
  # ダウンロード結果一覧のクラス名を返却
  def download_lists_class_name(download, target_id)
    if target_id.present?
      return download.last_downloaded_at.present? ? ' row_inactive' : ' row_active' if download.id == target_id

      return
    end

    return download.last_downloaded_at.present? ? ' row_inactive' : ' row_active' if download.status.to_sym == :success
    return ' row_inactive' if download.status.to_sym == :failure

    nil
  end
end
