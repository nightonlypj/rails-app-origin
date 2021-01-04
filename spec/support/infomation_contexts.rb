shared_context 'お知らせ一覧作成' do |all_forever_count, all_future_count, user_forever_count, user_future_count|
  before do
    # 全員（過去/未来〜なし）＋概要なし
    @infomations = FactoryBot.create_list(:infomation, all_forever_count,
                                          started_at: Time.current - 1.day, ended_at: nil, target: :All, summary: nil)
    FactoryBot.create(:infomation, started_at: Time.current + 1.day, ended_at: nil, target: :All, summary: nil)
    # 全員（過去/未来〜未来）＋本文なし
    @infomations += FactoryBot.create_list(:infomation, all_future_count,
                                           started_at: Time.current - 1.day, ended_at: Time.current + 2.days, target: :All, body: nil)
    FactoryBot.create(:infomation, started_at: Time.current + 1.day, ended_at: Time.current + 2.days, target: :All, body: nil)
    # 対象ユーザー（過去/未来〜なし）
    if user_forever_count > 0
      @infomations += FactoryBot.create_list(:infomation, user_forever_count,
                                             started_at: Time.current - 1.day, ended_at: nil, target: :User, user_id: user.id)
      FactoryBot.create(:infomation, started_at: Time.current + 1.day, ended_at: nil, target: :User, user_id: user.id)
    end
    # 対象ユーザー（過去/未来〜未来）
    if user_future_count > 0
      @infomations += FactoryBot.create_list(:infomation, user_future_count,
                                             started_at: Time.current - 1.day, ended_at: Time.current + 2.days, target: :User, user_id: user.id)
      FactoryBot.create(:infomation, started_at: Time.current + 1.day, ended_at: Time.current + 2.days, target: :User, user_id: user.id)
    end
    # 対象外ユーザー（過去/未来〜なし）
    outside_user = FactoryBot.create(:user)
    FactoryBot.create(:infomation, started_at: Time.current - 1.day, ended_at: nil, target: :User, user_id: outside_user.id)
    FactoryBot.create(:infomation, started_at: Time.current + 1.day, ended_at: nil, target: :User, user_id: outside_user.id)
    # 対象外ユーザー（過去/未来〜未来）
    FactoryBot.create(:infomation, started_at: Time.current - 1.day, ended_at: Time.current + 2.days, target: :User, user_id: outside_user.id)
    FactoryBot.create(:infomation, started_at: Time.current + 1.day, ended_at: Time.current + 2.days, target: :User, user_id: outside_user.id)
  end
end
