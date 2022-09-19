shared_context 'お知らせ一覧作成' do |all_forever_count, all_future_count, user_forever_count, user_future_count|
  before_all do
    # 全員（現在/未来〜なし）＋概要なし
    @all_infomations = FactoryBot.create_list(:infomation, all_forever_count, :forever, summary: nil)
    FactoryBot.create(:infomation, :reserve_forever, summary: nil)
    # 全員（現在/未来〜未来）＋概要・本文なし
    @all_infomations += FactoryBot.create_list(:infomation, all_future_count, summary: nil, body: nil)
    FactoryBot.create(:infomation, :reserve, summary: nil, body: nil)
    # 全員（過去〜過去）
    FactoryBot.create(:infomation, :finished)

    # 対象ユーザー（現在/未来〜なし）＋本文なし
    @user_infomations = @all_infomations
    if user_forever_count.positive?
      @user_infomations += FactoryBot.create_list(:infomation, user_forever_count, :forever, :user, user: user, body: nil)
      FactoryBot.create(:infomation, :reserve_forever, :user, user: user, body: nil)
    end
    # 対象ユーザー（現在/未来〜未来）
    if user_future_count.positive?
      @user_infomations += FactoryBot.create_list(:infomation, user_future_count, :user, user: user)
      FactoryBot.create(:infomation, :reserve, :user, user: user)
    end
    # 対象ユーザー（過去〜過去）
    FactoryBot.create(:infomation, :finished, :user, user: user) if (user_forever_count + user_future_count).positive?

    # 対象外ユーザー（現在/未来〜なし）
    outside_user = FactoryBot.create(:user)
    FactoryBot.create(:infomation, :forever, :user, user: outside_user)
    FactoryBot.create(:infomation, :reserve_forever, :user, user: outside_user)
    # 対象外ユーザー（現在/未来〜未来）
    FactoryBot.create(:infomation, :user, user: outside_user)
    FactoryBot.create(:infomation, :reserve, :user, user: outside_user)
    # 対象外ユーザー（過去〜過去）
    FactoryBot.create(:infomation, :finished, :user, user: outside_user)
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
    if user_forever_count.positive?
      @user_important_infomations += FactoryBot.create_list(:infomation, user_forever_count, :important, :force_forever, :user, user: user, body: nil)
      FactoryBot.create(:infomation, :important, :force_reserve_forever, :user, user: user, body: nil)
    end
    # 対象ユーザー（現在/未来〜未来）
    if user_future_count.positive?
      @user_important_infomations += FactoryBot.create_list(:infomation, user_future_count, :important, :user, user: user)
      FactoryBot.create(:infomation, :important, :force_reserve, :user, user: user)
    end
    # 対象ユーザー（過去〜過去）
    FactoryBot.create(:infomation, :important, :force_finished, :user, user: user) if (user_forever_count + user_future_count).positive?

    # 対象外ユーザー（現在/未来〜なし）
    outside_user = FactoryBot.create(:user)
    FactoryBot.create(:infomation, :important, :force_forever, :user, user: outside_user)
    FactoryBot.create(:infomation, :important, :force_reserve_forever, :user, user: outside_user)
    # 対象外ユーザー（現在/未来〜未来）
    FactoryBot.create(:infomation, :important, :user, user: outside_user)
    FactoryBot.create(:infomation, :important, :force_reserve, :user, user: outside_user)
    # 対象外ユーザー（過去〜過去）
    FactoryBot.create(:infomation, :important, :force_finished, :user, user: outside_user)
  end
end
