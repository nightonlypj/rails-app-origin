require 'rails_helper'

RSpec.describe AdminUser, type: :model do
  # 氏名
  # テストパターン
  #   ない, 最小文字数より少ない, 最小文字数と同じ, 最大文字数と同じ, 最大文字数より多い
  describe 'validates :name' do
    subject(:model) { FactoryBot.build_stubbed(:admin_user, name:) }

    # テストケース
    context 'ない' do
      let(:name) { nil }
      let(:messages) { { name: [get_locale('activerecord.errors.models.admin_user.attributes.name.blank')] } }
      it_behaves_like 'InValid'
    end
    context '最小文字数より少ない' do
      let(:name) { 'a' * (Settings.user_name_minimum - 1) }
      let(:messages) { { name: [get_locale('activerecord.errors.models.admin_user.attributes.name.too_short', count: Settings.user_name_minimum)] } }
      it_behaves_like 'InValid'
    end
    context '最小文字数と同じ' do
      let(:name) { 'a' * Settings.user_name_minimum }
      it_behaves_like 'Valid'
    end
    context '最大文字数と同じ' do
      let(:name) { 'a' * Settings.user_name_maximum }
      it_behaves_like 'Valid'
    end
    context '最大文字数より多い' do
      let(:name) { 'a' * (Settings.user_name_maximum + 1) }
      let(:messages) { { name: [get_locale('activerecord.errors.models.admin_user.attributes.name.too_long', count: Settings.user_name_maximum)] } }
      it_behaves_like 'InValid'
    end
  end
end
