class CreateMembers < ActiveRecord::Migration[6.1]
  def change
    create_table :members, comment: 'メンバー' do |t|
      t.references :space, type: :bigint, foreign_key: true, comment: 'スペースID'
      t.references :user,  type: :bigint, foreign_key: true, comment: 'ユーザーID'

      t.integer  :power, null: false, comment: '権限'

      t.references :invitation_user, type: :bigint, foreign_key: false, comment: '招待ユーザーID'
      t.datetime   :invitationed_at, comment: '招待日時'

      t.timestamps
    end
    add_index :members, [:space_id, :user_id], unique: true, name: 'index_members1'
    add_index :members, [:created_at, :id],                  name: 'index_members2'
  end
end
