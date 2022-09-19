module InfomationsHelper
  # ラベルのクラス名を返却
  def label_class_name(label)
    case label.to_sym
    when :maintenance
      'bg-danger'
    when :hindrance
      'bg-warning'
    else
      'bg-info'
    end
  end
end
