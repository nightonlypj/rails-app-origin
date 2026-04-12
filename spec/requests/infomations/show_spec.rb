require 'rails_helper'

RSpec.describe 'Infomations', type: :request do
  let(:response_parsed_body_sym) { response.parsed_body.deep_symbolize_keys }

  # お知らせ詳細・API
  # テストパターン
  #   URLの拡張子: ない, .json
  #   Acceptヘッダ: HTMLが含まれる, JSONが含まれる
  #   未ログイン, ログイン中, ログイン中（削除予約済み）, APIログイン中, APIログイン中（削除予約済み）
  #   対象: 全員, 自分, 他人
  #   開始日時: 過去, 未来
  #   終了日時: 過去, 未来, ない
  #   本文: ある, ない
  #   APIのみモード: true, false
  describe 'GET #show' do
    subject { get infomation_path(id: infomation.id, format: subject_format), headers: auth_headers.merge(accept_headers) }

    let_it_be(:valid_infomation) { FactoryBot.create(:infomation) }

    shared_context '有効な条件' do
      let(:infomation) { valid_infomation }
    end
    shared_context 'お知らせ作成' do
      let_it_be(:infomation) { FactoryBot.create(:infomation, started_at:, ended_at:, target:, user: infomation_user) }
    end
    shared_context 'お知らせ作成（本文がない）' do
      let_it_be(:infomation) { FactoryBot.create(:infomation, started_at:, ended_at:, target:, user: infomation_user, body: nil) }
    end

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
    shared_examples '対象なし(JSON)' do |alert_key = 'alert.page.notfound'|
      it 'HTTPステータスが404。対象項目が一致する' do
        is_expected.to eq(404)
        expect(response_parsed_body_sym).to eq(
          success: false,
          alert: get_locale(alert_key)
        )
      end
    end

    shared_examples '正常なレスポンス' do
      it 'HTTPステータスが200。対象項目が含まれる' do
        is_expected.to eq(200)
        # タイトル
        expect(response.body).to include(infomation.label_i18n)
        expect(response.body).to include(infomation.title)
        expect(response.body).to include(I18n.l(infomation.started_at.to_date))
        # 本文, サマリー
        expect(response.body).to include(infomation.body.presence || infomation.summary)
      end
    end
    shared_examples '正常なレスポンス(JSON)' do
      let(:expect_response) do
        {
          success: true,
          infomation: {
            label: infomation.label,
            label_i18n: infomation.label_i18n,
            title: infomation.title,
            summary: infomation.summary,
            body: infomation.body,
            started_at: I18n.l(started_at, format: :json),
            ended_at: I18n.l(ended_at, format: :json, default: nil),
            target: target.to_s
          }
        }
      end

      it 'HTTPステータスが200。対象項目が一致する' do
        is_expected.to eq(200)
        expect(response_parsed_body_sym).to eq(expect_response)
      end
    end

    context 'URLの拡張子がない' do
      let(:subject_format) { nil }
      include_context '未ログイン処理'
      include_context '有効な条件'

      shared_examples 'ログイン' do
        shared_examples 'APIのみモード（対象なし）' do
          context 'true' do
            before { allow(Settings).to receive(:api_only_mode).and_return(true) }

            it_behaves_like 'アクセス拒否'
          end
          context 'false' do
            before { allow(Settings).to receive(:api_only_mode).and_return(false) }

            it_behaves_like '対象なし'
          end
        end
        shared_examples 'APIのみモード（正常なレスポンス）' do
          context 'true' do
            before { allow(Settings).to receive(:api_only_mode).and_return(true) }

            it_behaves_like 'アクセス拒否'
          end
          context 'false' do
            before { allow(Settings).to receive(:api_only_mode).and_return(false) }

            it_behaves_like '正常なレスポンス'
          end
        end

        shared_examples '開始日時が未来' do
          let_it_be(:started_at) { 1.day.from_now }
          let_it_be(:ended_at) { nil }
          include_context 'お知らせ作成'

          it_behaves_like 'APIのみモード（対象なし）'
        end

        shared_examples '対象が全員' do
          let_it_be(:target) { :all }
          let_it_be(:infomation_user) { nil }

          context '開始日時が過去' do
            let_it_be(:started_at) { 1.day.ago }

            context '終了日時が過去' do
              let_it_be(:ended_at) { 1.day.ago }
              include_context 'お知らせ作成'

              it_behaves_like 'APIのみモード（対象なし）'
            end
            context '終了日時が未来' do
              let_it_be(:ended_at) { 1.day.from_now }

              context '本文がある' do
                include_context 'お知らせ作成'

                it_behaves_like 'APIのみモード（正常なレスポンス）'
              end
              context '本文がない' do
                include_context 'お知らせ作成（本文がない）'

                it_behaves_like 'APIのみモード（正常なレスポンス）'
              end
            end
            context '終了日時がない' do
              let_it_be(:ended_at) { nil }
              include_context 'お知らせ作成'

              it_behaves_like 'APIのみモード（正常なレスポンス）'
            end
          end
          it_behaves_like '開始日時が未来'
        end
        shared_examples '対象が他人' do
          let_it_be(:target) { :user }
          let_it_be(:infomation_user) { FactoryBot.create(:user) }

          context '開始日時が過去' do
            let_it_be(:started_at) { 1.day.ago }
            let_it_be(:ended_at) { nil }
            include_context 'お知らせ作成'

            it_behaves_like 'APIのみモード（対象なし）'
          end
          it_behaves_like '開始日時が未来'
        end
        shared_examples '対象が自分（ログイン中）' do
          let_it_be(:target) { :user }
          let_it_be(:infomation_user) { user }

          context '開始日時が過去' do
            let_it_be(:started_at) { 1.day.ago }

            context '終了日時が過去' do
              let_it_be(:ended_at) { 1.hour.ago }
              include_context 'お知らせ作成'

              it_behaves_like 'APIのみモード（対象なし）'
            end
            context '終了日時が未来' do
              let_it_be(:ended_at) { 1.hour.from_now }
              include_context 'お知らせ作成'

              it_behaves_like 'APIのみモード（正常なレスポンス）'
            end
            context '終了日時がない' do
              let_it_be(:ended_at) { nil }
              include_context 'お知らせ作成'

              it_behaves_like 'APIのみモード（正常なレスポンス）'
            end
          end
          it_behaves_like '開始日時が未来'
        end
        shared_examples '対象が自分（APIログイン中）' do
          let_it_be(:target) { :user }
          let_it_be(:infomation_user) { user }

          context '開始日時が過去' do
            let_it_be(:started_at) { 1.day.ago }

            context '終了日時が過去' do
              let_it_be(:ended_at) { 1.hour.ago }
              include_context 'お知らせ作成'

              it_behaves_like 'APIのみモード（対象なし）'
            end
            context '終了日時が未来' do
              let_it_be(:ended_at) { 1.hour.from_now }
              include_context 'お知らせ作成'

              it_behaves_like 'APIのみモード（正常なレスポンス）' # NOTE: HTMLもログイン状態になる
            end
            context '終了日時がない' do
              let_it_be(:ended_at) { nil }
              include_context 'お知らせ作成'

              it_behaves_like 'APIのみモード（正常なレスポンス）' # NOTE: HTMLもログイン状態になる
            end
          end
          it_behaves_like '開始日時が未来'
        end

        context '未ログイン' do
          include_context '未ログイン処理'

          it_behaves_like '対象が全員'
          it_behaves_like '対象が他人'
        end
        context 'ログイン中' do
          include_context 'ログイン処理'

          it_behaves_like '対象が全員'
          it_behaves_like '対象が自分（ログイン中）'
          it_behaves_like '対象が他人'
        end
        context 'ログイン中（削除予約済み）' do
          include_context 'ログイン処理', :destroy_reserved

          it_behaves_like '対象が全員'
          it_behaves_like '対象が自分（ログイン中）'
          it_behaves_like '対象が他人'
        end
        context 'APIログイン中' do
          include_context 'APIログイン処理'

          it_behaves_like '対象が全員'
          it_behaves_like '対象が自分（APIログイン中）'
          it_behaves_like '対象が他人'
        end
        context 'APIログイン中（削除予約済み）' do
          include_context 'APIログイン処理', :destroy_reserved

          it_behaves_like '対象が全員'
          it_behaves_like '対象が自分（APIログイン中）'
          it_behaves_like '対象が他人'
        end
      end

      context 'AcceptヘッダにHTMLが含まれる' do
        let(:accept_headers) { ACCEPT_INC_HTML }

        it_behaves_like 'ログイン'
      end
      context 'AcceptヘッダにJSONが含まれる' do
        let(:accept_headers) { ACCEPT_INC_JSON }

        it_behaves_like 'ログイン'
      end
    end
    context 'URLの拡張子が.json' do
      let(:subject_format) { :json }

      context 'AcceptヘッダにHTMLが含まれる' do
        let(:accept_headers) { ACCEPT_INC_HTML }
        include_context '未ログイン処理'
        include_context '有効な条件'

        it_behaves_like 'アクセス拒否'
      end
      context 'AcceptヘッダにJSONが含まれる' do
        let(:accept_headers) { ACCEPT_INC_JSON }

        shared_examples '開始日時が未来' do
          let_it_be(:started_at) { 1.day.from_now }
          let_it_be(:ended_at) { nil }
          include_context 'お知らせ作成'

          it_behaves_like '対象なし(JSON)'
        end

        shared_examples '対象が全員' do
          let_it_be(:target) { :all }
          let_it_be(:infomation_user) { nil }

          context '開始日時が過去' do
            let_it_be(:started_at) { 1.day.ago }

            context '終了日時が過去' do
              let_it_be(:ended_at) { 1.day.ago }
              include_context 'お知らせ作成'

              it_behaves_like '対象なし(JSON)', 'errors.messages.infomation.ended'
            end
            context '終了日時が未来' do
              let_it_be(:ended_at) { 1.day.from_now }

              context '本文がある' do
                include_context 'お知らせ作成'

                it_behaves_like '正常なレスポンス(JSON)'
              end
              context '本文がない' do
                include_context 'お知らせ作成（本文がない）'

                it_behaves_like '正常なレスポンス(JSON)'
              end
            end
            context '終了日時がない' do
              let_it_be(:ended_at) { nil }
              include_context 'お知らせ作成'

              it_behaves_like '正常なレスポンス(JSON)'
            end
          end
          it_behaves_like '開始日時が未来'
        end
        shared_examples '対象が他人' do
          let_it_be(:target) { :user }
          let_it_be(:infomation_user) { FactoryBot.create(:user) }

          context '開始日時が過去' do
            let_it_be(:started_at) { 1.day.ago }
            let_it_be(:ended_at) { nil }
            include_context 'お知らせ作成'

            it_behaves_like '対象なし(JSON)'
          end
          it_behaves_like '開始日時が未来'
        end
        shared_examples '対象が自分（ログイン中）' do
          let_it_be(:target) { :user }
          let_it_be(:infomation_user) { user }

          context '開始日時が過去' do
            let_it_be(:started_at) { 1.day.ago }
            let_it_be(:ended_at) { nil }
            include_context 'お知らせ作成'

            it_behaves_like '対象なし(JSON)' # NOTE: APIは未ログイン扱いの為、他人
          end
          it_behaves_like '開始日時が未来'
        end
        shared_examples '対象が自分（APIログイン中）' do
          let_it_be(:target) { :user }
          let_it_be(:infomation_user) { user }

          context '開始日時が過去' do
            let_it_be(:started_at) { 1.day.ago }

            context '終了日時が過去' do
              let_it_be(:ended_at) { 1.day.ago }
              include_context 'お知らせ作成'

              it_behaves_like '対象なし(JSON)', 'errors.messages.infomation.ended'
            end
            context '終了日時が未来' do
              let_it_be(:ended_at) { 1.day.from_now }
              include_context 'お知らせ作成'

              it_behaves_like '正常なレスポンス(JSON)'
            end
            context '終了日時がない' do
              let_it_be(:ended_at) { nil }
              include_context 'お知らせ作成'

              it_behaves_like '正常なレスポンス(JSON)'
            end
          end
          it_behaves_like '開始日時が未来'
        end

        context '未ログイン' do
          include_context '未ログイン処理'

          it_behaves_like '対象が全員'
          it_behaves_like '対象が他人'
        end
        context 'ログイン中' do
          include_context 'ログイン処理'

          it_behaves_like '対象が全員'
          it_behaves_like '対象が自分（ログイン中）'
          it_behaves_like '対象が他人'
        end
        context 'ログイン中（削除予約済み）' do
          include_context 'ログイン処理', :destroy_reserved

          it_behaves_like '対象が全員'
          it_behaves_like '対象が自分（ログイン中）'
          it_behaves_like '対象が他人'
        end
        context 'APIログイン中' do
          include_context 'APIログイン処理'

          it_behaves_like '対象が全員'
          it_behaves_like '対象が自分（APIログイン中）'
          it_behaves_like '対象が他人'
        end
        context 'APIログイン中（削除予約済み）' do
          include_context 'APIログイン処理', :destroy_reserved

          it_behaves_like '対象が全員'
          it_behaves_like '対象が自分（APIログイン中）'
          it_behaves_like '対象が他人'
        end
      end
    end
  end
end
