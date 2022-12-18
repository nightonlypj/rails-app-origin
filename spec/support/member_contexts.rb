shared_context 'メンバー一覧作成' do |admin_count, writer_count, reader_count|
  let_it_be(:members) do
    now = Time.current
    invitationed_user = FactoryBot.create(:user)
    [FactoryBot.create(:member, power: user_power, space: space, user: user, created_at: now - 4.days, updated_at: now - 5.days)] +
      FactoryBot.create_list(:member, admin_count, :admin, space: space, invitationed_user: invitationed_user, created_at: now - 3.days,
                                                           updated_at: now - 2.days) +
      FactoryBot.create_list(:member, writer_count, :writer, space: space, invitationed_user: invitationed_user, created_at: now - 1.days,
                                                             updated_at: now - 1.days) +
      FactoryBot.create_list(:member, reader_count, :reader, space: space, invitationed_user: invitationed_user)
  end
end

# テスト内容（共通）
def expect_member_json(response_json_member, member, user_power)
  expect_user_json(response_json_member['user'], member.user, user_power == :admin)

  expect(response_json_member['power']).to eq(member.power)
  expect(response_json_member['power_i18n']).to eq(member.power_i18n)

  if user_power == :admin
    expect_user_json(response_json_member['invitationed_user'], member.invitationed_user, true)
    expect_user_json(response_json_member['last_updated_user'], member.last_updated_user, true)
  else
    expect(response_json_member['invitationed_user']).to be_nil
    expect(response_json_member['last_updated_user']).to be_nil
  end
  expect(response_json_member['invitationed_at']).to eq(I18n.l(member.invitationed_at, format: :json, default: nil))
  if user_power == :admin
    expect(response_json_member['last_updated_at']).to eq(I18n.l(member.last_updated_at, format: :json, default: nil))
  else
    expect(response_json_member['last_updated_at']).to be_nil
  end
end

shared_examples_for 'ToMembers(html/*)' do |alert, notice|
  it 'メンバー一覧にリダイレクトする' do
    is_expected.to redirect_to(members_path(space.code))
    expect(flash[:alert]).to alert.present? ? eq(I18n.t(alert)) : be_nil
    expect(flash[:notice]).to notice.present? ? eq(I18n.t(notice)) : be_nil
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
