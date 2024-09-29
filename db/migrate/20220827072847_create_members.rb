class CreateMembers < ActiveRecord::Migration[6.1]
  def change
    create_table :members, comment: 'メンバー' do |t|
      t.references :space, null: false, type: :bigint, foreign_key: true, comment: 'スペースID'
      t.references :user,  null: false, type: :bigint, foreign_key: true, comment: 'ユーザーID'

      t.integer :power, null: false, comment: '権限'

      t.references :invitationed_user, type: :bigint, foreign_key: false, comment: '招待者ID'
      t.references :last_updated_user, type: :bigint, foreign_key: false, comment: '最終更新者ID'

      t.datetime :invitationed_at, comment: '招待日時'
      t.timestamps
    end
    add_index :members, %i[space_id user_id], unique: true, name: 'index_members1'
    add_index :members, %i[space_id power id],              name: 'index_members2'
    add_index :members, %i[invitationed_user_id id],        name: 'index_members3'
    add_index :members, %i[last_updated_user_id id],        name: 'index_members4'
    add_index :members, %i[invitationed_at id],             name: 'index_members5'
    add_index :members, %i[created_at id],                  name: 'index_members6'
    add_index :members, %i[updated_at id],                  name: 'index_members7'
  end
end
