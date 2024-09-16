require 'rails_helper'

RSpec.describe Invitation, type: :model do
  let_it_be(:created_user) { FactoryBot.create(:user) }
  let_it_be(:space) { FactoryBot.create(:space, created_user:) }

  # コード
  # テストパターン
  #   ない, 正常値, 重複
  describe 'validates :code' do
    let(:model) { FactoryBot.build_stubbed(:invitation, code:) }
    let(:valid_code) { Digest::MD5.hexdigest(SecureRandom.uuid) }

    # テストケース
    context 'ない' do
      let(:code) { nil }
      let(:messages) { { code: [get_locale('activerecord.errors.models.invitation.attributes.code.blank')] } }
      it_behaves_like 'InValid'
    end
    context '正常値' do
      let(:code) { valid_code }
      it_behaves_like 'Valid'
    end
    context '重複' do
      let(:code) { valid_code }
      let(:messages) { { code: [get_locale('activerecord.errors.models.invitation.attributes.code.taken')] } }
      before { FactoryBot.create(:invitation, code:) }
      it_behaves_like 'InValid'
    end
  end

  # 権限
  # テストパターン
  #   ない, 正常値
  describe 'validates :power' do
    let(:model) { FactoryBot.build_stubbed(:invitation, power:) }

    # テストケース
    context 'ない' do
      let(:power) { nil }
      let(:messages) { { power: [get_locale('activerecord.errors.models.invitation.attributes.power.blank')] } }
      it_behaves_like 'InValid'
    end
    context '正常値' do
      let(:power) { :admin }
      it_behaves_like 'Valid'
    end
  end

  # メモ
  # テストパターン
  #   ない, 最大文字数と同じ, 最大文字数より多い
  describe 'validates :memo' do
    let(:model) { FactoryBot.build_stubbed(:invitation, memo:) }

    # テストケース
    context 'ない' do
      let(:memo) { nil }
      it_behaves_like 'Valid'
    end
    context '最大文字数と同じ' do
      let(:memo) { 'a' * Settings.invitation_memo_maximum }
      it_behaves_like 'Valid'
    end
    context '最大文字数より多い' do
      let(:memo) { 'a' * (Settings.invitation_memo_maximum + 1) }
      let(:messages) { { memo: [get_locale('activerecord.errors.models.invitation.attributes.memo.too_long', count: Settings.invitation_memo_maximum)] } }
      it_behaves_like 'InValid'
    end
  end

  # 期限（日付）
  # 前提条件
  #   時間あり, タイムゾーンなし
  # テストパターン
  #   終了日時: ない
  #     ない, YYYY-MM-DD, YYYY/MM/DD, YYYYMMDD, 存在しない日付（1/0, 2/30）, 過去日
  #   終了日時: 過去, 未来
  #     変更なし, 過去に変更, 未来に変更
  describe 'validates :ended_date' do
    let(:model) { FactoryBot.build_stubbed(:invitation, ended_at:, ended_date:, ended_time: '23:59') }

    # テストケース
    shared_examples_for '終了日時がない' do
      context 'ない' do
        let(:ended_date) { nil }
        it_behaves_like 'Valid'
      end
      context 'YYYY-MM-DD' do
        let(:ended_date) { (Time.current + 1.day).strftime('%Y-%m-%d') }
        it_behaves_like 'Valid'
      end
      context 'YYYY/MM/DD' do
        let(:ended_date) { (Time.current + 1.day).strftime('%Y/%m/%d') }
        it_behaves_like 'Valid'
      end
      context 'YYYYMMDD' do
        let(:ended_date) { (Time.current + 1.day).strftime('%Y%m%d') }
        it_behaves_like 'Valid'
      end
      context '存在しない日付（1/0）' do
        let(:ended_date) { "#{Time.current.year}-01-00" }
        let(:messages) { { ended_date: [get_locale('activerecord.errors.models.invitation.attributes.ended_date.invalid')] } }
        it_behaves_like 'InValid'
      end
      context '存在しない日付（2/30）' do
        let(:ended_date) { "#{Time.current.year}-02-30" }
        let(:messages) { { ended_date: [get_locale('activerecord.errors.models.invitation.attributes.ended_date.notfound')] } }
        it_behaves_like 'InValid'
      end
      context '過去日' do
        let(:ended_date) { (Time.current - 1.day).strftime('%Y/%m/%d') }
        let(:messages) { { ended_date: [get_locale('activerecord.errors.models.invitation.attributes.ended_date.before')] } }
        it_behaves_like 'InValid'
      end
    end
    shared_examples_for '終了日時が過去/未来' do
      context '変更なし' do
        let(:ended_date) { ended_at.strftime('%Y-%m-%d') }
        it_behaves_like 'Valid'
      end
      context '過去に変更' do
        let(:ended_date) { (Time.current - 1.day).strftime('%Y-%m-%d') }
        let(:messages) { { ended_date: [get_locale('activerecord.errors.models.invitation.attributes.ended_date.before')] } }
        it_behaves_like 'InValid'
      end
      context '未来に変更' do
        let(:ended_date) { (Time.current + 1.day).strftime('%Y-%m-%d') }
        it_behaves_like 'Valid'
      end
    end

    context '終了日時がない' do
      let(:ended_at) { nil }
      it_behaves_like '終了日時がない'
    end
    context '終了日時が過去' do
      let(:ended_at) { (Time.current - 1.month).end_of_day.floor }
      it_behaves_like '終了日時が過去/未来'
    end
    context '終了日時が未来' do
      let(:ended_at) { (Time.current + 1.month).end_of_day.floor }
      it_behaves_like '終了日時が過去/未来'
    end
  end

  # 期限（時間）
  # 前提条件
  #   日付あり, タイムゾーンなし
  # テストパターン
  #   終了日時: ない
  #     ない, HH:MM, HHMM, 存在しない時間（24:00）, 過去日時
  #   終了日時: 過去, 未来
  #     変更なし, 過去に変更, 未来に変更
  describe 'validates :ended_time' do
    let(:model) { FactoryBot.build_stubbed(:invitation, ended_at:, ended_date:, ended_time:) }

    # テスト内容
    shared_examples_for 'Valid(12:00)' do
      it '保存できる' do
        travel_to(Time.current.beginning_of_day + 12.hours) do
          expect(model).to be_valid
        end
      end
    end
    shared_examples_for 'InValid(12:00)' do
      it '保存できない。エラーメッセージが一致する' do
        travel_to(Time.current.beginning_of_day + 12.hours) do
          expect(model).to be_invalid
          expect(model.errors.messages).to eq(messages)
        end
      end
    end

    # テストケース
    shared_examples_for '終了日時がない' do
      let(:ended_date) { Time.current.strftime('%Y-%m-%d') }
      context 'ない' do
        let(:ended_time) { nil }
        let(:messages) { { ended_time: [get_locale('activerecord.errors.models.invitation.attributes.ended_time.blank')] } }
        it_behaves_like 'InValid'
      end
      context 'HH:MM' do
        let(:ended_time) { '23:59' }
        it_behaves_like 'Valid'
      end
      context 'HHMM' do
        let(:ended_time) { '2359' }
        it_behaves_like 'Valid'
      end
      context 'HH' do
        let(:ended_time) { '23' }
        let(:messages) { { ended_time: [get_locale('activerecord.errors.models.invitation.attributes.ended_time.invalid')] } }
        it_behaves_like 'InValid'
      end
      context '存在しない時間（24:00）' do
        let(:ended_time) { '24:00' }
        let(:messages) { { ended_time: [get_locale('activerecord.errors.models.invitation.attributes.ended_time.invalid')] } }
        it_behaves_like 'InValid'
      end
      context '過去日時' do
        let(:ended_time) { '11:59' }
        let(:messages) { { ended_time: [get_locale('activerecord.errors.models.invitation.attributes.ended_time.before')] } }
        it_behaves_like 'InValid(12:00)'
      end
    end
    shared_examples_for '終了日時が過去/未来' do
      context '変更なし' do
        let(:ended_date) { ended_at.strftime('%Y-%m-%d') }
        let(:ended_time) { ended_at.strftime('%H:%M') }
        it_behaves_like 'Valid'
      end
      context '過去に変更' do
        let(:ended_date) { Time.current.strftime('%Y-%m-%d') }
        let(:ended_time) { '11:59' }
        let(:messages) { { ended_time: [get_locale('activerecord.errors.models.invitation.attributes.ended_time.before')] } }
        it_behaves_like 'InValid(12:00)'
      end
      context '未来に変更' do
        let(:ended_date) { Time.current.strftime('%Y-%m-%d') }
        let(:ended_time) { '12:00' }
        it_behaves_like 'Valid(12:00)'
      end
    end

    context '終了日時がない' do
      let(:ended_at) { nil }
      it_behaves_like '終了日時がない'
    end
    context '終了日時が過去' do
      let(:ended_at) { (Time.current - 1.month).end_of_day.floor }
      it_behaves_like '終了日時が過去/未来'
    end
    context '終了日時が未来' do
      let(:ended_at) { (Time.current + 1.month).end_of_day.floor }
      it_behaves_like '終了日時が過去/未来'
    end
  end

  # 期限（タイムゾーン）
  # 前提条件
  #   日付・時間・タイムゾーンあり
  # テストパターン
  #   +09:00, +00:00 -00:30, 存在しない値（+24:00）
  describe 'validates :ended_zone' do
    let(:model) { FactoryBot.build_stubbed(:invitation, ended_date: '9999-12-31', ended_time: '23:59', ended_zone:) }

    # テスト内容
    shared_examples_for 'OK' do |new_ended_at|
      it '保存でき、終了日時が一致する' do
        expect(model).to be_valid
        expect(model.new_ended_at).to eq(new_ended_at)
      end
    end

    # テストケース
    context '+09:00' do
      let(:ended_zone) { '+09:00' }
      it_behaves_like 'OK', '9999-12-31 23:59:59 +0900'
    end
    context '+00:00' do
      let(:ended_zone) { '+00:00' }
      it_behaves_like 'OK', '9999-12-31 23:59:59 +0000'
    end
    context '-00:30' do
      let(:ended_zone) { '-00:30' }
      it_behaves_like 'OK', '9999-12-31 23:59:59 -0030'
    end
    context '存在しない値（+24:00）' do
      let(:ended_zone) { '+24:00' }
      let(:messages) { { ended_zone: [get_locale('activerecord.errors.models.invitation.attributes.ended_zone.invalid')] } }
      it_behaves_like 'InValid'
    end
  end

  # ドメイン
  # テストパターン
  #   ない, 1件, 前後スペース・タブ・空行含む・重複, 最大数と同じ, 最大数より多い, 不正な形式が含まれる
  describe '#validate_domains' do
    subject { model.validate_domains }
    let(:model) { FactoryBot.build(:invitation, domains:) }
    let_it_be(:valid_domain) { Faker::Internet.domain_name }
    let_it_be(:valid_domains) { (1..Settings.invitation_domains_max_count).map { |index| "#{index}.#{valid_domain}" } }
    let_it_be(:invalid_domain) { 'aaa' }

    # テストケース
    context 'ない' do
      let(:domains) { nil }
      let(:value) { nil }
      let(:messages) { { domains: [get_locale('activerecord.errors.models.invitation.attributes.domains.blank')] } }
      it_behaves_like 'ValueErrors'
    end
    context '1件' do
      let(:domains) { valid_domain }
      let(:value) { [valid_domain] }
      let(:messages) { {} }
      it_behaves_like 'ValueErrors'
    end
    context '前後スペース・タブ・空行含む・重複' do
      let(:domains) { "\t #{valid_domain}\t \n\n#{valid_domain}" }
      let(:value) { [valid_domain] }
      let(:messages) { {} }
      it_behaves_like 'ValueErrors'
    end
    context '最大数と同じ' do
      let(:domains) { valid_domains.join("\n") }
      let(:value) { valid_domains }
      let(:messages) { {} }
      it_behaves_like 'ValueErrors'
    end
    context '最大数より多い' do
      let(:domains) { "#{valid_domains.join("\n")}\r\n#{valid_domain}" }
      let(:value) { nil }
      let(:messages) do
        { domains: [get_locale('activerecord.errors.models.invitation.attributes.domains.max_count', count: Settings.invitation_domains_max_count)] }
      end
      it_behaves_like 'ValueErrors'
    end
    context '不正な形式が含まれる' do
      let(:domains) { "#{valid_domain}\n#{invalid_domain}" }
      let(:value) { nil }
      let(:messages) { { domains: [get_locale('activerecord.errors.models.invitation.attributes.domains.invalid', domain: invalid_domain)] } }
      it_behaves_like 'ValueErrors'
    end
  end

  # ステータス
  # テストパターン
  #   参加日時: ある, ない
  #   削除予定日時: ある, ない
  #   終了日時: 過去, 未来, ない
  describe '#status' do
    subject { invitation.status }
    let(:invitation) { FactoryBot.create(:invitation, ended_at:, destroy_schedule_at:, email_joined_at:, space:, created_user:) }

    # テストケース
    context '参加日時がある' do
      let(:email_joined_at)     { Time.current }
      let(:destroy_schedule_at) { nil }
      let(:ended_at)            { nil }
      it_behaves_like 'Value', :email_joined
    end
    context '削除予定日時がある' do
      let(:email_joined_at)     { nil }
      let(:destroy_schedule_at) { Time.current }
      let(:ended_at)            { nil }
      it_behaves_like 'Value', :deleted
    end
    context '削除予定日時がない' do
      let(:email_joined_at)     { nil }
      let(:destroy_schedule_at) { nil }
      context '終了日時が過去' do
        let(:ended_at) { Time.current - 1.day }
        it_behaves_like 'Value', :expired
      end
      context '終了日時が未来' do
        let(:ended_at) { Time.current + 1.day }
        it_behaves_like 'Value', :active
      end
      context '終了日時がない' do
        let(:ended_at) { nil }
        it_behaves_like 'Value', :active
      end
    end
  end

  # ステータス（表示）
  # テストパターン
  #   ステータス: active, expired, deleted, email_joined
  describe '#status_i18n' do
    subject { invitation.status_i18n }
    let(:invitation) { FactoryBot.create(:invitation, ended_at:, destroy_schedule_at:, email_joined_at:, space:, created_user:) }

    # テストケース
    context 'ステータスがactive' do
      let(:destroy_schedule_at) { nil }
      let(:ended_at)            { nil }
      let(:email_joined_at)     { nil }
      it_behaves_like 'Value_i18n', 'enums.invitation.status.active'
    end
    context 'ステータスがexpired' do
      let(:destroy_schedule_at) { nil }
      let(:ended_at)            { Time.current - 1.day }
      let(:email_joined_at)     { nil }
      it_behaves_like 'Value_i18n', 'enums.invitation.status.expired'
    end
    context 'ステータスがdeleted' do
      let(:destroy_schedule_at) { Time.current }
      let(:ended_at)            { nil }
      let(:email_joined_at)     { nil }
      it_behaves_like 'Value_i18n', 'enums.invitation.status.deleted'
    end
    context 'ステータスがemail_joined' do
      let(:destroy_schedule_at) { nil }
      let(:ended_at)            { nil }
      let(:email_joined_at)     { Time.current }
      it_behaves_like 'Value_i18n', 'enums.invitation.status.email_joined'
    end
  end

  # ドメイン（配列）
  # テストパターン
  #   ドメイン: ない, 1件, 2件
  describe '#domains_array' do
    subject { invitation.domains_array }
    let(:invitation) { FactoryBot.create(:invitation, domains:, space:, created_user:) }

    # テスト内容
    shared_examples_for 'Value' do |text|
      it "#{text}が返却される" do
        is_expected.to eq(value)
      end
    end

    # テストケース
    context 'ドメインがない' do
      let(:domains) { nil }
      let(:value) { [] }
      it_behaves_like 'Value', '配列（空）'
    end
    context 'ドメインが1件' do
      let(:domains) { '["example.com"]' }
      let(:value) { ['example.com'] }
      it_behaves_like 'Value', '配列（1件）'
    end
    context 'ドメインが2件' do
      let(:domains) { '["a.example.com", "b.example.com"]' }
      let(:value) { ['a.example.com', 'b.example.com'] }
      it_behaves_like 'Value', '配列（2件）'
    end
  end

  # 最終更新日時
  # テストパターン
  #   更新日時: 作成日時と同じ, 作成日時以降
  describe '#last_updated_at' do
    subject { invitation.last_updated_at }

    # テストケース
    context '更新日時が作成日時と同じ' do
      let(:invitation) { FactoryBot.create(:invitation, space:, created_user:) }
      it_behaves_like 'Value', nil, 'nil'
    end
    context '更新日時が作成日時以降' do
      let(:invitation) do
        FactoryBot.create(:invitation, created_at: Time.current - 1.hour, updated_at: Time.current, space:, created_user:)
      end
      it '更新日時' do
        is_expected.to eq(invitation.updated_at)
      end
    end
  end
end
