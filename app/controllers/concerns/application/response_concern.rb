module Application::ResponseConcern
  extend ActiveSupport::Concern

  private

  # リクエストのuidヘッダを[id+36**2](36進数)からuidに変更 # NOTE: uidがメールアドレスだと、メールアドレス確認後に認証に失敗する為
  def update_request_uid_header
    return if request.headers['uid'].blank?

    user = User.find_by(id: request.headers['uid'].to_i(36) - (36**2))
    request.headers['uid'] = user&.uid
  end

  # レスポンスのuidヘッダをuidから[id+36**2](36進数)に変更
  def update_response_uid_header
    return if response.headers['uid'].blank?

    user = User.find_by(uid: response.headers['uid'])
    response.headers['uid'] = user.present? ? (user.id + (36**2)).to_s(36) : nil
  end

  # URLの拡張子がHTMLか、acceptヘッダに含まれるかを返却
  def format_html?
    request.format.html?
  end

  # URLの拡張子がJSONか、acceptヘッダに含まれるかを返却
  def format_json?
    request.format.json?
  end

  # acceptヘッダにJSONが含まれる（ワイルドカード不可）かを返却
  def accept_header_json?
    !(%r{,application/json[,;]} =~ target_accept_header).nil?
  end

  def target_accept_header
    ",#{request.headers[:ACCEPT]&.gsub(' ', '')},"
  end

  # acceptヘッダが空か、HTMLが含まれる（ワイルドカード可）かを返却
  def accept_header_html?
    request.headers[:ACCEPT].blank? ||
      !(%r{,text/html[,;]} =~ target_accept_header).nil? ||
      !(%r{,\*/\*[,;]} =~ target_accept_header).nil?
  end

  # APIのみモードでAPIリクエストでない場合、存在しない(404)を返却
  def response_not_found_for_api_mode_not_api
    head :not_found if Settings.api_only_mode && format_html?
  end

  # HTMLリクエストに不整合がある場合、HTTPステータス406を返却（明示的にHTMLのみ対応にする場合に使用）
  def response_not_acceptable_for_not_html
    head :not_acceptable if !format_html? || !accept_header_html?
  end

  # APIリクエストに不整合がある場合、HTTPステータス406を返却（明示的にAPIのみ対応にする場合に使用）
  def response_not_acceptable_for_not_api
    head :not_acceptable if !format_json? || !accept_header_json?
  end

  # 認証エラーを返却
  def response_unauthenticated
    render '/failure', locals: { alert: t('devise.failure.unauthenticated') }, status: :unauthorized
  end

  # 認証済みエラーを返却
  def response_already_authenticated
    render '/failure', locals: { alert: t('devise.failure.already_authenticated') }, status: :unauthorized
  end

  # ユーザーが削除予約済みの場合、リダイレクトしてメッセージを表示
  def redirect_for_user_destroy_reserved(path = root_path)
    redirect_to path, alert: t('alert.user.destroy_reserved') if current_user.destroy_reserved?
  end

  # ユーザーが削除予約済みの場合、JSONでメッセージを返却
  def response_api_for_user_destroy_reserved
    render '/failure', locals: { alert: t('alert.user.destroy_reserved') }, status: :unprocessable_entity if current_user&.destroy_reserved?
  end

  # ユーザーが削除予約済みでない場合、リダイレクトしてメッセージを表示
  def redirect_for_not_user_destroy_reserved
    redirect_to root_path, alert: t('alert.user.not_destroy_reserved') unless current_user.destroy_reserved?
  end

  # ユーザーが削除予約済みでない場合、JSONでメッセージを返却
  def response_api_for_not_user_destroy_reserved
    render '/failure', locals: { alert: t('alert.user.not_destroy_reserved') }, status: :unprocessable_entity unless current_user&.destroy_reserved?
  end
end
