shared_context '招待URL一覧作成' do |active_count, expired_count, deleted_count, email_joined_count|
  let_it_be(:invitations) do
    now = Time.current
    created_user = FactoryBot.create(:user)
    last_updated_user = FactoryBot.create(:user)
    destroy_user = FactoryBot.build_stubbed(:user)

    other_member = FactoryBot.create(:member, :admin, user:)
    FactoryBot.create(:invitation, :active, space: other_member.space, created_user:, last_updated_user: nil) # NOTE: 対象外

    FactoryBot.create_list(:invitation, active_count, :active, space:, created_user_id: destroy_user.id,
                                                               last_updated_user:, created_at: now - 4.days, updated_at: now - 5.days) +
      FactoryBot.create_list(:invitation, expired_count, :expired, space:, created_user:,
                                                                   last_updated_user_id: destroy_user.id, created_at: now - 3.days, updated_at: now - 2.days) +
      FactoryBot.create_list(:invitation, deleted_count, :deleted, space:, created_user:,
                                                                   last_updated_user: nil, created_at: now - 1.day, updated_at: now - 1.day) +
      FactoryBot.create_list(:invitation, email_joined_count, :email_joined, space:, created_user:,
                                                                             last_updated_user: nil, created_at: now, updated_at: now)
  end
end

# テスト内容（共通）
def expect_invitation_json(response_json_invitation, invitation)
  result = 13
  expect(response_json_invitation['status']).to eq(invitation.status.to_s)
  expect(response_json_invitation['status_i18n']).to eq(invitation.status_i18n)

  expect(response_json_invitation['code']).to eq(invitation.code)
  if invitation.email.present?
    expect(response_json_invitation['email']).to eq(invitation.email)
    expect(response_json_invitation['domains']).to be_nil
  else
    expect(response_json_invitation['email']).to be_nil
    expect(response_json_invitation['domains']).to eq(invitation.domains_array)
  end
  expect(response_json_invitation['power']).to eq(invitation.power)
  expect(response_json_invitation['power_i18n']).to eq(Invitation.powers_i18n[invitation.power])
  expect(response_json_invitation['memo']).to eq(invitation.memo)

  expect(response_json_invitation['ended_at']).to eq(I18n.l(invitation.ended_at, format: :json, default: nil))
  expect(response_json_invitation['destroy_requested_at']).to eq(I18n.l(invitation.destroy_requested_at, format: :json, default: nil))
  expect(response_json_invitation['destroy_schedule_at']).to eq(I18n.l(invitation.destroy_schedule_at, format: :json, default: nil))
  if invitation.email.present?
    expect(response_json_invitation['email_joined_at']).to eq(I18n.l(invitation.email_joined_at, format: :json, default: nil))
    result += 1
  else
    expect(response_json_invitation['email_joined_at']).to be_nil
  end

  data = response_json_invitation['created_user']
  count = expect_user_json(data, invitation.created_user, { email: true })
  expect(data['deleted']).to eq(invitation.created_user.blank?)
  expect(data.count).to eq(count + 1)

  expect(response_json_invitation['created_at']).to eq(I18n.l(invitation.created_at, format: :json))

  data = response_json_invitation['last_updated_user']
  if invitation.last_updated_user_id.present?
    count = expect_user_json(data, invitation.last_updated_user, { email: true })
    expect(data['deleted']).to eq(invitation.last_updated_user.blank?)
    expect(data.count).to eq(count + 1)
    result += 1
  else
    expect(data).to be_nil
  end
  expect(response_json_invitation['last_updated_at']).to eq(I18n.l(invitation.last_updated_at, format: :json, default: nil))

  result
end

shared_examples_for 'ToInvitations(html/*)' do |alert, notice|
  it '招待URL一覧にリダイレクトする' do
    is_expected.to redirect_to(invitations_path(space_code: space.code))
    expect(flash[:alert]).to alert.present? ? eq(get_locale(alert)) : be_nil
    expect(flash[:notice]).to notice.present? ? eq(get_locale(notice)) : be_nil
  end
end
shared_examples_for 'ToInvitations(html/html)' do |alert, notice|
  let(:subject_format) { nil }
  let(:accept_headers) { ACCEPT_INC_HTML }
  it_behaves_like 'ToInvitations(html/*)', alert, notice
end
shared_examples_for 'ToInvitations(html/json)' do |alert, notice|
  let(:subject_format) { nil }
  let(:accept_headers) { ACCEPT_INC_JSON }
  it_behaves_like 'ToInvitations(html/*)', alert, notice
end
shared_examples_for 'ToInvitations(html)' do |alert = nil, notice = nil|
  it_behaves_like 'ToInvitations(html/html)', alert, notice
  it_behaves_like 'ToInvitations(html/json)', alert, notice
end
