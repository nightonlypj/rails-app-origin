require 'rails_helper'

RSpec.describe 'top/index', type: :view do
  let!(:user) { FactoryBot.create(:user) }
  shared_context 'login' do
    before { login_user user }
  end

  shared_examples_for 'スペースが0件' do
    it 'もっと見るのパスが含まれない' do
      render
      expect(rendered).not_to match("\"#{Regexp.escape(spaces_path)}\"")
    end
    it 'スペース作成のパスが含まれる' do
      render
      expect(rendered).to match("\"#{Regexp.escape(new_space_path)}\"")
    end
  end

  context '未ログイン' do
    it_behaves_like 'スペースが0件'
  end

  context 'ログイン中' do
    include_context 'login'
    it_behaves_like 'スペースが0件'
  end

  space_limit = 10
  shared_context 'create_spaces' do
    before do
      @create_spaces = FactoryBot.create_list(:space, space_limit + 1)
      @new_spaces = Space.all.order(id: 'DESC').limit(space_limit)
    end
  end

  shared_examples_for "スペースが#{space_limit + 1}件" do
    it '1番新しいスペース名が含まれる' do
      render
      expect(rendered).to match(Regexp.escape(@create_spaces[space_limit].name))
    end
    it "#{space_limit}番目に新しいスペース名が含まれる" do
      render
      expect(rendered).to match(Regexp.escape(@create_spaces[1].name))
    end
    it "#{space_limit + 1}番目に新しいスペース名が含まれない" do
      render
      expect(rendered).not_to match(Regexp.escape(@create_spaces[0].name))
    end
    it '1番新しいスペースのパスが含まれる' do
      render
      expect(rendered).to match("//#{@create_spaces[space_limit].subdomain}.#{Settings['base_domain_link']}")
    end
    it "#{space_limit}番目に新しいスペースのパスが含まれる" do
      render
      expect(rendered).to match("//#{@create_spaces[1].subdomain}.#{Settings['base_domain_link']}")
    end
    it "#{space_limit + 1}番目に新しいスペースのパスが含まれない" do
      render
      expect(rendered).not_to match("//#{@create_spaces[0].subdomain}.#{Settings['base_domain_link']}")
    end
    it 'もっと見るのパスが含まれる' do
      render
      expect(rendered).to match("\"#{Regexp.escape(spaces_path)}\"")
    end
    it 'スペース作成のパスが含まれる' do
      render
      expect(rendered).to match("\"#{Regexp.escape(new_space_path)}\"")
    end
  end

  context '未ログイン' do
    include_context 'create_spaces'
    it_behaves_like "スペースが#{space_limit + 1}件"
  end

  context 'ログイン中' do
    include_context 'login'
    include_context 'create_spaces'
    it_behaves_like "スペースが#{space_limit + 1}件"
  end
end
