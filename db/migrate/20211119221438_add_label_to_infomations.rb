class AddLabelToInfomations < ActiveRecord::Migration[6.1]
  def change
    add_column :infomations, :label, :integer, null: false, default: 0, comment: 'ラベル'

    add_column :infomations, :force_started_at, :datetime, comment: '強制表示開始日時'
    add_column :infomations, :force_ended_at,   :datetime, comment: '強制表示終了日時'

    add_index :infomations, %i[force_started_at force_ended_at], name: 'index_infomations4'
  end
end
