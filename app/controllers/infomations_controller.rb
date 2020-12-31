class InfomationsController < ApplicationController
  before_action :set_infomation, only: %i[show edit update destroy]

  # GET /infomations
  # GET /infomations.json
  def index
    @infomations = Infomation.all
  end

  # GET /infomations/1
  # GET /infomations/1.json
  def show; end

  # GET /infomations/new
  def new
    @infomation = Infomation.new
  end

  # GET /infomations/1/edit
  def edit; end

  # POST /infomations
  # POST /infomations.json
  def create
    @infomation = Infomation.new(infomation_params)

    respond_to do |format|
      if @infomation.save
        format.html { redirect_to @infomation, notice: 'Infomation was successfully created.' }
        format.json { render :show, status: :created, location: @infomation }
      else
        format.html { render :new }
        format.json { render json: @infomation.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /infomations/1
  # PATCH/PUT /infomations/1.json
  def update
    respond_to do |format|
      if @infomation.update(infomation_params)
        format.html { redirect_to @infomation, notice: 'Infomation was successfully updated.' }
        format.json { render :show, status: :ok, location: @infomation }
      else
        format.html { render :edit }
        format.json { render json: @infomation.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /infomations/1
  # DELETE /infomations/1.json
  def destroy
    @infomation.destroy
    respond_to do |format|
      format.html { redirect_to infomations_url, notice: 'Infomation was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_infomation
    @infomation = Infomation.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def infomation_params
    params.require(:infomation).permit(:title, :body, :target, :user_id)
  end
end
