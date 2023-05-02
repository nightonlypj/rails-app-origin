class TextHashValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    param = eval(value)
    if param.blank?
      # :nocov:
      record.errors.add(attribute, :blank)
      # :nocov:
    elsif !param.instance_of?(Hash)
      record.errors.add(attribute, :invalid)
    end
  rescue StandardError, SyntaxError
    record.errors.add(attribute, :invalid)
  end
end
