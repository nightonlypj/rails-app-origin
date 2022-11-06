require 'rails_helper'

RSpec.describe Download, type: :model do
  # テスト内容（共通）
  shared_examples_for 'Valid' do
    it '保存できる' do
      expect(download).to be_valid
    end
  end
  shared_examples_for 'InValid' do
    it '保存できない' do
      expect(download).to be_invalid
    end
  end
  shared_examples_for 'Value' do |value, text = value|
    it "#{text}が返却される" do
      is_expected.to eq(value)
    end
  end

  # 対象
  describe 'validates :target' do
    let(:download) { FactoryBot.build_stubbed(:download, target: target) }

    # テストケース
    context 'ない' do
      let(:target) { nil }
      it_behaves_like 'InValid'
    end
    context '正常値' do
      let(:target) { :all }
      it_behaves_like 'Valid'
    end
  end

  # 形式
  describe 'validates :format' do
    let(:download) { FactoryBot.build_stubbed(:download, format: format) }

    # テストケース
    context 'ない' do
      let(:format) { nil }
      it_behaves_like 'InValid'
    end
    context '正常値' do
      let(:format) { :csv }
      it_behaves_like 'Valid'
    end
  end

  # 文字コード
  describe 'validates :char' do
    let(:download) { FactoryBot.build_stubbed(:download, char: char) }

    # テストケース
    context 'ない' do
      let(:char) { nil }
      it_behaves_like 'InValid'
    end
    context '正常値' do
      let(:char) { :sjis }
      it_behaves_like 'Valid'
    end
  end

  # 改行コード
  describe 'validates :newline' do
    let(:download) { FactoryBot.build_stubbed(:download, newline: newline) }

    # テストケース
    context 'ない' do
      let(:newline) { nil }
      it_behaves_like 'InValid'
    end
    context '正常値' do
      let(:newline) { :crlf }
      it_behaves_like 'Valid'
    end
  end

  # 出力項目
  describe 'validates :output_items' do
    let(:download) { FactoryBot.build_stubbed(:download, output_items: output_items) }

    # テストケース
    context 'ない' do
      let(:output_items) { nil }
      it_behaves_like 'InValid'
    end
    context '正常値' do
      let(:output_items) { '["user.name", "power"]' }
      it_behaves_like 'Valid'
    end
    context '文字列' do
      let(:output_items) { 'user.name,power' }
      it_behaves_like 'InValid'
    end
    context '文字列（ハッシュ）' do
      let(:output_items) { '{"text"=>"a"}' }
      it_behaves_like 'InValid'
    end
  end

  # 選択項目
  describe 'validates :select_items' do
    let(:download) { FactoryBot.build_stubbed(:download, target: target, select_items: select_items) }

    # テストケース
    shared_examples_for 'ない' do |valid|
      let(:select_items) { nil }
      it_behaves_like valid ? 'Valid' : 'InValid'
    end
    shared_examples_for '正常値' do
      let(:select_items) { '["code000000000000000000001", "code000000000000000000002"]' }
      it_behaves_like 'Valid'
    end
    shared_examples_for '文字列' do
      let(:select_items) { 'code000000000000000000001,code000000000000000000002' }
      it_behaves_like 'InValid'
    end
    shared_examples_for '文字列（ハッシュ）' do
      let(:select_items) { '{"text"=>"a"}' }
      it_behaves_like 'InValid'
    end

    context '対象が選択項目' do
      let(:target) { :select }
      it_behaves_like 'ない', false
      it_behaves_like '正常値'
      it_behaves_like '文字列'
      it_behaves_like '文字列（ハッシュ）'
    end
    context '対象が選択項目以外' do
      let(:target) { :all }
      it_behaves_like 'ない', true
      it_behaves_like '正常値'
      it_behaves_like '文字列'
      it_behaves_like '文字列（ハッシュ）'
    end
  end

  # 検索パラメータ
  describe 'validates :search_params' do
    let(:download) { FactoryBot.build_stubbed(:download, target: target, search_params: search_params) }

    # テストケース
    shared_examples_for 'ない' do |valid|
      let(:search_params) { nil }
      it_behaves_like valid ? 'Valid' : 'InValid'
    end
    shared_examples_for '正常値' do
      let(:search_params) { '{"text"=>"a"}' }
      it_behaves_like 'Valid'
    end
    shared_examples_for '文字列' do
      let(:search_params) { 'a' }
      it_behaves_like 'InValid'
    end
    shared_examples_for '文字列（配列）' do
      let(:search_params) { '["code000000000000000000001", "code000000000000000000002"]' }
      it_behaves_like 'InValid'
    end

    context '対象が検索' do
      let(:target) { :search }
      it_behaves_like 'ない', false
      it_behaves_like '正常値'
      it_behaves_like '文字列'
      it_behaves_like '文字列（配列）'
    end
    context '対象が検索以外' do
      let(:target) { :all }
      it_behaves_like 'ない', true
      it_behaves_like '正常値'
      it_behaves_like '文字列'
      it_behaves_like '文字列（配列）'
    end
  end

  # 区切り文字
  describe '#col_sep' do
    subject { download.col_sep }
    let(:download) { FactoryBot.create(:download, format: format) }

    context 'CSV' do
      let(:format) { :csv }
      it_behaves_like 'Value', ','
    end
    context 'TSV' do
      let(:format) { :tsv }
      it_behaves_like 'Value', "\t", '\t'
    end
  end

  # 改行文字
  describe '#row_sep' do
    subject { download.row_sep }
    let(:download) { FactoryBot.create(:download, newline: newline) }

    context 'CR+LF' do
      let(:newline) { :crlf }
      it_behaves_like 'Value', "\r\n", '\r\n'
    end
    context 'LF' do
      let(:newline) { :lf }
      it_behaves_like 'Value', "\n", '\n'
    end
    context 'CR' do
      let(:newline) { :cr }
      it_behaves_like 'Value', "\r", '\r'
    end
  end
end
