shared_context 'お知らせ一覧作成' do |all_forever_count, all_future_count, user_forever_count, user_future_count|
  before do
    # 全員（現在/未来〜なし）＋概要なし
    @all_infomations = FactoryBot.create_list(:infomation_forever, all_forever_count, summary: nil)
    FactoryBot.create(:infomation_reserve_forever, summary: nil)
    # 全員（現在/未来〜未来）＋概要・本文なし
    @all_infomations += FactoryBot.create_list(:infomation, all_future_count, summary: nil, body: nil)
    FactoryBot.create(:infomation_reserve, summary: nil, body: nil)
    # 全員（過去〜過去）
    FactoryBot.create(:infomation_finished)

    # 対象ユーザー（現在/未来〜なし）＋本文なし
    @user_infomations = @all_infomations
    if user_forever_count.positive?
      @user_infomations += FactoryBot.create_list(:infomation_forever, user_forever_count, target: :User, user_id: user.id, body: nil)
      FactoryBot.create(:infomation_reserve_forever, target: :User, user_id: user.id, body: nil)
    end
    # 対象ユーザー（現在/未来〜未来）
    if user_future_count.positive?
      @user_infomations += FactoryBot.create_list(:infomation, user_future_count, target: :User, user_id: user.id)
      FactoryBot.create(:infomation_reserve, target: :User, user_id: user.id)
    end
    # 対象ユーザー（過去〜過去）
    FactoryBot.create(:infomation_finished, target: :User, user_id: user.id) if (user_forever_count + user_future_count).positive?

    # 対象外ユーザー（現在/未来〜なし）
    outside_user = FactoryBot.create(:user)
    FactoryBot.create(:infomation_forever, target: :User, user_id: outside_user.id)
    FactoryBot.create(:infomation_reserve_forever, target: :User, user_id: outside_user.id)
    # 対象外ユーザー（現在/未来〜未来）
    FactoryBot.create(:infomation, target: :User, user_id: outside_user.id)
    FactoryBot.create(:infomation_reserve, target: :User, user_id: outside_user.id)
    # 対象外ユーザー（過去〜過去）
    FactoryBot.create(:infomation_finished, target: :User, user_id: outside_user.id)
  end
end

shared_context '大切なお知らせ一覧作成' do |all_forever_count, all_future_count, user_forever_count, user_future_count|
  before do
    # 全員（現在/未来〜なし）＋概要なし
    @all_important_infomations = FactoryBot.create_list(:infomation_important_forever, all_forever_count, summary: nil)
    FactoryBot.create(:infomation_important_reserve_forever, summary: nil)
    # 全員（現在/未来〜未来）＋概要・本文なし
    @all_important_infomations += FactoryBot.create_list(:infomation_important, all_future_count, summary: nil, body: nil)
    FactoryBot.create(:infomation_important_reserve, summary: nil, body: nil)
    # 全員（過去〜過去）
    FactoryBot.create(:infomation_important_finished)

    # 対象ユーザー（現在/未来〜なし）＋本文なし
    @user_important_infomations = @all_important_infomations
    if user_forever_count.positive?
      @user_important_infomations += FactoryBot.create_list(:infomation_important_forever, user_forever_count, target: :User, user_id: user.id, body: nil)
      FactoryBot.create(:infomation_important_reserve_forever, target: :User, user_id: user.id, body: nil)
    end
    # 対象ユーザー（現在/未来〜未来）
    if user_future_count.positive?
      @user_important_infomations += FactoryBot.create_list(:infomation_important, user_future_count, target: :User, user_id: user.id)
      FactoryBot.create(:infomation_important_reserve, target: :User, user_id: user.id)
    end
    # 対象ユーザー（過去〜過去）
    FactoryBot.create(:infomation_important_finished, target: :User, user_id: user.id) if (user_forever_count + user_future_count).positive?

    # 対象外ユーザー（現在/未来〜なし）
    outside_user = FactoryBot.create(:user)
    FactoryBot.create(:infomation_important_forever, target: :User, user_id: outside_user.id)
    FactoryBot.create(:infomation_important_reserve_forever, target: :User, user_id: outside_user.id)
    # 対象外ユーザー（現在/未来〜未来）
    FactoryBot.create(:infomation_important, target: :User, user_id: outside_user.id)
    FactoryBot.create(:infomation_important_reserve, target: :User, user_id: outside_user.id)
    # 対象外ユーザー（過去〜過去）
    FactoryBot.create(:infomation_important_finished, target: :User, user_id: outside_user.id)
  end
end
