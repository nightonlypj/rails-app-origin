class CreateMembers < ActiveRecord::Migration[6.1]
  def change
    create_table :members, comment: 'メンバー' do |t|
      t.references :space, null: false, type: :bigint, foreign_key: true, comment: 'スペースID'
      t.references :user,  null: false, type: :bigint, foreign_key: true, comment: 'ユーザーID'

      t.integer :power, null: false, comment: '権限'

      t.references :invitation_user, type: :bigint, foreign_key: false, comment: '招待ユーザーID'
      t.datetime   :invitationed_at, comment: '招待日時'

      t.timestamps
    end
    add_index :members, [:space_id, :user_id], unique: true, name: 'index_members1'
    add_index :members, [:invitationed_at, :id],             name: 'index_members2'
    add_index :members, [:space_id, :power],                 name: 'index_members3'
  end
end
