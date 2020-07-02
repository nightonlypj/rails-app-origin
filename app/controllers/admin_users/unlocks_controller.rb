# frozen_string_literal: true

class AdminUsers::UnlocksController < Devise::UnlocksController
  layout 'admin_users'

  # GET /admin_users/unlock/new アカウントロック解除メール再送
  # def new
  #   super
  # end

  # POST /admin_users/unlock アカウントロック解除メール再送(処理)
  # def create
  #   super
  # end

  # GET /admin_users/unlock アカウントロック解除(処理)
  # def show
  #   super
  # end

  # protected

  # The path used after sending unlock password instructions
  # def after_sending_unlock_instructions_path_for(resource)
  #   super(resource)
  # end

  # The path used after unlocking the resource
  # def after_unlock_path_for(resource)
  #   super(resource)
  # end
end
