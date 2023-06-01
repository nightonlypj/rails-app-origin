shared_context 'メンバー一覧作成' do |admin_count, writer_count, reader_count|
  let_it_be(:members) do
    now = Time.current
    invitationed_user = FactoryBot.create(:user)
    last_updated_user = FactoryBot.create(:user)
    destroy_user = FactoryBot.build_stubbed(:user)
    [FactoryBot.create(:member, power: user_power, space: space, user: user,
                                last_updated_user: last_updated_user, created_at: now - 4.days, updated_at: now - 5.days)] +
      FactoryBot.create_list(:member, admin_count, :admin, space: space, invitationed_user_id: destroy_user.id,
                                                           last_updated_user_id: destroy_user.id, created_at: now - 3.days, updated_at: now - 2.days) +
      FactoryBot.create_list(:member, writer_count, :writer, space: space, invitationed_user: invitationed_user,
                                                             created_at: now - 1.days, updated_at: now - 1.days) +
      FactoryBot.create_list(:member, reader_count, :reader, space: space, invitationed_user: invitationed_user,
                                                             created_at: now, updated_at: now)
  end
  before_all { FactoryBot.create(:member, :admin, user: user) } # NOTE: 対象外
end

shared_context 'set_member_power' do |power|
  let(:user_power) { power }
  let_it_be(:member_myself) { FactoryBot.create(:member, power, space: space, user: user) if power.present? && user.present? }
end

# テスト内容（共通）
def expect_member_json(response_json_member, member, user_power)
  result = 4

  data = response_json_member['user']
  count = expect_user_json(data, member.user, { email: user_power == :admin })
  expect(data.count).to eq(count)

  expect(response_json_member['power']).to eq(member.power)
  expect(response_json_member['power_i18n']).to eq(member.power_i18n)

  data = response_json_member['invitationed_user']
  if user_power == :admin && member.invitationed_user_id.present?
    count = expect_user_json(data, member.invitationed_user, { email: true })
    expect(data['deleted']).to eq(member.invitationed_user.blank?)
    expect(data.count).to eq(count + 1)
    result += 1
  else
    expect(data).to be_nil
  end
  expect(response_json_member['invitationed_at']).to eq(I18n.l(member.invitationed_at, format: :json, default: nil))

  data = response_json_member['last_updated_user']
  if user_power == :admin && member.last_updated_user_id.present?
    count = expect_user_json(data, member.last_updated_user, { email: true })
    expect(data['deleted']).to eq(member.last_updated_user.blank?)
    expect(data.count).to eq(count + 1)
    result += 1
  else
    expect(data).to be_nil
  end
  data = response_json_member['last_updated_at']
  if user_power == :admin
    expect(data).to eq(I18n.l(member.last_updated_at, format: :json, default: nil))
    result += 1
  else
    expect(data).to be_nil
  end

  result
end

shared_examples_for 'ToMembers(html/*)' do |alert, notice|
  it 'メンバー一覧にリダイレクトする' do
    is_expected.to redirect_to(members_path(space.code))
    expect(flash[:alert]).to alert.present? ? eq(get_locale(alert)) : be_nil
    expect(flash[:notice]).to notice.present? ? eq(get_locale(notice)) : be_nil
  end
end
shared_examples_for 'ToMembers(html/html)' do |alert, notice|
  let(:subject_format) { nil }
  let(:accept_headers) { ACCEPT_INC_HTML }
  it_behaves_like 'ToMembers(html/*)', alert, notice
end
shared_examples_for 'ToMembers(html/json)' do |alert, notice|
  let(:subject_format) { nil }
  let(:accept_headers) { ACCEPT_INC_JSON }
  it_behaves_like 'ToMembers(html/*)', alert, notice
end
shared_examples_for 'ToMembers(html)' do |alert = nil, notice = nil|
  it_behaves_like 'ToMembers(html/html)', alert, notice
  it_behaves_like 'ToMembers(html/json)', alert, notice
end
