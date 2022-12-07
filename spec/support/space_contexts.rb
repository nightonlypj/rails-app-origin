shared_context 'スペース一覧作成' do |public_admin_count, public_none_count, private_admin_count, private_reader_count|
  before_all do
    @members = {}
    create_user = FactoryBot.create(:user)

    # 公開（管理者）
    @public_spaces = FactoryBot.create_list(:space, public_admin_count, :public, create_user: create_user, description: '公開（管理者）')
    @public_spaces.each do |space|
      FactoryBot.create(:member, :admin, space: space, user: user)
      @members[space.id] = 'admin'
    end

    # 公開（未参加）
    @public_nojoin_spaces = FactoryBot.create_list(:space, public_none_count, :public, create_user: create_user, description: '公開（未参加）')

    # 公開（削除予約済み、削除対象）
    @public_nojoin_destroy_spaces = [
      FactoryBot.create(:space, :public, :destroy_reserved, create_user: create_user, description: '公開（削除予約済み）'),
      FactoryBot.create(:space, :public, :destroy_targeted, create_user: create_user, description: '公開（削除対象）')
    ]

    # 非公開（管理者）
    @private_spaces = []
    if private_admin_count.positive?
      spaces = FactoryBot.create_list(:space, private_admin_count, :private, create_user: create_user, description: '非公開（管理者）')
      spaces.each do |space|
        FactoryBot.create(:member, :admin, space: space, user: user)
        @members[space.id] = 'admin'
      end
      @private_spaces += spaces
    end

    # 非公開（閲覧者）
    if private_reader_count.positive?
      spaces = FactoryBot.create_list(:space, private_reader_count, :private, create_user: create_user, description: '非公開（閲覧者）')
      spaces.each do |space|
        FactoryBot.create(:member, :reader, space: space, user: user)
        @members[space.id] = 'reader'
      end
      @private_spaces += spaces
    end

    # 非公開（未参加）
    @private_nojoin_spaces = [FactoryBot.create(:space, :private, create_user: create_user, description: '非公開（未参加）')]
  end
end
