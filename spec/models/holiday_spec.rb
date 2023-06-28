require 'rails_helper'

RSpec.describe Holiday, type: :model do
  # 日付
  # テストパターン
  #   ない, 正常値, 重複
  describe 'validates :date' do
    let(:model) { FactoryBot.build_stubbed(:holiday, date:, name: 'a') }

    # テストケース
    context 'ない' do
      let(:date) { nil }
      let(:messages) { { date: [get_locale('activerecord.errors.models.holiday.attributes.date.blank')] } }
      it_behaves_like 'InValid'
    end
    context '正常値' do
      let(:date) { Time.zone.today }
      it_behaves_like 'Valid'
    end
    context '重複' do
      before { FactoryBot.create(:holiday, date:) }
      let(:date) { Time.zone.today }
      let(:messages) { { date: [get_locale('activerecord.errors.models.holiday.attributes.date.taken')] } }
      it_behaves_like 'InValid'
    end
  end

  # 名称
  # テストパターン
  #   ない, ある
  describe 'validates :name' do
    let(:model) { FactoryBot.build_stubbed(:holiday, name:) }

    # テストケース
    context 'ない' do
      let(:name) { nil }
      let(:messages) { { name: [get_locale('activerecord.errors.models.holiday.attributes.name.blank')] } }
      it_behaves_like 'InValid'
    end
    context 'ある' do
      let(:name) { 'a' }
      it_behaves_like 'Valid'
    end
  end
end
