class TopController < ApplicationController
  # GET / トップページ
  def index
    @infomations = Infomation.by_target_period.by_target_user(current_user).page(1).per(Settings['infomations_limit'])
  end
end
