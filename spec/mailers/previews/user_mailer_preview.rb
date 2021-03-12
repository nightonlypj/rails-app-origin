# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview
  # アカウント削除受け付けのお知らせ
  def destroy_reserved
    user = FactoryBot.build_stubbed(:user, destroy_schedule_at: Time.current + Settings['destroy_schedule_days'].days)
    UserMailer.with(user: user).destroy_reserved
  end

  # アカウント削除取り消し完了のお知らせ
  def undo_destroy_reserved
    user = FactoryBot.build_stubbed(:user)
    UserMailer.with(user: user).undo_destroy_reserved
  end

  # アカウント削除完了のお知らせ
  def destroy_completed
    user = FactoryBot.build_stubbed(:user)
    UserMailer.with(user: user).destroy_completed
  end

  # メンバー登録のお願い
  def member_create
    send_member_create(true, true, true)
  end

  # メンバー登録のお願い（メンバー解除済み）
  def member_create_not_member
    send_member_create(false, true, true)
  end

  # メンバー登録のお願い（招待者削除済み）
  def member_create_not_invitation_user
    send_member_create(true, false, true)
  end

  # メンバー登録のお願い（顧客削除済み）
  def member_create_not_customer
    send_member_create(true, true, false)
  end

  # メンバー登録のお願い（メンバー解除・招待者削除済み）
  def member_create_not_member_invitation_user
    send_member_create(false, false, true)
  end

  # メンバー登録のお願い（メンバー解除・顧客削除済み）
  def member_create_not_member_customer
    send_member_create(false, true, false)
  end

  # メンバー登録のお願い（メンバー解除・招待者削除・顧客削除済み）
  def member_create_not_member_invitation_user_customer
    send_member_create(false, false, false)
  end

  private

  # メンバー登録のお願い（各ケース）
  def send_member_create(enable_member, enable_invitation_user, enable_customer)
    user = FactoryBot.build_stubbed(:user, name: '-' * Settings['user_name_minimum'], invitation_token: Digest::MD5.hexdigest(SecureRandom.uuid),
                                           invitation_requested_at: Time.current)
    member = enable_member ? FactoryBot.build_stubbed(:member, power: :Member, invitationed_at: Time.current) : nil
    customer = enable_customer ? FactoryBot.build_stubbed(:customer) : nil
    invitation_user = enable_invitation_user ? FactoryBot.build_stubbed(:user) : nil
    UserMailer.with(user: user, member: member, customer: customer, invitation_user: invitation_user).member_create
  end
end
