require 'rake_helper'

RSpec.describe :holiday, type: :task do
  # 祝日データ更新（前年の2月に元データが更新される） -> tool:create_yamlでseed更新
  # テストパターン
  #   状態: 追加あり, 変更なし, 名称変更あり
  #   ドライラン: true, false
  describe 'holiday:update' do
    subject { Rake.application['holiday:update'].execute('dry_run' => dry_run) }

    let_it_be(:year) { Time.current.year }
    let_it_be(:holidays) do
      [
        FactoryBot.create(:holiday, date: Date.new(year, 1, 1), name: '元旦'),
        FactoryBot.create(:holiday, date: Date.new(year, 5, 5), name: 'こどもの日')
      ]
    end

    before do
      WebMock.stub_request(:get, HOLIDAY_CSV_URL).to_return(
        body:,
        status: 200
      )
    end

    let!(:start_time) { Time.current }
    let(:current_holidays) { Holiday.all.order(:id) }

    shared_examples 'ドライラン' do
      context 'true' do
        let(:dry_run) { 'true' }

        it '追加・変更されない' do
          expect do
            subject
            expect(current_holidays).to eq(holidays)
          end.not_to change(Holiday, :count)
        end
      end
      context 'false' do
        let(:dry_run) { 'false' }

        it '追加または変更される' do
          expect do
            subject
            current_holidays.each_with_index do |current_holiday, index|
              expect_holiday = expect_holidays[index]
              expect(current_holiday).to have_attributes(
                expect_holiday.attributes.symbolize_keys.except(:id, :created_at, :updated_at)
              )
              expect(current_holiday.id).to eq(expect_holiday.id) if expect_holiday.id.present?
              if expect_holiday.created_at.present?
                expect(current_holiday.created_at).to eq(expect_holiday.created_at)
              else
                expect(current_holiday.created_at).to be_between(start_time.floor, Time.current.ceil)
              end
              if expect_holiday.updated_at.present?
                expect(current_holiday.updated_at).to eq(expect_holiday.updated_at)
              else
                expect(current_holiday.updated_at).to be_between(start_time.floor, Time.current.ceil)
              end
            end
          end.to change(Holiday, :count).by(expect_holidays.count - holidays.count)
        end
      end
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
          holidays[0],
          holidays[1],
          Holiday.new(date: Date.new(year + 1, 1, 1), name: '元旦'),
          Holiday.new(date: Date.new(year + 1, 5, 5), name: 'こどもの日')
        ]
      end

      it_behaves_like 'ドライラン'
    end
    context '変更なし' do
      let(:body) do
        "#{HOLIDAY_HEADER_DATE},#{HOLIDAY_HEADER_NAME}\n" \
          "#{year}/1/1,元旦\n" \
          "#{year}/5/5,こどもの日\n"
      end
      let(:expect_holidays) { holidays }

      it_behaves_like 'ドライラン'
    end
    context '名称変更あり' do
      let(:body) do
        "#{HOLIDAY_HEADER_DATE},#{HOLIDAY_HEADER_NAME}\n" \
          "#{year}/1/1,元旦\n" \
          "#{year}/5/5,子供の日\n"
      end
      let(:expect_holidays) do
        new_holiday = holidays[1].dup
        new_holiday.assign_attributes(name: '子供の日', created_at: holidays[1].created_at) # NOTE: 名称変更

        [holidays[0], new_holiday]
      end

      it_behaves_like 'ドライラン'
    end
  end
end
