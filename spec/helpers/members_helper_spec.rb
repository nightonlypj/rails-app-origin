require 'rails_helper'

RSpec.describe MembersHelper, type: :helper do
  # 権限のクラス名を返却
  describe 'power_class_name' do
    subject { helper.power_class_name(power) }

    # テスト内容
    shared_examples_for 'value' do |value|
      it 'value' do
        is_expected.to eq(value)
      end
    end

    # テストケース
    context 'Admin' do
      let(:power) { 'Admin' }
      it_behaves_like 'value', 'fa-user-cog'
    end
    context 'Writer' do
      let(:power) { :Writer }
      it_behaves_like 'value', 'fa-user-edit'
    end
    context 'nil' do
      let(:power) { nil }
      it_behaves_like 'value', 'fa-user'
    end
    context 'blank' do
      let(:power) { '' }
      it_behaves_like 'value', 'fa-user'
    end
  end
end
