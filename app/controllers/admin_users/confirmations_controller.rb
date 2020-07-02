# frozen_string_literal: true

class AdminUsers::ConfirmationsController < Devise::ConfirmationsController
  layout 'admin_users'

  # GET /admin_users/confirmation/new メールアドレス確認メール再送
  # def new
  #   super
  # end

  # POST /admin_users/confirmation メールアドレス確認メール再送(処理)
  # def create
  #   super
  # end

  # GET /admin_users/confirmation メールアドレス確認(処理)
  # def show
  #   super
  # end

  # protected

  # The path used after resending confirmation instructions.
  # def after_resending_confirmation_instructions_path_for(resource_name)
  #   super(resource_name)
  # end

  # The path used after confirmation.
  # def after_confirmation_path_for(resource_name, resource)
  #   super(resource_name, resource)
  # end
end
