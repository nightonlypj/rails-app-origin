class InfomationsController < ApplicationController
  # GET /infomations お知らせ一覧
  # GET /infomations.json お知らせ一覧API
  def index
    user_id = current_user.present? ? current_user.id : nil
    @infomations = Infomation.order(started_at: 'DESC', id: 'DESC').page(params[:page]).per(Settings['default_infomations_limit'])
                             .where('started_at <= ? AND (ended_at IS NULL OR ended_at >= ?)', Time.current, Time.current)
                             .where('target = ? OR (target = ? AND target_user_id = ?)', Infomation.targets[:All], Infomation.targets[:User], user_id)
  end

  # GET /infomations/1
  # GET /infomations/1.json
  # def show
  # end
end
