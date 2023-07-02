require 'rake_helper'
require 'webmock/rspec'

RSpec.describe :holiday, type: :task do
  # 祝日データ更新（前年の2月に元データが更新される） → tool:create_yamlでseed更新
  # テストパターン
  #   追加あり, 変更なし, 名称変更あり
  describe 'holiday:update' do
    subject { Rake.application['holiday:update'].invoke(dry_run) }

    let_it_be(:year) { Time.current.year }
    let_it_be(:holidays) do
      [
        FactoryBot.create(:holiday, date: Date.new(year, 1, 1), name: '元旦'),
        FactoryBot.create(:holiday, date: Date.new(year, 5, 5), name: 'こどもの日')
      ]
    end
    let(:current_holidays) { Holiday.all.order(:id) }

    # テスト内容
    before do
      WebMock.stub_request(:get, HOLIDAY_CSV_URL).to_return(
        body:,
        status: 200
      )
    end
    shared_examples_for 'OK' do
      it '追加または変更される' do
        subject
        expect(Holiday.count).to eq(expect_holidays.count)
        current_holidays.each_with_index do |holiday, index|
          expect(holiday.date).to eq(expect_holidays[index][:date])
          expect(holiday.name).to eq(expect_holidays[index][:name])
        end
      end
    end
    shared_examples_for 'NG' do
      it '追加・変更されない' do
        subject
        expect(Holiday.count).to eq(holidays.count)
        expect(current_holidays).to eq(holidays)
      end
    end

    # テストケース
    shared_examples_for '[*]ドライランtrue' do
      let(:dry_run) { 'true' }
      it_behaves_like 'NG'
    end
    shared_examples_for '[*]ドライランfalse' do
      let(:dry_run) { 'false' }
      it_behaves_like 'OK'
    end

    context '追加あり' do
      let(:body) do
        "#{HOLIDAY_HEADER_DATE},#{HOLIDAY_HEADER_NAME}\n" \
          "#{year}/1/1,元旦\n" \
          "#{year}/5/5,こどもの日\n" \
          "#{year + 1}/1/1,元旦\n" \
          "#{year + 1}/5/5,こどもの日\n"
      end
      let(:expect_holidays) do
        [
          { date: Date.new(year, 1, 1), name: '元旦' },
          { date: Date.new(year, 5, 5), name: 'こどもの日' },
          { date: Date.new(year + 1, 1, 1), name: '元旦' },
          { date: Date.new(year + 1, 5, 5), name: 'こどもの日' }
        ]
      end
      it_behaves_like '[*]ドライランtrue'
      it_behaves_like '[*]ドライランfalse'
    end
    context '変更なし' do
      let(:body) do
        "#{HOLIDAY_HEADER_DATE},#{HOLIDAY_HEADER_NAME}\n" \
          "#{year}/1/1,元旦\n" \
          "#{year}/5/5,こどもの日\n"
      end
      let(:expect_holidays) do
        [
          { date: Date.new(year, 1, 1), name: '元旦' },
          { date: Date.new(year, 5, 5), name: 'こどもの日' }
        ]
      end
      it_behaves_like '[*]ドライランtrue'
      it_behaves_like '[*]ドライランfalse'
    end
    context '名称変更あり' do
      let(:body) do
        "#{HOLIDAY_HEADER_DATE},#{HOLIDAY_HEADER_NAME}\n" \
          "#{year}/1/1,元旦\n" \
          "#{year}/5/5,子供の日\n"
      end
      let(:expect_holidays) do
        [
          { date: Date.new(year, 1, 1), name: '元旦' },
          { date: Date.new(year, 5, 5), name: '子供の日' } # NOTE: 名称変更
        ]
      end
      it_behaves_like '[*]ドライランtrue'
      it_behaves_like '[*]ドライランfalse'
    end
  end
end
