module Application::LocaleConcern
  extend ActiveSupport::Concern

  private

  def switch_locale(&)
    return I18n.with_locale(I18n.default_locale.to_s, &) if Settings.locales.keys.count < 2 || redirect_switch_locale || Rails.env.test?

    locale = params[:locale] || cookies[:locale] || http_accept_language.compatible_language_from(I18n.available_locales).to_s || I18n.default_locale.to_s
    return redirect_to "/#{locale}#{request.fullpath}" if format_html? && params[:locale].blank? && locale != I18n.default_locale.to_s

    cookies[:locale] = locale if format_html?
    I18n.with_locale(locale, &)
  end

  def default_url_options
    { locale: I18n.locale == I18n.default_locale ? nil : I18n.locale }
  end

  def redirect_switch_locale
    new_locale = params[:switch_locale]
    return false if !format_html? || new_locale.blank? || !I18n.available_locales.include?(new_locale.to_sym)

    old_locale = params[:locale] || I18n.default_locale.to_s
    uri = URI::DEFAULT_PARSER.parse(request.fullpath)
    uri.path = new_locale == I18n.default_locale.to_s ? base_path(uri.path, old_locale) : "/#{new_locale}#{base_path(uri.path, old_locale)}"

    query = Rack::Utils.parse_nested_query(uri.query)
    query.delete('switch_locale')
    query.delete('locale')
    uri.query = query.blank? ? nil : query.to_param # NOTE: 存在しない場合も区切りの?が入る為
    return false if uri.to_s == request.fullpath # NOTE: 念の為、リダイレクトループしないようにしておく

    cookies[:locale] = new_locale # NOTE: パスにlocaleが含まれない場合、以前の言語になる為
    redirect_to uri.to_s
    true
  end

  def base_path(path, locale)
    "#{path}/"[0..(locale.length + 1)] == "/#{locale}/" ? path[(locale.length + 1)..] : path
  end
end
