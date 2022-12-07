require 'rails_helper'

RSpec.describe MembersHelper, type: :helper do
  # 権限のクラス名を返却
  # テストパターン
  #   admin, writer, nil, 空
  describe 'power_class_name' do
    subject { helper.power_class_name(power) }

    # テスト内容
    shared_examples_for 'value' do |value|
      it 'value' do
        is_expected.to eq(value)
      end
    end

    # テストケース
    context 'admin' do
      let(:power) { 'admin' }
      it_behaves_like 'value', 'fa-user-cog'
    end
    context 'writer' do
      let(:power) { :writer }
      it_behaves_like 'value', 'fa-user-edit'
    end
    context 'nil' do
      let(:power) { nil }
      it_behaves_like 'value', 'fa-user'
    end
    context '空' do
      let(:power) { '' }
      it_behaves_like 'value', 'fa-user'
    end
  end
end
