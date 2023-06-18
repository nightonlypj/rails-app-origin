shared_context 'お知らせ一覧作成' do |all_forever_count, all_future_count, user_forever_count, user_future_count|
  before_all do
    # 全員（現在/未来〜なし）＋概要がない
    @all_infomations = FactoryBot.create_list(:infomation, all_forever_count, :forever, summary: nil)
    FactoryBot.create(:infomation, :reserve_forever, summary: nil)
    # 全員（現在/未来〜未来）＋概要・本文がない
    @all_infomations += FactoryBot.create_list(:infomation, all_future_count, summary: nil, body: nil)
    FactoryBot.create(:infomation, :reserve, summary: nil, body: nil)
    # 全員（過去〜過去）
    FactoryBot.create(:infomation, :finished)

    # 対象ユーザー（現在/未来〜なし）＋本文がない
    @user_infomations = @all_infomations
    if user_forever_count > 0
      @user_infomations += FactoryBot.create_list(:infomation, user_forever_count, :forever, :user, user: user, body: nil)
      FactoryBot.create(:infomation, :reserve_forever, :user, user: user, body: nil)
    end
    # 対象ユーザー（現在/未来〜未来）
    if user_future_count > 0
      @user_infomations += FactoryBot.create_list(:infomation, user_future_count, :user, user: user)
      FactoryBot.create(:infomation, :reserve, :user, user: user)
    end
    # 対象ユーザー（過去〜過去）
    FactoryBot.create(:infomation, :finished, :user, user: user) if (user_forever_count + user_future_count) > 0

    # 対象外ユーザー（現在/未来〜なし）
    other_user = FactoryBot.create(:user)
    FactoryBot.create(:infomation, :forever, :user, user: other_user)
    FactoryBot.create(:infomation, :reserve_forever, :user, user: other_user)
    # 対象外ユーザー（現在/未来〜未来）
    FactoryBot.create(:infomation, :user, user: other_user)
    FactoryBot.create(:infomation, :reserve, :user, user: other_user)
    # 対象外ユーザー（過去〜過去）
    FactoryBot.create(:infomation, :finished, :user, user: other_user)
  end
end

shared_context '大切なお知らせ一覧作成' do |all_forever_count, all_future_count, user_forever_count, user_future_count|
  before_all do
    # 全員（現在/未来〜なし）＋概要なし
    @all_important_infomations = FactoryBot.create_list(:infomation, all_forever_count, :important, :force_forever, summary: nil)
    FactoryBot.create(:infomation, :important, :force_reserve_forever, summary: nil)
    # 全員（現在/未来〜未来）＋概要・本文なし
    @all_important_infomations += FactoryBot.create_list(:infomation, all_future_count, :important, summary: nil, body: nil)
    FactoryBot.create(:infomation, :important, :force_reserve, summary: nil, body: nil)
    # 全員（過去〜過去）
    FactoryBot.create(:infomation, :important, :force_finished)

    # 対象ユーザー（現在/未来〜なし）＋本文なし
    @user_important_infomations = @all_important_infomations
    if user_forever_count > 0
      @user_important_infomations += FactoryBot.create_list(:infomation, user_forever_count, :important, :force_forever, :user, user: user, body: nil)
      FactoryBot.create(:infomation, :important, :force_reserve_forever, :user, user: user, body: nil)
    end
    # 対象ユーザー（現在/未来〜未来）
    if user_future_count > 0
      @user_important_infomations += FactoryBot.create_list(:infomation, user_future_count, :important, :user, user: user)
      FactoryBot.create(:infomation, :important, :force_reserve, :user, user: user)
    end
    # 対象ユーザー（過去〜過去）
    FactoryBot.create(:infomation, :important, :force_finished, :user, user: user) if (user_forever_count + user_future_count) > 0

    # 対象外ユーザー（現在/未来〜なし）
    other_user = FactoryBot.create(:user)
    FactoryBot.create(:infomation, :important, :force_forever, :user, user: other_user)
    FactoryBot.create(:infomation, :important, :force_reserve_forever, :user, user: other_user)
    # 対象外ユーザー（現在/未来〜未来）
    FactoryBot.create(:infomation, :important, :user, user: other_user)
    FactoryBot.create(:infomation, :important, :force_reserve, :user, user: other_user)
    # 対象外ユーザー（過去〜過去）
    FactoryBot.create(:infomation, :important, :force_finished, :user, user: other_user)
  end
end

# テスト内容（共通）
def expect_infomation_json(response_json_infomation, infomation, use = { id: false, body: false })
  result = 8
  if use[:id]
    expect(response_json_infomation['id']).to eq(infomation.id)
    result += 1
  else
    expect(response_json_infomation['id']).to be_nil
  end
  expect(response_json_infomation['label']).to eq(infomation.label)
  expect(response_json_infomation['label_i18n']).to eq(infomation.label_i18n)
  expect(response_json_infomation['title']).to eq(infomation.title)
  expect(response_json_infomation['summary']).to eq(infomation.summary)
  if use[:body]
    expect(response_json_infomation['body']).to eq(infomation.body)
    expect(response_json_infomation['body_present']).to be_nil
  else
    expect(response_json_infomation['body']).to be_nil
    expect(response_json_infomation['body_present']).to eq(infomation.body.present?)
  end
  expect(response_json_infomation['started_at']).to eq(I18n.l(infomation.started_at, format: :json))
  expect(response_json_infomation['ended_at']).to eq(I18n.l(infomation.ended_at, format: :json, default: nil))
  expect(response_json_infomation['target']).to eq(infomation.target)

  result
end
