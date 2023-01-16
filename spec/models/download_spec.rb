require 'rails_helper'

RSpec.describe Download, type: :model do
  # テスト内容（共通）
  shared_examples_for 'Valid' do
    it '保存できる' do
      expect(download).to be_valid
    end
  end
  shared_examples_for 'InValid' do
    it '保存できない。エラーメッセージが一致する' do
      expect(download).to be_invalid
      expect(download.errors.messages).to eq(messages)
    end
  end
  shared_examples_for 'Value' do |value, text = value|
    it "#{text}が返却される" do
      is_expected.to eq(value)
    end
  end

  # 対象
  # テストパターン
  #   ない, 正常値
  describe 'validates :target' do
    let(:download) { FactoryBot.build_stubbed(:download, target: target) }

    # テストケース
    context 'ない' do
      let(:target) { nil }
      let(:messages) { { target: [get_locale('activerecord.errors.models.download.attributes.target.blank')] } }
      it_behaves_like 'InValid'
    end
    context '正常値' do
      let(:target) { :all }
      it_behaves_like 'Valid'
    end
  end

  # 形式
  # テストパターン
  #   ない, 正常値
  describe 'validates :format' do
    let(:download) { FactoryBot.build_stubbed(:download, format: format) }

    # テストケース
    context 'ない' do
      let(:format) { nil }
      let(:messages) { { format: [get_locale('activerecord.errors.models.download.attributes.format.blank')] } }
      it_behaves_like 'InValid'
    end
    context '正常値' do
      let(:format) { :csv }
      it_behaves_like 'Valid'
    end
  end

  # 文字コード
  # テストパターン
  #   ない, 正常値
  describe 'validates :char_code' do
    let(:download) { FactoryBot.build_stubbed(:download, char_code: char_code) }

    # テストケース
    context 'ない' do
      let(:char_code) { nil }
      let(:messages) { { char_code: [get_locale('activerecord.errors.models.download.attributes.char_code.blank')] } }
      it_behaves_like 'InValid'
    end
    context '正常値' do
      let(:char_code) { :sjis }
      it_behaves_like 'Valid'
    end
  end

  # 改行コード
  # テストパターン
  #   ない, 正常値
  describe 'validates :newline_code' do
    let(:download) { FactoryBot.build_stubbed(:download, newline_code: newline_code) }

    # テストケース
    context 'ない' do
      let(:newline_code) { nil }
      let(:messages) { { newline_code: [get_locale('activerecord.errors.models.download.attributes.newline_code.blank')] } }
      it_behaves_like 'InValid'
    end
    context '正常値' do
      let(:newline_code) { :crlf }
      it_behaves_like 'Valid'
    end
  end

  # 出力項目
  # テストパターン
  #   ない, 正常値, 文字列, 文字列（ハッシュ）
  describe 'validates :output_items' do
    let(:download) { FactoryBot.build_stubbed(:download, output_items: output_items) }

    # テストケース
    context 'ない' do
      let(:output_items) { nil }
      let(:messages) { { output_items: [get_locale('activerecord.errors.models.download.attributes.output_items.blank')] } }
      it_behaves_like 'InValid'
    end
    context '正常値' do
      let(:output_items) { '["user.name", "power"]' }
      it_behaves_like 'Valid'
    end
    context '文字列' do
      let(:output_items) { 'user.name,power' }
      let(:messages) { { output_items: [get_locale('activerecord.errors.models.download.attributes.output_items.invalid')] } }
      it_behaves_like 'InValid'
    end
    context '文字列（ハッシュ）' do
      let(:output_items) { '{"text"=>"aaa"}' }
      let(:messages) { { output_items: [get_locale('activerecord.errors.models.download.attributes.output_items.invalid')] } }
      it_behaves_like 'InValid'
    end
  end

  # 選択項目
  describe 'validates :select_items' do
    let(:download) { FactoryBot.build_stubbed(:download, target: target, select_items: select_items) }

    # テストケース
    shared_examples_for 'ない' do |valid|
      let(:select_items) { nil }
      let(:messages) { { select_items: [get_locale('activerecord.errors.models.download.attributes.select_items.blank')] } }
      it_behaves_like valid ? 'Valid' : 'InValid'
    end
    shared_examples_for '正常値' do
      let(:select_items) { '["code000000000000000000001", "code000000000000000000002"]' }
      it_behaves_like 'Valid'
    end
    shared_examples_for '文字列' do
      let(:select_items) { 'code000000000000000000001,code000000000000000000002' }
      let(:messages) { { select_items: [get_locale('activerecord.errors.models.download.attributes.select_items.invalid')] } }
      it_behaves_like 'InValid'
    end
    shared_examples_for '文字列（ハッシュ）' do
      let(:select_items) { '{"text"=>"aaa"}' }
      let(:messages) { { select_items: [get_locale('activerecord.errors.models.download.attributes.select_items.invalid')] } }
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
  # テストパターン
  #   ない, 正常値, 文字列, 文字列（配列）
  describe 'validates :search_params' do
    let(:download) { FactoryBot.build_stubbed(:download, target: target, search_params: search_params) }

    # テストケース
    shared_examples_for 'ない' do |valid|
      let(:search_params) { nil }
      let(:messages) { { search_params: [get_locale('activerecord.errors.models.download.attributes.search_params.blank')] } }
      it_behaves_like valid ? 'Valid' : 'InValid'
    end
    shared_examples_for '正常値' do
      let(:search_params) { '{"text"=>"aaa"}' }
      it_behaves_like 'Valid'
    end
    shared_examples_for '文字列' do
      let(:search_params) { 'aaa' }
      let(:messages) { { search_params: [get_locale('activerecord.errors.models.download.attributes.search_params.invalid')] } }
      it_behaves_like 'InValid'
    end
    shared_examples_for '文字列（配列）' do
      let(:search_params) { '["code000000000000000000001", "code000000000000000000002"]' }
      let(:messages) { { search_params: [get_locale('activerecord.errors.models.download.attributes.search_params.invalid')] } }
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
  # テストパターン
  #   CSV, TSV
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
  # テストパターン
  #   CR+LF, LF, CR
  describe '#row_sep' do
    subject { download.row_sep }
    let(:download) { FactoryBot.create(:download, newline_code: newline_code) }

    context 'CR+LF' do
      let(:newline_code) { :crlf }
      it_behaves_like 'Value', "\r\n", '\r\n'
    end
    context 'LF' do
      let(:newline_code) { :lf }
      it_behaves_like 'Value', "\n", '\n'
    end
    context 'CR' do
      let(:newline_code) { :cr }
      it_behaves_like 'Value', "\r", '\r'
    end
  end
end
