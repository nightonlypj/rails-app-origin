shared_context 'スペース一覧作成' do |public_admin_count, public_none_count, private_admin_count, private_reader_count|
  before_all do
    @members = {}
    now = Time.current
    created_user = FactoryBot.create(:user)
    last_updated_user = FactoryBot.create(:user)
    destroy_user = FactoryBot.build_stubbed(:user)

    # 公開（管理者）
    @public_spaces = FactoryBot.create_list(:space, public_admin_count, :public, description: '公開（管理者）', created_user: created_user,
                                                                                 last_updated_user: last_updated_user, created_at: now - 5.days, updated_at: now - 4.days)
    @public_spaces.each do |space|
      FactoryBot.create(:member, :admin, space: space, user: user)
      @members[space.id] = 'admin'
    end

    # 公開（未参加）
    @public_nojoin_spaces = FactoryBot.create_list(:space, public_none_count, :public, description: '公開（未参加）', created_user: created_user,
                                                                                       created_at: now - 4.days, updated_at: now - 4.days)

    # 公開（削除予約済み、削除対象）
    @public_nojoin_destroy_spaces = [
      FactoryBot.create(:space, :public, :destroy_reserved, description: '公開（削除予約済み）', created_user: created_user, created_at: now - 3.days, updated_at: now - 3.days),
      FactoryBot.create(:space, :public, :destroy_targeted, description: '公開（削除対象）', created_user: created_user, created_at: now - 3.days, updated_at: now - 3.days)
    ]

    # 非公開（管理者）
    @private_spaces = []
    if private_admin_count.positive?
      spaces = FactoryBot.create_list(:space, private_admin_count, :private, description: '非公開（管理者）', created_user_id: destroy_user.id,
                                                                             last_updated_user_id: destroy_user.id, created_at: now - 2.days, updated_at: now - 1.days)
      spaces.each do |space|
        FactoryBot.create(:member, :admin, space: space, user: user)
        @members[space.id] = 'admin'
      end
      @private_spaces += spaces
    end

    # 非公開（閲覧者）
    if private_reader_count.positive?
      spaces = FactoryBot.create_list(:space, private_reader_count, :private, description: '非公開（閲覧者）', created_user: created_user,
                                                                              created_at: now - 1.days, updated_at: now - 1.days)
      spaces.each do |space|
        FactoryBot.create(:member, :reader, space: space, user: user)
        @members[space.id] = 'reader'
      end
      @private_spaces += spaces
    end

    # 非公開（未参加）
    @private_nojoin_spaces = [FactoryBot.create(:space, :private, description: '非公開（未参加）', created_user: created_user,
                                                                  created_at: now, updated_at: now)]
  end
end

# テスト内容（共通）
def expect_space_json(response_json_space, space, user_power)
  expect(response_json_space['code']).to eq(space.code)
  expect_image_json(response_json_space, space)
  expect(response_json_space['name']).to eq(space.name)
  expect(response_json_space['description']).to eq(space.description)
  expect(response_json_space['private']).to eq(space.private)

  ## 削除予約
  expect(response_json_space['destroy_requested_at']).to eq(I18n.l(space.destroy_requested_at, format: :json, default: nil))
  expect(response_json_space['destroy_schedule_at']).to eq(I18n.l(space.destroy_schedule_at, format: :json, default: nil))

  ## メンバー数
  expect(response_json_space['member_count']).to eq(member_count)

  ## スペース削除の猶予期間
  expect(response_json_space['destroy_schedule_days']).to eq(Settings['space_destroy_schedule_days'])

  if user_power.present?
    expect(response_json_space['current_member']['power']).to eq(user_power.to_s)
    expect(response_json_space['current_member']['power_i18n']).to eq(Member.powers_i18n[user_power])
  else
    expect(response_json_space['current_member']).to be_nil
  end

  if user_power == :admin
    expect_user_json(response_json_space['created_user'], space.created_user, true, space.created_user_id.present?)
    expect_user_json(response_json_space['last_updated_user'], space.last_updated_user, true, space.last_updated_user_id.present?)
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

shared_examples_for 'ToSpace(html/*)' do |alert, notice|
  it 'スペーストップにリダイレクトする' do
    is_expected.to redirect_to(space_path(space.code))
    expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
    expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
  end
end
shared_examples_for 'ToSpace(html/html)' do |alert, notice|
  let(:subject_format) { nil }
  let(:accept_headers) { ACCEPT_INC_HTML }
  it_behaves_like 'ToSpace(html/*)', alert, notice
end
shared_examples_for 'ToSpace(html/json)' do |alert, notice|
  let(:subject_format) { nil }
  let(:accept_headers) { ACCEPT_INC_JSON }
  it_behaves_like 'ToSpace(html/*)', alert, notice
end
shared_examples_for 'ToSpace(html)' do |alert = nil, notice = nil|
  it_behaves_like 'ToSpace(html/html)', alert, notice
  it_behaves_like 'ToSpace(html/json)', alert, notice
end
