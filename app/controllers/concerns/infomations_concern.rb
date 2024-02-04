module InfomationsConcern
  extend ActiveSupport::Concern

  private

  # 大切なお知らせ一覧
  def set_important_infomations
    @infomations = Infomation.by_locale(I18n.locale).by_target(current_user).by_force.order(started_at: :desc, id: :desc)
  end
end
