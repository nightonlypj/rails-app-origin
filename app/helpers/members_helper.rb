module MembersHelper
  # 権限のクラス名を返却
  def power_class_name(power)
    case power&.to_sym
    when :Admin
      'fa-user-cog'
    when :Writer
      'fa-user-edit'
    else
      'fa-user'
    end
  end
end
