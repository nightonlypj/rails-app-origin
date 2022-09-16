module MembersHelper
  # 権限のクラス名を返却
  def power_class_name(power)
    case power&.to_sym
    when :admin
      'fa-user-cog'
    when :writer
      'fa-user-edit'
    else
      'fa-user'
    end
  end
end
