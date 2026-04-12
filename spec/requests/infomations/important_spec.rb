require 'rails_helper'

RSpec.describe 'Infomations', type: :request do
  let(:response_parsed_body_sym) { response.parsed_body.deep_symbolize_keys }

  # 大切なお知らせ一覧API
  # テストパターン
  #   URLの拡張子: ない, .json
  #   Acceptヘッダ: HTMLが含まれる, JSONが含まれる
  #   未ログイン, ログイン中, ログイン中（削除予約済み）, APIログイン中, APIログイン中（削除予約済み）
  #   大切なお知らせ: ない, ある
  #     地域: 全て, 一致, 不一致
  #     対象: 全員, 自分, 他人
  #     強制表示期間: 未設定, 期間内, 終了, 前
  describe 'GET #important' do
    subject { get important_infomations_path(format: subject_format), headers: auth_headers.merge(accept_headers) }

    shared_examples 'アクセス拒否' do
      it 'HTTPステータスが406' do
        is_expected.to eq(406)
        expect(response.body).to eq('')
      end
    end

    shared_examples '正常なレスポンス(JSON)' do
      it 'HTTPステータスが200。対象項目が一致する' do
        is_expected.to eq(200)
        expect(response_parsed_body_sym).to eq(expect_response)
      end
    end

    context 'URLの拡張子がない' do
      let(:subject_format) { nil }
      include_context '未ログイン処理'

      context 'AcceptヘッダにHTMLが含まれる' do
        let(:accept_headers) { ACCEPT_INC_HTML }

        it_behaves_like 'アクセス拒否'
      end
      context 'AcceptヘッダにJSONが含まれる' do
        let(:accept_headers) { ACCEPT_INC_JSON }

        it_behaves_like 'アクセス拒否'
      end
    end
    context 'URLの拡張子が.json' do
      let(:subject_format) { :json }

      context 'AcceptヘッダにHTMLが含まれる' do
        let(:accept_headers) { ACCEPT_INC_HTML }
        include_context '未ログイン処理'

        it_behaves_like 'アクセス拒否'
      end
      context 'AcceptヘッダにJSONが含まれる' do
        let(:accept_headers) { ACCEPT_INC_JSON }

        context '大切なお知らせがない' do
          include_context '未ログイン処理'
          let(:expect_response) { { success: true, infomations: [] } }

          it_behaves_like '正常なレスポンス(JSON)'
        end
        context '大切なお知らせがある' do
          let_it_be(:inside_all_infomation) do
            FactoryBot.create(:infomation, :all_locale, :all, :force_period_inside, started_at: 1.minute.ago, title: '対象が全員', body: '本文')
          end
          before_all do
            FactoryBot.create(:infomation, :other_locale, :all, :force_period_inside, title: '地域が不一致')
            FactoryBot.create(:infomation, :my_locale, :user, :force_period_inside, title: '対象が他人')
            FactoryBot.create(:infomation, :my_locale, :all, :force_period_not_set, title: '強制表示期間が未設定')
            FactoryBot.create(:infomation, :my_locale, :all, :force_period_finished, title: '強制表示期間が終了')
            FactoryBot.create(:infomation, :my_locale, :all, :force_period_before, title: '強制表示期間が前')
          end
          shared_context 'ユーザー向けお知らせ作成' do
            let_it_be(:user_infomation) do
              FactoryBot.create(:infomation, :my_locale, :user, :force_period_inside, user:, started_at: 1.second.ago, title: '対象がユーザー', body: nil)
            end
          end

          let(:expect_all_infomation) do
            {
              id: inside_all_infomation.id,
              label: inside_all_infomation.label,
              label_i18n: inside_all_infomation.label_i18n,
              title: '対象が全員',
              summary: inside_all_infomation.summary,
              body_present: true,
              started_at: I18n.l(inside_all_infomation.started_at, format: :json),
              ended_at: I18n.l(inside_all_infomation.ended_at, format: :json, default: nil),
              target: 'all',
              force_started_at: I18n.l(inside_all_infomation.force_started_at, format: :json, default: nil),
              force_ended_at: I18n.l(inside_all_infomation.force_ended_at, format: :json, default: nil)
            }
          end
          let(:expect_user_infomation) do
            {
              id: user_infomation.id,
              label: user_infomation.label,
              label_i18n: user_infomation.label_i18n,
              title: '対象がユーザー',
              summary: user_infomation.summary,
              body_present: false,
              started_at: I18n.l(user_infomation.started_at, format: :json),
              ended_at: I18n.l(user_infomation.ended_at, format: :json, default: nil),
              target: 'user',
              force_started_at: I18n.l(user_infomation.force_started_at, format: :json, default: nil),
              force_ended_at: I18n.l(user_infomation.force_ended_at, format: :json, default: nil)
            }
          end

          context '未ログイン' do
            include_context '未ログイン処理'
            let(:expect_response) { { success: true, infomations: [expect_all_infomation] } }

            it_behaves_like '正常なレスポンス(JSON)'
          end
          context 'ログイン中' do
            include_context 'ログイン処理'
            include_context 'ユーザー向けお知らせ作成'
            let(:expect_response) { { success: true, infomations: [expect_all_infomation] } } # NOTE: APIは未ログイン扱いの為

            it_behaves_like '正常なレスポンス(JSON)'
          end
          context 'ログイン中（削除予約済み）' do
            include_context 'ログイン処理', :destroy_reserved
            include_context 'ユーザー向けお知らせ作成'
            let(:expect_response) { { success: true, infomations: [expect_all_infomation] } } # NOTE: APIは未ログイン扱いの為

            it_behaves_like '正常なレスポンス(JSON)'
          end
          context 'APIログイン中' do
            include_context 'APIログイン処理'
            include_context 'ユーザー向けお知らせ作成'
            let(:expect_response) { { success: true, infomations: [expect_user_infomation, expect_all_infomation] } }

            it_behaves_like '正常なレスポンス(JSON)'
          end
          context 'APIログイン中（削除予約済み）' do
            include_context 'APIログイン処理', :destroy_reserved
            include_context 'ユーザー向けお知らせ作成'
            let(:expect_response) { { success: true, infomations: [expect_user_infomation, expect_all_infomation] } }

            it_behaves_like '正常なレスポンス(JSON)'
          end
        end
      end
    end
  end
end
