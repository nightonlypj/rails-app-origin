class HolidaysController < ApplicationAuthController
  before_action :response_not_acceptable_for_not_api

  # GET /holidays(.json) 祝日一覧API
  def index
    @start_date = change_date(params[:start_date], Time.zone.today.beginning_of_year)
    @end_date = change_date(params[:end_date], @start_date + 1.year - 1.day)
    @holidays = Holiday.where(date: @start_date..@end_date).order(:date)
  end

  private

  def change_date(value, default)
    value.to_date || default
  rescue StandardError
    default
  end
end
