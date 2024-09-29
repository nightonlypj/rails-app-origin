require 'rails_helper'

RSpec.describe DownloadJob, type: :job do
  # ダウンロードファイル作成
  # 前提条件
  # テストパターン
  #   出力項目: ある, ない
  #   model: member（space: 存在する, 存在しない, ない）, 存在しない, ない
  #   権限: ある（管理者）, ない（投稿者, 閲覧者）, なし
  #   対象/形式/文字コード/改行コード: 選択項目/CSV/Shift_JIS/CR+LF, 検索/CSV/EUC-JP/CR, 全て/TSV/UTF-8/LF
  describe '.perform' do
    subject { job.perform(download.id) }
    let(:job) { described_class.new }

    let_it_be(:user)  { FactoryBot.create(:user) }
    let_it_be(:space) { FactoryBot.create(:space, created_user: user) }

    # テスト内容
    let(:current_download)      { Download.find(download.id) }
    let(:current_download_file) { DownloadFile.find_by(download: current_download) }
    before do # NOTE: let_it_beだと他のテストでセットした値が残る為、初期化
      download.status = :waiting
      download.error_message = nil
      download.completed_at = nil
    end
    shared_examples_for 'OK' do
      let!(:start_time) { Time.current.floor }
      let(:result_body) do
        result = ''
        body_data.each do |data|
          result += data.to_csv(col_sep: download.col_sep, row_sep: download.row_sep)
        end

        result
      end
      it 'ダウンロードの対象項目が変更され、ダウンロードファイルが作成・対象項目が設定される' do
        subject
        expect(current_download.status.to_sym).to eq(:success)
        expect(current_download.completed_at).to be_between(start_time, Time.current)

        # NOTE: current_download_file.body.encoding: #<Encoding:ASCII-8BIT>
        case download.char_code.to_sym
        when :sjis
          current_download_file.body.force_encoding(Encoding::Shift_JIS)
        when :eucjp
          current_download_file.body.force_encoding(Encoding::EUC_JP)
        when :utf8
          current_download_file.body.force_encoding(Encoding::UTF_8)
        else
          # :nocov:
          raise "char_code not found.(#{download.char_code})"
          # :nocov:
        end
        expect(current_download_file.body.encode(Encoding::UTF_8)).to eq(result_body) # NOTE: UTF-8に変換して期待値と比較
      end
    end
    shared_examples_for 'NG' do |message|
      let!(:start_time) { Time.current.floor }
      it '例外が発生し、対象項目が設定される' do
        subject
      rescue StandardError => e
        job.status_failure(e) # NOTE: Specだとrescue_fromが呼び出されない為
        expect(current_download.status.to_sym).to eq(:failure)
        expect(current_download.error_message).to eq(message)
        expect(current_download.completed_at).to be_between(start_time, Time.current)
      end
    end

    # テストケース
    let_it_be(:member1) { FactoryBot.create(:member, space:, user: FactoryBot.create(:user, name: '氏名(Aaa)'), invitationed_user: user) }
    let_it_be(:member2) { FactoryBot.create(:member, space:, user: FactoryBot.create(:user, email: '_Aaa@example.com'), last_updated_user: user) }
    before_all { FactoryBot.create(:member, user: FactoryBot.create(:user, name: '氏名(Aaa)')) } # NOTE: 対象外
    shared_context 'set_member_body' do
      let(:body_data) do
        result = [I18n.t('items.member').values]
        members.each do |member|
          result.push(
            [
              member.user.name,
              member.user.email,
              member.power_i18n,
              member.invitationed_user&.name,
              I18n.l(member.invitationed_at, default: nil),
              member.last_updated_user&.name,
              I18n.l(member.last_updated_at, default: nil)
            ]
          )
        end

        result
      end
    end

    shared_examples_for '[member][ある]選択項目/CSV/Shift_JIS/CR+LF' do
      let_it_be(:download) do
        FactoryBot.create(:download, user:, model: 'member', space:, output_items:,
                                     target: :select, select_items: [member1.user.code, member2.user.code],
                                     format: :csv, char_code: :sjis, newline_code: :crlf)
      end
      let(:members) { [member2, member1] }
      include_context 'set_member_body'
      it_behaves_like 'OK'
    end
    shared_examples_for '[member][ある]検索/CSV/EUC-JP/CR' do
      let_it_be(:download) do
        FactoryBot.create(:download, user:, model: 'member', space:, output_items:,
                                     target: :search, search_params: { 'text' => 'aaa' },
                                     format: :csv, char_code: :eucjp, newline_code: :cr)
      end
      let(:members) { [member2, member1] }
      include_context 'set_member_body'
      it_behaves_like 'OK'
    end
    shared_examples_for '[member][ある]全て/TSV/UTF-8/LF' do
      let_it_be(:download) do
        FactoryBot.create(:download, user:, model: 'member', space:, output_items:,
                                     target: :all,
                                     format: :tsv, char_code: :utf8, newline_code: :lf)
      end
      let(:members) { [member, member2, member1] }
      include_context 'set_member_body'
      it_behaves_like 'OK'
    end

    shared_examples_for '[member]権限がある' do |power|
      let_it_be(:member) { FactoryBot.create(:member, power, space:, user:) }
      let_it_be(:output_items) { I18n.t('items.member').stringify_keys.keys }
      it_behaves_like '[member][ある]選択項目/CSV/Shift_JIS/CR+LF'
      it_behaves_like '[member][ある]検索/CSV/EUC-JP/CR'
      it_behaves_like '[member][ある]全て/TSV/UTF-8/LF'
    end
    shared_examples_for '[member]権限がない' do |power|
      let_it_be(:member) { FactoryBot.create(:member, power, space:, user:) }
      it_behaves_like 'ToRaise', 'power not found.'
      it_behaves_like 'NG', 'power not found.'
    end
    shared_examples_for '[member]権限がなし' do
      it_behaves_like 'ToRaise', 'current_member not found.'
      it_behaves_like 'NG', 'current_member not found.'
    end

    context '出力項目がある' do
      context 'modelがmember（spaceが存在する）' do
        let_it_be(:download) { FactoryBot.create(:download, user:, model: 'member', space:) }
        it_behaves_like '[member]権限がある', :admin
        it_behaves_like '[member]権限がない', :writer
        it_behaves_like '[member]権限がない', :reader
        it_behaves_like '[member]権限がなし'
      end
      context 'modelがmember（spaceが存在しない）' do
        let_it_be(:download) { FactoryBot.create(:download, user:, model: 'member', space_id: 0) }
        it_behaves_like 'ToRaise', 'space not found.'
        it_behaves_like 'NG', 'space not found.'
      end
      context 'modelがmember（spaceがない）' do
        let_it_be(:download) { FactoryBot.create(:download, user:, model: 'member', space: nil) }
        it_behaves_like 'ToRaise', 'space not found.'
        it_behaves_like 'NG', 'space not found.'
      end
      # context 'modelが存在しない' do
      #   let_it_be(:download) { FactoryBot.create(:download, :skip_validate, user: user, model: 'xxx') } # NOTE: 'xxx' is not a valid model
      #   it_behaves_like 'ToRaise', 'model not found.(xxx)'
      #   it_behaves_like 'NG', 'model not found.(xxx)'
      # end
      # context 'modelがない' do
      #   let_it_be(:download) { FactoryBot.create(:download, :skip_validate, user: user, model: nil) } # NOTE: ActiveRecord::NotNullViolation
      #   it_behaves_like 'ToRaise', 'model not found.()'
      #   it_behaves_like 'NG', 'model not found.()'
      # end
    end
    context '出力項目がない' do
      let_it_be(:download) { FactoryBot.create(:download, :skip_validate, user:, model: 'member', space:, output_items: '[]') }
      it_behaves_like 'ToRaise', I18n.locale == :ja ? 'バリデーションに失敗しました: 出力項目選択してください。' : 'Validation failed: Output items Please select.'
      it_behaves_like 'NG', I18n.locale == :ja ? 'バリデーションに失敗しました: 出力項目選択してください。' : 'Validation failed: Output items Please select.'
    end
  end
end
