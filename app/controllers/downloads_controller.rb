class DownloadsController < ApplicationController
  before_action :set_download, only: %i[show edit update destroy]

  # GET /downloads or /downloads.json
  def index
    @downloads = Download.all
  end

  # GET /downloads/1 or /downloads/1.json
  def show; end

  # GET /downloads/new
  def new
    @download = Download.new
  end

  # GET /downloads/1/edit
  def edit; end

  # POST /downloads or /downloads.json
  def create
    @download = Download.new(download_params)

    respond_to do |format|
      if @download.save
        format.html { redirect_to @download, notice: 'Download was successfully created.' }
        format.json { render :show, status: :created, location: @download }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @download.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /downloads/1 or /downloads/1.json
  def update
    respond_to do |format|
      if @download.update(download_params)
        format.html { redirect_to @download, notice: 'Download was successfully updated.' }
        format.json { render :show, status: :ok, location: @download }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @download.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /downloads/1 or /downloads/1.json
  def destroy
    @download.destroy
    respond_to do |format|
      format.html { redirect_to downloads_url, notice: 'Download was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_download
    @download = Download.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def download_params
    params.fetch(:download, {})
  end
end
