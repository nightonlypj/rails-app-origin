require 'rake_helper'

RSpec.describe User do
  # 削除予定日時を過ぎたユーザーのアカウントを削除
  describe 'user:destroy' do
    let!(:task) { Rake.application['user:destroy'] }
    let!(:dry_run) { 'false' }

    context '2件（削除予約1件、削除対象0件）' do
      before(:each) do
        FactoryBot.create(:user)
        FactoryBot.create(:user, destroy_schedule_at: Time.current + Settings['destroy_schedule_days'].days - 1.hour)
      end
      it 'ユーザーが削除されない' do
        expect do
          expect(task.invoke(dry_run)).to be_truthy
        end.to change(User, :count).by(0)
      end
    end

    context '3件（削除予約1件、削除対象1件）' do
      before(:each) do
        FactoryBot.create(:user)
        FactoryBot.create(:user, destroy_schedule_at: Time.current + Settings['destroy_schedule_days'].days - 1.hour)
        FactoryBot.create(:user, destroy_schedule_at: Time.current - Settings['destroy_schedule_days'].days - 1.second)
      end
      it 'ユーザーが1件削除される' do
        expect do
          expect(task.invoke(dry_run)).to be_truthy
        end.to change(User, :count).by(-1)
      end
    end

    context '4件（削除予約1件、削除対象2件）' do
      before(:each) do
        FactoryBot.create(:user)
        FactoryBot.create(:user, destroy_schedule_at: Time.current + Settings['destroy_schedule_days'].days - 1.hour)
        FactoryBot.create(:user, destroy_schedule_at: Time.current - Settings['destroy_schedule_days'].days - 1.second)
        FactoryBot.create(:user, destroy_schedule_at: Time.current - Settings['destroy_schedule_days'].days - 1.hour)
      end
      it 'ユーザーが2件削除される' do
        expect do
          expect(task.invoke(dry_run)).to be_truthy
        end.to change(User, :count).by(-2)
      end
    end
  end
end
