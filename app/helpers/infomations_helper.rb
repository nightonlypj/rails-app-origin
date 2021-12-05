module InfomationsHelper
  # ラベルのクラス名を返却
  def label_class_name(label)
    case label.to_sym
    when :Maintenance
      'bg-danger'
    when :Hindrance
      'bg-warning'
    else
      'bg-info'
    end
  end
end
