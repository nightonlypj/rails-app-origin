require 'rails_helper'

RSpec.describe 'Infomations', type: :request do
  let(:response_parsed_body_sym) { response.parsed_body.deep_symbolize_keys }

  # お知らせ一覧・API
  # テストパターン
  #   URLの拡張子: ない, .json
  #   Acceptヘッダ: HTMLが含まれる, JSONが含まれる
  #   APIのみモード: true, false
  #   未ログイン, ログイン中, ログイン中（削除予約済み）, APIログイン中, APIログイン中（削除予約済み）
  #   お知らせ: ない, ある
  #     地域: 全て, 一致, 不一致
  #     対象: 全員, 自分, 他人
  #     表示期間: 期間内, 終了, 前
  #     本文: ある, ない
  #   一覧: 最大表示数と同じ, 最大表示数より多い
  #   ページ: 1, 2
  describe 'GET #index' do
    subject { get infomations_path(page: subject_page, format: subject_format), headers: auth_headers.merge(accept_headers) }
    let(:subject_page) { 1 }

    let_it_be(:outside_base_infomations) do
      [
        FactoryBot.create(:infomation, :other_locale, :all, :period_inside, title: '地域が不一致'),
        FactoryBot.create(:infomation, :my_locale, :user, :period_inside, title: '対象が他人'),
        FactoryBot.create(:infomation, :my_locale, :all, :period_finished, title: '強制表示期間が終了'),
        FactoryBot.create(:infomation, :my_locale, :all, :period_before, title: '強制表示期間が前')
      ]
    end
    shared_context 'お知らせ作成' do
      let_it_be(:inside_base_infomation) do
        FactoryBot.create(:infomation, :all_locale, :all, :period_inside, started_at: 1.minute.ago, title: '対象が全員', body: '本文')
      end
      let_it_be(:user_infomation) do
        FactoryBot.create(:infomation, :my_locale, :user, :period_inside, user:, started_at: 1.second.ago, title: '対象がユーザー', body: nil) if user.present?
      end
    end

    shared_examples 'アクセス拒否' do
      it 'HTTPステータスが406' do
        is_expected.to eq(406)
        expect(response.body).to eq('')
      end
    end

    shared_examples '正常なレスポンス' do |link_page: nil, not_link_page: nil|
      it 'HTTPステータスが200。対象項目が一致する' do
        is_expected.to eq(200)
        expect(response.body).to include("\"#{infomations_path(page: link_page == 1 ? nil : link_page)}\"") if link_page.present?
        expect(response.body).not_to include("\"#{infomations_path(page: not_link_page)}\"") if not_link_page.present?

        expect_display_infomations.each do |infomation|
          # タイトル
          expect(response.body).to include(infomation.label_i18n)
          url = "href=\"#{infomation_path(infomation)}\""
          if infomation.body.present?
            expect(response.body).to include(url)
          else
            expect(response.body).not_to include(url)
          end
          expect(response.body).to include(infomation.title)
          expect(response.body).to include(I18n.l(infomation.started_at.to_date))
          # 概要
          expect(response.body).to include(infomation.summary) if infomation.summary.present?
        end
        expect_hidden_infomations.each do |infomation|
          expect(response.body).not_to include(infomation.title)
        end
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

      shared_examples 'APIのみモード' do
        context 'true' do
          before { allow(Settings).to receive(:api_only_mode).and_return(true) }
          include_context '未ログイン処理'

          it_behaves_like 'アクセス拒否'
        end
        context 'false' do
          before { allow(Settings).to receive(:api_only_mode).and_return(false) }

          shared_examples 'お知らせ' do |expect_user:|
            context 'ない' do
              it 'HTTPステータスが200。対象項目が一致する' do
                is_expected.to eq(200)
                expect(response.body).to include(I18n.t('%{name}はありません。', name: I18n.t('お知らせ')))
              end
            end
            context 'ある' do
              include_context 'お知らせ作成'
              let(:inside_infomations) do
                if expect_user
                  [user_infomation, inside_base_infomation]
                else
                  [inside_base_infomation]
                end
              end
              let(:outside_infomations) { outside_base_infomations + ([user_infomation, inside_base_infomation].compact - inside_infomations) }

              context '一覧が最大表示数と同じ' do
                before { allow(Settings).to receive(:default_infomations_limit).and_return(inside_infomations.count) }

                context 'ページが1' do
                  let(:expect_display_infomations) { inside_infomations }
                  let(:expect_hidden_infomations) { outside_infomations }

                  it_behaves_like '正常なレスポンス', not_link_page: 2
                end
                context 'ページが2' do
                  let(:subject_page) { 2 }
                  let(:expect_display_infomations) { [] }
                  let(:expect_hidden_infomations) { inside_infomations + outside_infomations }

                  it '最終ページにリダイレクトする' do
                    is_expected.to redirect_to(infomations_path(page: nil))
                  end
                end
              end
              context '一覧が最大表示数より多い' do
                next unless expect_user # NOTE: per(limit_value)が0になる為

                before { allow(Settings).to receive(:default_infomations_limit).and_return(inside_infomations.count - 1) }

                context 'ページが1' do
                  let(:expect_display_infomations) { inside_infomations[0..-2] }
                  let(:expect_hidden_infomations) { inside_infomations[-1..] + outside_infomations }

                  it_behaves_like '正常なレスポンス', link_page: 2
                end
                context 'ページが2' do
                  let(:subject_page) { 2 }
                  let(:expect_display_infomations) { inside_infomations[-1..] }
                  let(:expect_hidden_infomations) { inside_infomations[0..-2] + outside_infomations }

                  it_behaves_like '正常なレスポンス', link_page: 1
                end
              end
            end
          end

          context '未ログイン' do
            include_context '未ログイン処理'

            it_behaves_like 'お知らせ', expect_user: false
          end
          context 'ログイン中' do
            include_context 'ログイン処理'

            it_behaves_like 'お知らせ', expect_user: true
          end
          context 'ログイン中（削除予約済み）' do
            include_context 'ログイン処理', :destroy_reserved

            it_behaves_like 'お知らせ', expect_user: true
          end
          context 'APIログイン中' do
            include_context 'APIログイン処理'

            it_behaves_like 'お知らせ', expect_user: true
          end
          context 'APIログイン中（削除予約済み）' do
            include_context 'APIログイン処理', :destroy_reserved

            it_behaves_like 'お知らせ', expect_user: true
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
        include_context 'APIログイン処理'

        it_behaves_like 'アクセス拒否'
      end
      context 'AcceptヘッダにJSONが含まれる' do
        let(:accept_headers) { ACCEPT_INC_JSON }

        shared_examples 'お知らせ' do |expect_user:|
          context 'ない' do
            let(:expect_response) do
              {
                success: true,
                infomation: {
                  total_count: 0,
                  current_page: 1,
                  total_pages: 0,
                  limit_value: Settings.default_infomations_limit
                },
                infomations: []
              }
            end

            it_behaves_like '正常なレスポンス(JSON)'
          end
          context 'ある' do
            include_context 'お知らせ作成'
            let(:expect_all_infomation) do
              {
                id: inside_base_infomation.id,
                label: inside_base_infomation.label,
                label_i18n: inside_base_infomation.label_i18n,
                title: '対象が全員',
                summary: inside_base_infomation.summary,
                body_present: true,
                started_at: I18n.l(inside_base_infomation.started_at, format: :json),
                ended_at: I18n.l(inside_base_infomation.ended_at, format: :json, default: nil),
                target: inside_base_infomation.target
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
                target: user_infomation.target
              }
            end
            let(:expect_infomations) do
              if expect_user
                [expect_user_infomation, expect_all_infomation]
              else
                [expect_all_infomation]
              end
            end

            context '一覧が最大表示数と同じ' do
              before { allow(Settings).to receive(:default_infomations_limit).and_return(expect_infomations.count) }

              context 'ページが1' do
                let(:expect_response) do
                  {
                    success: true,
                    infomation: {
                      total_count: expect_infomations.count,
                      current_page: 1,
                      total_pages: 1,
                      limit_value: expect_infomations.count
                    },
                    infomations: expect_infomations
                  }
                end

                it_behaves_like '正常なレスポンス(JSON)'
              end
              context 'ページが2' do
                let(:subject_page) { 2 }
                let(:expect_response) do
                  {
                    success: true,
                    infomation: {
                      total_count: expect_infomations.count,
                      current_page: 2,
                      total_pages: 1,
                      limit_value: expect_infomations.count
                    },
                    infomations: []
                  }
                end

                it_behaves_like '正常なレスポンス(JSON)'
              end
            end
            context '一覧が最大表示数より多い' do
              next unless expect_user # NOTE: per(limit_value)が0になる為

              before { allow(Settings).to receive(:default_infomations_limit).and_return(expect_infomations.count - 1) }

              context 'ページが1' do
                let(:expect_response) do
                  {
                    success: true,
                    infomation: {
                      total_count: expect_infomations.count,
                      current_page: 1,
                      total_pages: 2,
                      limit_value: expect_infomations.count - 1
                    },
                    infomations: expect_infomations[0..-2]
                  }
                end

                it_behaves_like '正常なレスポンス(JSON)'
              end
              context 'ページが2' do
                let(:subject_page) { 2 }
                let(:expect_response) do
                  {
                    success: true,
                    infomation: {
                      total_count: expect_infomations.count,
                      current_page: 2,
                      total_pages: 2,
                      limit_value: expect_infomations.count - 1
                    },
                    infomations: expect_infomations[-1..]
                  }
                end

                it_behaves_like '正常なレスポンス(JSON)'
              end
            end
          end
        end

        context '未ログイン' do
          include_context '未ログイン処理'

          it_behaves_like 'お知らせ', expect_user: false
        end
        context 'ログイン中' do
          include_context 'ログイン処理'

          it_behaves_like 'お知らせ', expect_user: false # NOTE: APIは未ログイン扱いの為
        end
        context 'ログイン中（削除予約済み）' do
          include_context 'ログイン処理', :destroy_reserved

          it_behaves_like 'お知らせ', expect_user: false # NOTE: APIは未ログイン扱いの為
        end
        context 'APIログイン中' do
          include_context 'APIログイン処理'

          it_behaves_like 'お知らせ', expect_user: true
        end
        context 'APIログイン中（削除予約済み）' do
          include_context 'APIログイン処理', :destroy_reserved

          it_behaves_like 'お知らせ', expect_user: true
        end
      end
    end
  end
end
