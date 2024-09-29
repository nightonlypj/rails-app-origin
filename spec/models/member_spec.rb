require 'rails_helper'

RSpec.describe Member, type: :model do
  # 権限
  # テストパターン
  #   ない, 正常値
  describe 'validates :power' do
    subject(:model) { FactoryBot.build_stubbed(:member, power:) }

    # テストケース
    context 'ない' do
      let(:power) { nil }
      let(:messages) { { power: [get_locale('activerecord.errors.models.member.attributes.power.blank')] } }
      it_behaves_like 'InValid'
    end
    context '正常値' do
      let(:power) { :admin }
      it_behaves_like 'Valid'
    end
  end

  # メールアドレス
  # テストパターン
  #   ない, 1件, 前後スペース・タブ・空行含む・重複, 最大数と同じ, 最大数より多い, 不正な形式が含まれる
  describe '#validate_emails' do
    subject { model.validate_emails }
    let(:model) { FactoryBot.build(:member, emails:) }
    let_it_be(:valid_email) { Faker::Internet.email(name: 'name') }
    let_it_be(:valid_emails) { (1..Settings.member_emails_max_count).map { |index| Faker::Internet.email(name: "name#{index}") } }
    let_it_be(:invalid_email) { 'aaa' }

    # テストケース
    context 'ない' do
      let(:emails) { nil }
      let(:value) { nil }
      let(:messages) { { emails: [get_locale('activerecord.errors.models.member.attributes.emails.blank')] } }
      it_behaves_like 'ValueErrors'
    end
    context '1件' do
      let(:emails) { valid_email }
      let(:value) { [valid_email] }
      let(:messages) { {} }
      it_behaves_like 'ValueErrors'
    end
    context '前後スペース・タブ・空行含む・重複' do
      let(:emails) { "\t #{valid_email}\t \n\n#{valid_email}" }
      let(:value) { [valid_email] }
      let(:messages) { {} }
      it_behaves_like 'ValueErrors'
    end
    context '最大数と同じ' do
      let(:emails) { valid_emails.join("\n") }
      let(:value) { valid_emails }
      let(:messages) { {} }
      it_behaves_like 'ValueErrors'
    end
    context '最大数より多い' do
      let(:emails) { "#{valid_emails.join("\n")}\r\n#{valid_email}" }
      let(:value) { nil }
      let(:messages) do
        { emails: [get_locale('activerecord.errors.models.member.attributes.emails.max_count', count: Settings.member_emails_max_count)] }
      end
      it_behaves_like 'ValueErrors'
    end
    context '不正な形式が含まれる' do
      let(:emails) { "#{valid_email}\n#{invalid_email}" }
      let(:value) { nil }
      let(:messages) { { emails: [get_locale('activerecord.errors.models.member.attributes.emails.invalid', email: invalid_email)] } }
      it_behaves_like 'ValueErrors'
    end
  end

  # 最終更新日時
  # テストパターン
  #   更新日時: 作成日時と同じ, 作成日時以降
  #   招待日時: ない, 更新日時と同じ, 更新日時以前
  describe '#last_updated_at' do
    subject { member.last_updated_at }
    let(:member) { FactoryBot.create(:member, space:, user:, invitationed_at:, created_at:, updated_at:) }
    let_it_be(:user)  { FactoryBot.create(:user) }
    let_it_be(:space) { FactoryBot.create(:space, created_user: user) }
    let(:now) { Time.current.floor }

    # テスト内容
    shared_examples_for 'updated_at' do
      it '更新日時' do
        is_expected.to eq(member.updated_at)
      end
    end

    # テストケース
    context '更新日時が作成日時と同じ' do
      let(:created_at) { now }
      let(:updated_at) { now }

      context '招待日時がない' do
        let(:invitationed_at) { nil }
        it_behaves_like 'Value', nil, 'nil'
      end
      context '招待日時が更新日時と同じ' do
        let(:invitationed_at) { now }
        it_behaves_like 'Value', nil, 'nil'
      end
      context '招待日時が更新日時以前' do
        let(:invitationed_at) { now - 1.hour }
        it_behaves_like 'updated_at'
      end
    end
    context '更新日時が作成日時以降' do
      let(:created_at) { now - 1.hour }
      let(:updated_at) { now }

      context '招待日時がない' do
        let(:invitationed_at) { nil }
        it_behaves_like 'updated_at'
      end
      context '招待日時が更新日時と同じ' do
        let(:invitationed_at) { now }
        it_behaves_like 'updated_at'
      end
      context '招待日時が更新日時以前' do
        let(:invitationed_at) { now - 1.hour }
        it_behaves_like 'updated_at'
      end
    end
  end
end
