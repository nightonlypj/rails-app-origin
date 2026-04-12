require 'rails_helper'

RSpec.describe 'Top', type: :request do
  # トップページ
  # テストパターン
  #   URLの拡張子: ない, .json
  #   Acceptヘッダ: HTMLが含まれる, JSONが含まれる
  #   APIのみモード: true, false
  #   大切なお知らせ: ない, ある
  #     地域: 全て, 一致, 不一致
  #     対象: 全員, 自分, 他人
  #     強制表示期間: 未設定, 期間内, 終了, 前
  #   未ログイン, ログイン中, ログイン中（削除予約済み）, APIログイン中, APIログイン中（削除予約済み）
  describe 'GET #index' do
    subject { get root_path(format: subject_format), headers: auth_headers.merge(accept_headers) }

    shared_examples 'アクセス拒否' do
      it 'HTTPステータスが406' do
        is_expected.to eq(406)
        expect(response.body).to eq('')
      end
    end
    shared_examples '対象なし' do
      it 'HTTPステータスが404' do
        is_expected.to eq(404)
        expect(response.body).to eq('')
      end
    end

    shared_examples '正常なレスポンス' do
      it 'HTTPステータスが200。対象項目が含まれる' do
        is_expected.to eq(200)
        expect(response.body).to include(get_locale('大切なお知らせ'))

        inside_infomations.each do |infomation|
          expect(response.body).to include(infomation.label_i18n)
          expect(response.body).to include(infomation.title)
          expect(response.body).to include("href=\"#{infomation_path(infomation)}\"")
          expect(response.body).to include(I18n.l(infomation.started_at.to_date))
        end
        outside_infomations.each do |infomation|
          expect(response.body).not_to include(infomation.title)
        end
      end
    end

    context 'URLの拡張子がない' do
      let(:subject_format) { nil }

      shared_examples 'APIのみモード' do
        context 'true' do
          before { allow(Settings).to receive(:api_only_mode).and_return(true) }
          include_context '未ログイン処理'

          it_behaves_like '対象なし'
        end
        context 'false' do
          before { allow(Settings).to receive(:api_only_mode).and_return(false) }

          context '大切なお知らせがない' do
            include_context '未ログイン処理'

            it 'HTTPステータスが200。対象項目が一致する' do
              is_expected.to eq(200)
              expect(response.body).not_to include(get_locale('大切なお知らせ'))
            end
          end
          context '大切なお知らせがある' do
            let_it_be(:inside_base_infomation) { FactoryBot.create(:infomation, :all_locale, :all, :force_period_inside, title: '対象が全員') }
            let_it_be(:outside_base_infomations) do
              [
                FactoryBot.create(:infomation, :other_locale, :all, :force_period_inside, title: '地域が不一致'),
                FactoryBot.create(:infomation, :my_locale, :user, :force_period_inside, title: '対象が他人'),
                FactoryBot.create(:infomation, :my_locale, :all, :force_period_not_set, title: '強制表示期間が未設定'),
                FactoryBot.create(:infomation, :my_locale, :all, :force_period_finished, title: '強制表示期間が終了'),
                FactoryBot.create(:infomation, :my_locale, :all, :force_period_before, title: '強制表示期間が前')
              ]
            end
            shared_context 'ユーザー向けお知らせ作成' do
              let_it_be(:user_infomation) { FactoryBot.create(:infomation, :my_locale, :user, :force_period_inside, user:, title: '対象がユーザー') }
            end

            context '未ログイン' do
              include_context '未ログイン処理'
              let(:inside_infomations) { [inside_base_infomation] }
              let(:outside_infomations) { outside_base_infomations }

              it_behaves_like '正常なレスポンス'
            end
            context 'ログイン中' do
              include_context 'ログイン処理'
              include_context 'ユーザー向けお知らせ作成'
              let(:inside_infomations) { [inside_base_infomation, user_infomation] }
              let(:outside_infomations) { outside_base_infomations }

              it_behaves_like '正常なレスポンス'
            end
            context 'ログイン中（削除予約済み）' do
              include_context 'ログイン処理', :destroy_reserved
              include_context 'ユーザー向けお知らせ作成'
              let(:inside_infomations) { [inside_base_infomation, user_infomation] }
              let(:outside_infomations) { outside_base_infomations }

              it_behaves_like '正常なレスポンス'
            end
            context 'APIログイン中' do
              include_context 'APIログイン処理'
              include_context 'ユーザー向けお知らせ作成'
              let(:inside_infomations) { [inside_base_infomation] }
              let(:outside_infomations) { outside_base_infomations + [user_infomation] } # NOTE: APIは未ログイン扱いの為

              it_behaves_like '正常なレスポンス'
            end
            context 'APIログイン中（削除予約済み）' do
              include_context 'APIログイン処理', :destroy_reserved
              include_context 'ユーザー向けお知らせ作成'
              let(:inside_infomations) { [inside_base_infomation] }
              let(:outside_infomations) { outside_base_infomations + [user_infomation] } # NOTE: APIは未ログイン扱いの為

              it_behaves_like '正常なレスポンス'
            end
          end
        end
      end

      context 'AcceptヘッダにHTMLが含まれる' do
        let(:accept_headers) { ACCEPT_INC_HTML }

        it_behaves_like 'APIのみモード'
      end
      context 'AcceptヘッダにJSONが含まれる' do
        let(:accept_headers) { ACCEPT_INC_JSON }

        it_behaves_like 'APIのみモード'
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
        include_context '未ログイン処理'

        it_behaves_like 'アクセス拒否'
      end
    end
  end
end
