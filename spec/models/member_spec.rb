require 'rails_helper'

RSpec.describe Member, type: :model do
  # 権限
  # テストパターン
  #   ない, 正常値
  describe 'validates :power' do
    let(:model) { FactoryBot.build_stubbed(:member, power: power) }

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

  # 最終更新日時
  # テストパターン
  #   更新日時: 作成日時と同じ, 作成日時以降
  #   招待日時: ない, 更新日時と同じ, 更新日時以前
  describe '#last_updated_at' do
    subject { member.last_updated_at }
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
      context '招待日時がない' do
        let(:member) { FactoryBot.create(:member, space: space, user: user, invitationed_at: nil, created_at: now, updated_at: now) }
        it_behaves_like 'Value', nil, 'nil'
      end
      context '招待日時が更新日時と同じ' do
        let(:member) { FactoryBot.create(:member, space: space, user: user, invitationed_at: now, created_at: now, updated_at: now) }
        it_behaves_like 'Value', nil, 'nil'
      end
      context '招待日時が更新日時以前' do
        let(:member) { FactoryBot.create(:member, space: space, user: user, invitationed_at: now - 1.hour, created_at: now, updated_at: now) }
        it_behaves_like 'updated_at'
      end
    end
    context '更新日時が作成日時以降' do
      context '招待日時がない' do
        let(:member) { FactoryBot.create(:member, space: space, user: user, invitationed_at: nil, created_at: now - 1.hour, updated_at: now) }
        it_behaves_like 'updated_at'
      end
      context '招待日時が更新日時と同じ' do
        let(:member) { FactoryBot.create(:member, space: space, user: user, invitationed_at: now, created_at: now - 1.hour, updated_at: now) }
        it_behaves_like 'updated_at'
      end
      context '招待日時が更新日時以前' do
        let(:member) { FactoryBot.create(:member, space: space, user: user, invitationed_at: now - 1.hour, created_at: now - 1.hour, updated_at: now) }
        it_behaves_like 'updated_at'
      end
    end
  end
end
