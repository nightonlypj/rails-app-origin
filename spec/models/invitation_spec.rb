require 'rails_helper'

RSpec.describe Invitation, type: :model do
  # 最終更新日時
  # テストパターン
  #   更新日時: 作成日時と同じ, 作成日時以降
  describe '#last_updated_at' do
    subject { invitation.last_updated_at }

    # テストケース
    context '更新日時が作成日時と同じ' do
      let(:invitation) { FactoryBot.create(:invitation) }
      it 'なし' do
        is_expected.to eq(nil)
      end
    end
    context '更新日時が作成日時以降' do
      let(:invitation) { FactoryBot.create(:invitation, created_at: Time.current - 1.hour, updated_at: Time.current) }
      it '更新日時' do
        is_expected.to eq(invitation.updated_at)
      end
    end
  end
end
