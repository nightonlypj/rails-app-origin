require 'rails_helper'

RSpec.describe Space, type: :model do
  describe 'validates subdomain' do
    subdomain_minimum = 1
    context "#{subdomain_minimum - 1}文字" do
      it 'NG' do
        space = FactoryBot.build(:space)
        space.subdomain = 'a' * (subdomain_minimum - 1)
        expect(space).not_to be_valid
      end
    end
    context "#{subdomain_minimum}文字" do
      it 'OK' do
        space = FactoryBot.build(:space)
        space.subdomain = 'a' * subdomain_minimum
        expect(space).to be_valid
      end
    end
    context '32文字' do
      it 'OK' do
        space = FactoryBot.build(:space)
        space.subdomain = 'a' * 32
        expect(space).to be_valid
      end
    end
    context '33文字' do
      it 'NG' do
        space = FactoryBot.build(:space)
        space.subdomain = 'a' * 33
        expect(space).not_to be_valid
      end
    end
    context 'アルファベット(小文字)・数字・ハイフン(先頭不可)' do
      it 'OK' do
        space = FactoryBot.build(:space)
        space.subdomain = 'a' * [subdomain_minimum - 4, 1].max + 'z09-'
        expect(space).to be_valid
      end
    end
    context 'アルファベット(大文字)' do
      it 'NG' do
        space = FactoryBot.build(:space)
        space.subdomain = 'A' * subdomain_minimum
        expect(space).not_to be_valid
      end
    end
    context 'ハイフン(先頭)' do
      it 'NG' do
        space = FactoryBot.build(:space)
        space.subdomain = '-' + 'a' * [subdomain_minimum - 1, 1].max
        expect(space).not_to be_valid
      end
    end
    context 'ハイフン(後尾)' do
      it 'OK' do
        space = FactoryBot.build(:space)
        space.subdomain = 'a' * [subdomain_minimum - 1, 1].max + '-'
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
    context '0文字' do
      it 'NG' do
        space = FactoryBot.build(:space)
        space.name = ''
        expect(space).not_to be_valid
      end
    end
    context '1文字' do
      it 'OK' do
        space = FactoryBot.build(:space)
        space.name = 'a'
        expect(space).to be_valid
      end
    end
    context '32文字' do
      it 'OK' do
        space = FactoryBot.build(:space)
        space.name = 'a' * 32
        expect(space).to be_valid
      end
    end
    context '33文字' do
      it 'NG' do
        space = FactoryBot.build(:space)
        space.name = 'a' * 33
        expect(space).not_to be_valid
      end
    end
  end
end
