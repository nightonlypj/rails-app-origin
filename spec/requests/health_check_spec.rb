require 'rails_helper'

RSpec.describe 'HealthChecks', type: :request do
  # GET /_health ヘルスチェック
  # テストパターン
  #   正常, DBエラー
  #   パラメータがない, 対象: 存在しない, db, all
  describe 'GET #index' do
    subject { get health_check_path, params: }

    shared_context 'DB正常' do
      before { allow(ActiveRecord::Base.connection).to receive(:execute).with('SELECT 1').and_return(nil) }
    end
    shared_context 'DB異常' do
      before { allow(ActiveRecord::Base.connection).to receive(:execute).with('SELECT 1').and_raise(ActiveRecord::DatabaseConnectionError) }
    end

    # テスト内容
    shared_examples 'OK' do
      it 'HTTPステータスが200。OKが返却される' do
        is_expected.to eq(200)
        expect(response.body).to eq('OK')

        expect(ActiveRecord::Base.connection).not_to have_received(:execute)
      end
    end
    shared_examples 'OK(DB)' do
      it 'HTTPステータスが200。OKが返却される' do
        is_expected.to eq(200)
        expect(response.body).to eq('OK')

        expect(ActiveRecord::Base.connection).to have_received(:execute).once.with('SELECT 1')
      end
    end

    shared_examples 'NG(DB)' do
      it 'HTTPステータスが503。エラーメッセージが返却される' do
        is_expected.to eq(503)
        expect(response.body).to eq('ActiveRecord::DatabaseConnectionError')
      end
    end

    # テストケース
    context '正常' do
      include_context 'DB正常'

      context 'パラメータがない' do
        let(:params) { nil }

        it_behaves_like 'OK'
      end
      context '対象が存在しない' do
        let(:params) { { target: 'not' } }

        it_behaves_like 'OK'
      end
      context '対象がdb' do
        let(:params) { { target: 'db' } }

        it_behaves_like 'OK(DB)'
      end
      context '対象がall' do
        let(:params) { { target: 'all' } }

        it_behaves_like 'OK(DB)'
      end
    end
    context 'DBエラー' do
      include_context 'DB異常'

      context 'パラメータがない' do
        let(:params) { nil }

        it_behaves_like 'OK'
      end
      context '対象が存在しない' do
        let(:params) { { target: 'not' } }

        it_behaves_like 'OK'
      end
      context '対象がdb' do
        let(:params) { { target: 'db' } }

        it_behaves_like 'NG(DB)'
      end
      context '対象がall' do
        let(:params) { { target: 'all' } }

        it_behaves_like 'NG(DB)'
      end
    end
  end
end
