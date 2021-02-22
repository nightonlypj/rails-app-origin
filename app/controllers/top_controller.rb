class TopController < ApplicationController
  # GET / トップページ
  def index
    user_id = current_user.present? ? current_user.id : nil
    @infomations = Infomation.order(started_at: 'DESC', id: 'DESC').page(1).per(Settings['infomations_limit'])
                             .where('started_at <= ? AND (ended_at IS NULL OR ended_at >= ?)', Time.current, Time.current)
                             .where('target = ? OR (target = ? AND user_id = ?)', Infomation.targets[:All], Infomation.targets[:User], user_id)
  end
end
