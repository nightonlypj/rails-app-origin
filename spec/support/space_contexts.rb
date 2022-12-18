shared_context 'スペース一覧作成' do |public_admin_count, public_none_count, private_admin_count, private_reader_count|
  before_all do
    @members = {}
    created_user = FactoryBot.create(:user)

    # 公開（管理者）
    @public_spaces = FactoryBot.create_list(:space, public_admin_count, :public, created_user: created_user, description: '公開（管理者）')
    @public_spaces.each do |space|
      FactoryBot.create(:member, :admin, space: space, user: user)
      @members[space.id] = 'admin'
    end

    # 公開（未参加）
    @public_nojoin_spaces = FactoryBot.create_list(:space, public_none_count, :public, created_user: created_user, description: '公開（未参加）')

    # 公開（削除予約済み、削除対象）
    @public_nojoin_destroy_spaces = [
      FactoryBot.create(:space, :public, :destroy_reserved, created_user: created_user, description: '公開（削除予約済み）'),
      FactoryBot.create(:space, :public, :destroy_targeted, created_user: created_user, description: '公開（削除対象）')
    ]

    # 非公開（管理者）
    @private_spaces = []
    if private_admin_count.positive?
      spaces = FactoryBot.create_list(:space, private_admin_count, :private, created_user: created_user, description: '非公開（管理者）')
      spaces.each do |space|
        FactoryBot.create(:member, :admin, space: space, user: user)
        @members[space.id] = 'admin'
      end
      @private_spaces += spaces
    end

    # 非公開（閲覧者）
    if private_reader_count.positive?
      spaces = FactoryBot.create_list(:space, private_reader_count, :private, created_user: created_user, description: '非公開（閲覧者）')
      spaces.each do |space|
        FactoryBot.create(:member, :reader, space: space, user: user)
        @members[space.id] = 'reader'
      end
      @private_spaces += spaces
    end

    # 非公開（未参加）
    @private_nojoin_spaces = [FactoryBot.create(:space, :private, created_user: created_user, description: '非公開（未参加）')]
  end
end

# テスト内容（共通）
def expect_space_json(response_json_space, space, user_power)
  expect(response_json_space['code']).to eq(space.code)
  expect_image_json(response_json_space, space)
  expect(response_json_space['name']).to eq(space.name)
  expect(response_json_space['description']).to eq(space.description)
  expect(response_json_space['private']).to eq(space.private)
  expect(response_json_space['destroy_requested_at']).to eq(I18n.l(space.destroy_requested_at, format: :json, default: nil))
  expect(response_json_space['destroy_schedule_at']).to eq(I18n.l(space.destroy_schedule_at, format: :json, default: nil))
  expect(response_json_space['member_count']).to eq(member_count) # メンバー数

  if user_power.present?
    expect(response_json_space['current_member']['power']).to eq(user_power.to_s)
    expect(response_json_space['current_member']['power_i18n']).to eq(Member.powers_i18n[user_power])
  else
    expect(response_json_space['current_member']).to be_nil
  end

  if user_power == :admin
    if space.created_user.present?
      expect_user_json(response_json_space['created_user'], space.created_user, true)
    else
      expect(response_json_space['created_user']).to be_nil
    end
    if space.last_updated_user.present?
      expect_user_json(response_json_space['last_updated_user'], space.last_updated_user, true)
    else
      expect(response_json_space['last_updated_user']).to be_nil
    end
    expect(response_json_space['created_at']).to eq(I18n.l(space.created_at, format: :json))
    expect(response_json_space['last_updated_at']).to eq(I18n.l(space.last_updated_at, format: :json, default: nil))
  else
    expect(response_json_space['created_user']).to be_nil
    expect(response_json_space['last_updated_user']).to be_nil
    expect(response_json_space['created_at']).to be_nil
    expect(response_json_space['last_updated_at']).to be_nil
  end
end

shared_examples_for 'ToSpaces(html/*)' do |alert, notice|
  it 'スペース一覧にリダイレクトする' do
    is_expected.to redirect_to(spaces_path)
    expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
    expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
  end
end
shared_examples_for 'ToSpaces(html/html)' do |alert, notice|
  let(:subject_format) { nil }
  let(:accept_headers) { ACCEPT_INC_HTML }
  it_behaves_like 'ToSpaces(html/*)', alert, notice
end
shared_examples_for 'ToSpaces(html/json)' do |alert, notice|
  let(:subject_format) { nil }
  let(:accept_headers) { ACCEPT_INC_JSON }
  it_behaves_like 'ToSpaces(html/*)', alert, notice
end
shared_examples_for 'ToSpaces(html)' do |alert = nil, notice = nil|
  it_behaves_like 'ToSpaces(html/html)', alert, notice
  it_behaves_like 'ToSpaces(html/json)', alert, notice
end
