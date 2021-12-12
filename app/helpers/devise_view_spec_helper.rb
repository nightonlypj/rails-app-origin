module DeviseViewSpecHelper
  # Gets the actual resource stored in the instance variable
  def resource
    # instance_variable_get(:"@#{resource_name}")
    @resource
  end

  # Attempt to find the mapped route for devise based on request path
  def devise_mapping
    # @devise_mapping ||= request.env["devise.mapping"]
    Devise.mappings[resource.class.name.underscore.to_sym]
  end

  # Proxy to devise map name
  def resource_name
    devise_mapping.name
  end

  # Proxy to devise map class
  def resource_class
    devise_mapping.to
  end
end
