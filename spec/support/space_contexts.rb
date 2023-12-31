shared_context 'スペース一覧作成' do |public_admin_count, public_none_count, private_admin_count, private_reader_count|
  before_all do
    @members = {}
    now = Time.current
    created_user = FactoryBot.create(:user)
    last_updated_user = FactoryBot.create(:user)
    destroy_user = FactoryBot.build_stubbed(:user)

    # 公開（権限が管理者）
    @public_spaces = FactoryBot.create_list(:space, public_admin_count, :public, description: '公開（管理者）', created_user:,
                                                                                 last_updated_user:, created_at: now - 5.days, updated_at: now - 4.days)
    @public_spaces.each do |space|
      FactoryBot.create(:member, :admin, space:, user:)
      @members[space.id] = 'admin'
    end

    # 公開（権限がない）
    @public_nojoin_spaces = FactoryBot.create_list(:space, public_none_count, :public, description: '公開（未参加）', created_user:,
                                                                                       last_updated_user: nil, created_at: now - 4.days, updated_at: now - 4.days)

    # 公開（削除予約済み、削除対象）
    @public_nojoin_destroy_spaces = [
      FactoryBot.create(:space, :public, :destroy_reserved, description: '公開（削除予約済み）', created_user:, created_at: now - 3.days, updated_at: now - 3.days),
      FactoryBot.create(:space, :public, :destroy_targeted, description: '公開（削除対象）', created_user:, created_at: now - 3.days, updated_at: now - 3.days)
    ]

    # 非公開（権限が管理者）
    @private_spaces = []
    if private_admin_count > 0
      spaces = FactoryBot.create_list(:space, private_admin_count, :private, description: '非公開（管理者）', created_user_id: destroy_user.id,
                                                                             last_updated_user_id: destroy_user.id, created_at: now - 2.days, updated_at: now - 1.day)
      spaces.each do |space|
        FactoryBot.create(:member, :admin, space:, user:)
        @members[space.id] = 'admin'
      end
      @private_spaces += spaces
    end

    # 非公開（権限が閲覧者）
    if private_reader_count > 0
      spaces = FactoryBot.create_list(:space, private_reader_count, :private, description: '非公開（閲覧者）', created_user:,
                                                                              last_updated_user: nil, created_at: now - 1.day, updated_at: now - 1.day)
      spaces.each do |space|
        FactoryBot.create(:member, :reader, space:, user:)
        @members[space.id] = 'reader'
      end
      @private_spaces += spaces
    end

    # 非公開（権限がない）
    @private_nojoin_spaces = [FactoryBot.create(:space, :private, description: '非公開（未参加）', created_user:,
                                                                  last_updated_user: nil, created_at: now, updated_at: now)]
  end
end

# テスト内容（共通）
def expect_space_html(response, space, user_power = :admin, use_link = true, image_version = :small)
  expect(response.body).to include(space.image_url(image_version))
  expect(response.body).to include("href=\"#{space_path(space.code)}\"") if use_link # スペーストップ
  expect(response.body).to include(space.name)
  expect(response.body).to include('非公開') if space.private
  expect(response.body).to include(I18n.l(space.destroy_schedule_at.to_date)) if space.destroy_reserved?
  expect(response.body).to include(Member.powers_i18n[user_power]) if user_power.present?
end

def expect_space_basic_json(response_json_space, space)
  result = 8
  expect(response_json_space['code']).to eq(space.code)
  expect_image_json(response_json_space, space)
  expect(response_json_space['name']).to eq(space.name)
  expect(response_json_space['description']).to eq(space.description)
  expect(response_json_space['private']).to eq(space.private)

  expect(response_json_space['destroy_requested_at']).to eq(I18n.l(space.destroy_requested_at, format: :json, default: nil))
  expect(response_json_space['destroy_schedule_at']).to eq(I18n.l(space.destroy_schedule_at, format: :json, default: nil))

  result
end

def expect_space_json(response_json_space, space, user_power, member_count)
  result = expect_space_basic_json(response_json_space, space) + 2

  ## メンバー数
  expect(response_json_space['member_count']).to eq(member_count)

  ## スペース削除の猶予期間
  expect(response_json_space['destroy_schedule_days']).to eq(Settings.space_destroy_schedule_days)

  data = response_json_space['current_member']
  if user_power.present?
    expect(data['power']).to eq(user_power.to_s)
    expect(data['power_i18n']).to eq(Member.powers_i18n[user_power])
    expect(data.count).to eq(2)
    result += 1
  else
    expect(data).to be_nil
  end

  data = response_json_space['created_user']
  if user_power == :admin && space.created_user_id.present?
    count = expect_user_json(data, space.created_user, { email: true })
    expect(data['deleted']).to eq(space.created_user.blank?)
    expect(data.count).to eq(count + 1)
    result += 1
  else
    expect(data).to be_nil
  end
  data = response_json_space['created_at']
  if user_power == :admin
    expect(data).to eq(I18n.l(space.created_at, format: :json))
    result += 1
  else
    expect(data).to be_nil
  end

  data = response_json_space['last_updated_user']
  if user_power == :admin && space.last_updated_user_id.present?
    count = expect_user_json(data, space.last_updated_user, { email: true })
    expect(data['deleted']).to eq(space.last_updated_user.blank?)
    expect(data.count).to eq(count + 1)
    result += 1
  else
    expect(data).to be_nil
  end
  data = response_json_space['last_updated_at']
  if user_power == :admin
    expect(data).to eq(I18n.l(space.last_updated_at, format: :json, default: nil))
    result += 1
  else
    expect(data).to be_nil
  end

  result
end

shared_examples_for 'ToSpaces(html/*)' do |alert, notice|
  it 'スペース一覧にリダイレクトする' do
    is_expected.to redirect_to(spaces_path)
    expect(flash[:alert]).to alert.present? ? eq(get_locale(alert)) : be_nil
    expect(flash[:notice]).to notice.present? ? eq(get_locale(notice)) : be_nil
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
    expect(flash[:alert]).to alert.present? ? eq(get_locale(alert)) : be_nil
    expect(flash[:notice]).to notice.present? ? eq(get_locale(notice)) : be_nil
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
