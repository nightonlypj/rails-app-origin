require 'rails_helper'

RSpec.describe Space, type: :model do
  describe 'validates subdomain' do
    context "#{Settings['subdomain_minimum'] - 1}文字" do
      it 'NG' do
        space = FactoryBot.build(:space)
        space.subdomain = 'a' * (Settings['subdomain_minimum'] - 1)
        expect(space).not_to be_valid
      end
    end
    context "#{Settings['subdomain_minimum']}文字" do
      it 'OK' do
        space = FactoryBot.build(:space)
        space.subdomain = 'a' * Settings['subdomain_minimum']
        expect(space).to be_valid
      end
    end
    context "#{Settings['subdomain_maximum']}文字" do
      it 'OK' do
        space = FactoryBot.build(:space)
        space.subdomain = 'a' * Settings['subdomain_maximum']
        expect(space).to be_valid
      end
    end
    context "#{Settings['subdomain_maximum'] + 1}文字" do
      it 'NG' do
        space = FactoryBot.build(:space)
        space.subdomain = 'a' * (Settings['subdomain_maximum'] + 1)
        expect(space).not_to be_valid
      end
    end
    context 'アルファベット(小文字)・数字・ハイフン(先頭不可)' do
      it 'OK' do
        space = FactoryBot.build(:space)
        space.subdomain = 'a' * [Settings['subdomain_minimum'] - 4, 1].max + 'z09-'
        expect(space).to be_valid
      end
    end
    context 'アルファベット(大文字)' do
      it 'NG' do
        space = FactoryBot.build(:space)
        space.subdomain = 'A' * Settings['subdomain_minimum']
        expect(space).not_to be_valid
      end
    end
    context 'ハイフン(先頭)' do
      it 'NG' do
        space = FactoryBot.build(:space)
        space.subdomain = '-' + 'a' * [Settings['subdomain_minimum'] - 1, 1].max
        expect(space).not_to be_valid
      end
    end
    context 'ハイフン(後尾)' do
      it 'OK' do
        space = FactoryBot.build(:space)
        space.subdomain = 'a' * [Settings['subdomain_minimum'] - 1, 1].max + '-'
        expect(space).to be_valid
      end
    end
    context '重複' do
      it 'NG' do
        space1 = FactoryBot.create(:space)
        space2 = FactoryBot.build(:space)
        space2.subdomain = space1.subdomain
        expect(space2).not_to be_valid
      end
    end
  end

  describe 'validates name' do
    context "#{Settings['space_name_minimum'] - 1}文字" do
      it 'NG' do
        space = FactoryBot.build(:space)
        space.name = 'a' * (Settings['space_name_minimum'] - 1)
        expect(space).not_to be_valid
      end
    end
    context "#{Settings['space_name_minimum']}文字" do
      it 'OK' do
        space = FactoryBot.build(:space)
        space.name = 'a' * Settings['space_name_minimum']
        expect(space).to be_valid
      end
    end
    context "#{Settings['space_name_maximum']}文字" do
      it 'OK' do
        space = FactoryBot.build(:space)
        space.name = 'a' * Settings['space_name_maximum']
        expect(space).to be_valid
      end
    end
    context "#{Settings['space_name_maximum'] + 1}文字" do
      it 'NG' do
        space = FactoryBot.build(:space)
        space.name = 'a' * (Settings['space_name_maximum'] + 1)
        expect(space).not_to be_valid
      end
    end
  end
end
