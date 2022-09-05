shared_context 'スペース一覧作成' do |public_admin_count, public_none_count, private_admin_count, private_reader_count|
  before_all do
    @members = {}

    # 公開（管理者）＋削除予約済み
    @all_spaces = FactoryBot.create_list(:space, public_admin_count, :public, :destroy_reserved)
    @all_spaces.each do |space|
      FactoryBot.create(:member, :admin, space_id: space.id, user_id: user.id)
      @members[space.id] = 'Admin'
    end

    # 公開（未参加）
    @all_spaces += FactoryBot.create_list(:space, public_none_count, :public) if public_none_count.positive?

    # 非公開（管理者）＋削除対象
    @user_spaces = @all_spaces
    if private_admin_count.positive?
      spaces = FactoryBot.create_list(:space, private_admin_count, :private, :destroy_targeted)
      spaces.each do |space|
        FactoryBot.create(:member, :admin, space_id: space.id, user_id: user.id)
        @members[space.id] = 'Admin'
      end
      @user_spaces += spaces
    end

    # 非公開（閲覧者）
    if private_reader_count.positive?
      spaces = FactoryBot.create_list(:space, private_reader_count, :private)
      spaces.each do |space|
        FactoryBot.create(:member, :reader, space_id: space.id, user_id: user.id)
        @members[space.id] = 'Reader'
      end
      @user_spaces += spaces
    end

    # 非公開（未参加）
    FactoryBot.create(:space, :private)
  end
end
