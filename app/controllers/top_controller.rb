class TopController < ApplicationController
  # GET / トップページ
  def index
    @infomations = Infomation.order(started_at: 'DESC', id: 'DESC').page(1).per(Settings['infomations_limit'])
                             .where('started_at <= ? AND (ended_at IS NULL OR ended_at >= ?)', Time.current, Time.current)
                             .where('target = ? OR (target = ? AND user_id = ?)', Infomation.targets[:All], Infomation.targets[:User], current_user&.id)
  end
end
