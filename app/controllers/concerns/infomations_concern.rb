module InfomationsConcern
  extend ActiveSupport::Concern

  private

  # 大切なお知らせ
  def set_important_infomations
    @infomations = Infomation.by_target(current_user).by_force
  end
end
