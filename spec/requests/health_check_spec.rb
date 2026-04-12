require 'rails_helper'

RSpec.describe 'HealthChecks', type: :request do
  # ヘルスチェック
  # テストパターン
  #   正常, DBエラー
  #   パラメータ: ない, 対象: 存在しない, db, all
  describe 'GET #index' do
    subject { get health_check_path, params: }

    shared_context 'DB正常' do
      before { allow(ActiveRecord::Base.connection).to receive(:execute).with('SELECT 1').and_return(nil) }
    end
    shared_context 'DB異常' do
      before { allow(ActiveRecord::Base.connection).to receive(:execute).with('SELECT 1').and_raise(ActiveRecord::DatabaseConnectionError) }
    end

    shared_examples 'DB未チェックでOK' do
      it 'HTTPステータスが200。OKが返る' do
        is_expected.to eq(200)
        expect(response.body).to eq('OK')

        expect(ActiveRecord::Base.connection).not_to have_received(:execute)
      end
    end
    shared_examples 'DBチェックでOK' do
      it 'HTTPステータスが200。OKが返る' do
        is_expected.to eq(200)
        expect(response.body).to eq('OK')

        expect(ActiveRecord::Base.connection).to have_received(:execute).with('SELECT 1')
        expect(ActiveRecord::Base.connection).to have_received(:execute).once
      end
    end

    shared_examples 'DBチェックでNG' do
      it 'HTTPステータスが503。エラーメッセージが返る' do
        is_expected.to eq(503)
        expect(response.body).to eq('ActiveRecord::DatabaseConnectionError')

        expect(ActiveRecord::Base.connection).to have_received(:execute).with('SELECT 1')
        expect(ActiveRecord::Base.connection).to have_received(:execute).once
      end
    end

    context '正常' do
      include_context 'DB正常'

      context 'パラメータがない' do
        let(:params) { nil }

        it_behaves_like 'DB未チェックでOK'
      end
      context 'パラメータの対象が存在しない' do
        let(:params) { { target: 'not' } }

        it_behaves_like 'DB未チェックでOK'
      end
      context 'パラメータの対象がdb' do
        let(:params) { { target: 'db' } }

        it_behaves_like 'DBチェックでOK'
      end
      context 'パラメータの対象がall' do
        let(:params) { { target: 'all' } }

        it_behaves_like 'DBチェックでOK'
      end
    end
    context 'DBエラー' do
      include_context 'DB異常'

      context 'パラメータがない' do
        let(:params) { nil }

        it_behaves_like 'DB未チェックでOK'
      end
      context 'パラメータの対象が存在しない' do
        let(:params) { { target: 'not' } }

        it_behaves_like 'DB未チェックでOK'
      end
      context 'パラメータの対象がdb' do
        let(:params) { { target: 'db' } }

        it_behaves_like 'DBチェックでNG'
      end
      context 'パラメータの対象がall' do
        let(:params) { { target: 'all' } }

        it_behaves_like 'DBチェックでNG'
      end
    end
  end
end
