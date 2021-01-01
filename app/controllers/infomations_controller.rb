class InfomationsController < ApplicationController
  # GET /infomations
  # GET /infomations.json
  def index
    @infomations = Infomation.all
  end

  # GET /infomations/1
  # GET /infomations/1.json
  # def show
  # end
end
