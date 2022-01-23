class AddInfomationCheckToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :infomation_check_last_started_at, :datetime, comment: 'お知らせ確認最終開始日時'
  end
end
