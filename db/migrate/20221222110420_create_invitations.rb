class CreateInvitations < ActiveRecord::Migration[6.1]
  def change
    create_table :invitations, comment: '招待' do |t|
      t.string :code, null: false, comment: 'コード'

      t.references :space, null: false, type: :bigint, foreign_key: true, comment: 'スペースID'
      t.text       :domains, comment: 'ドメイン'
      t.string     :email,   comment: 'メールアドレス'
      t.integer    :power, null: false, comment: '権限'
      t.string     :memo, comment: 'メモ'

      t.datetime :ended_at,   comment: '終了日時'
      t.datetime :deleted_at, comment: '削除日時'

      t.references :created_user, null: false, type: :bigint, foreign_key: false, comment: '作成者ID'
      t.references :last_updated_user,         type: :bigint, foreign_key: false, comment: '最終更新者ID'
      t.timestamps
    end
    add_index :invitations, :code, unique: true,          name: 'index_invitations1'
    add_index :invitations, :domains,                     name: 'index_invitations2'
    add_index :invitations, :email,                       name: 'index_invitations3'
    add_index :invitations, [:space_id, :power, :id],     name: 'index_invitations4'
    add_index :invitations, [:ended_at, :id],             name: 'index_invitations5'
    add_index :invitations, [:deleted_at, :id],           name: 'index_invitations6'
    add_index :invitations, [:created_user_id, :id],      name: 'index_invitations7'
    add_index :invitations, [:last_updated_user_id, :id], name: 'index_invitations8'
    add_index :invitations, [:created_at, :id],           name: 'index_invitations9'
    add_index :invitations, [:updated_at, :id],           name: 'index_invitations10'
  end
end
