require 'rails_helper'

RSpec.describe User, type: :model do
  shared_context 'データ作成' do |name|
    let!(:user) { FactoryBot.build(:user, name: name) }
  end

  describe 'validates name' do
    # テスト内容
    shared_examples_for 'ToOK' do
      it 'OK' do
        expect(user).to be_valid
      end
    end
    shared_examples_for 'ToNG' do
      it 'NG' do
        expect(user).not_to be_valid
      end
    end

    # テストケース
    context "#{Settings['user_name_minimum'] - 1}文字" do
      include_context 'データ作成', 'a' * (Settings['user_name_minimum'] - 1)
      it_behaves_like 'ToNG'
    end
    context "#{Settings['user_name_minimum']}文字" do
      include_context 'データ作成', 'a' * Settings['user_name_minimum']
      it_behaves_like 'ToOK'
    end
    context "#{Settings['user_name_maximum']}文字" do
      include_context 'データ作成', 'a' * Settings['user_name_maximum']
      it_behaves_like 'ToOK'
    end
    context "#{Settings['user_name_maximum'] + 1}文字" do
      include_context 'データ作成', 'a' * (Settings['user_name_maximum'] + 1)
      it_behaves_like 'ToNG'
    end
  end
end
