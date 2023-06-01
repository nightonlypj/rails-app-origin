require 'rails_helper'

RSpec.describe MembersHelper, type: :helper do
  # 権限のクラス名を返却
  # テストパターン
  #   admin, writer, nil, 空
  describe 'power_class_name' do
    subject { helper.power_class_name(power) }

    # テストケース
    context 'admin' do
      let(:power) { 'admin' }
      it_behaves_like 'Value', 'fa-user-cog'
    end
    context 'writer' do
      let(:power) { :writer }
      it_behaves_like 'Value', 'fa-user-edit'
    end
    context 'nil' do
      let(:power) { nil }
      it_behaves_like 'Value', 'fa-user'
    end
    context '空' do
      let(:power) { '' }
      it_behaves_like 'Value', 'fa-user'
    end
  end
end
