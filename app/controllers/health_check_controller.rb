class HealthCheckController < ApplicationController
  # GET /_health ヘルスチェック
  def index
    ActiveRecord::Base.connection.execute('SELECT 1') if %w[all db].include?(params[:target])

    render plain: 'OK'
  rescue ActiveRecord::ActiveRecordError => e
    render plain: e.class, status: :service_unavailable
  end
end
