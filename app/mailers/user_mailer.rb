class UserMailer < ApplicationMailer
  # アカウント削除受け付けのお知らせ
  def destroy_reserved
    @undo_delete_url = params[:undo_delete_url]
    send_mail('mailer.user.destroy_reserved.subject')
  end

  # アカウント削除取り消し完了のお知らせ
  def undo_destroy_reserved
    send_mail('mailer.user.undo_destroy_reserved.subject')
  end

  # アカウント削除完了のお知らせ
  def destroy_completed
    send_mail('mailer.user.destroy_completed.subject')
  end
end
