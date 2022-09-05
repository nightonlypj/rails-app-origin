require 'rails_helper'

RSpec.describe 'Spaces', type: :request do
  # GET /spaces スペース一覧
  # GET /spaces(.json) スペース一覧API
  # 前提条件
  #   検索条件なし
  # テストパターン
  #   未ログイン, ログイン中, ログイン中（削除予約済み）, APIログイン中, APIログイン中（削除予約済み）
  #   スペース: ない, 最大表示数と同じ, 最大表示数より多い
  #   ＋URLの拡張子: ない, .json
  #   ＋Acceptヘッダ: HTMLが含まれる, JSONが含まれる
  describe 'GET #index' do
    subject { get spaces_path(page: subject_page, format: subject_format), headers: auth_headers.merge(accept_headers) }

    # テスト内容
    shared_examples_for 'ToOK(html)' do
      let(:subject_format) { nil }
      it 'HTTPステータスが200' do
        is_expected.to eq(200)
      end
    end

    shared_examples_for 'ToOK(html/html)' do
      let(:accept_headers) { ACCEPT_INC_HTML }
      it_behaves_like 'ToOK(html)'
    end
    shared_examples_for 'ToOK(html/json)' do
      let(:accept_headers) { ACCEPT_INC_JSON }
      it_behaves_like 'ToOK(html)'
    end
    shared_examples_for 'ToOK(json/json)' do
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      it 'HTTPステータスが200。対象項目が一致する' do
        is_expected.to eq(200)
        expect(JSON.parse(response.body)['success']).to eq(true)

        response_json = JSON.parse(response.body)['space']
        expect(response_json['total_count']).to eq(spaces.count) # 全件数
        expect(response_json['current_page']).to eq(subject_page) # 現在ページ
        expect(response_json['total_pages']).to eq((spaces.count - 1).div(Settings['default_spaces_limit']) + 1) # 全ページ数
        expect(response_json['limit_value']).to eq(Settings['default_spaces_limit']) # 最大表示件数
      end
    end

    shared_examples_for 'ToOK' do |page|
      let(:subject_page) { page }
      it_behaves_like 'ToOK(html/html)'
      it_behaves_like 'ToOK(html/json)'
    end
    shared_examples_for 'ToOK(json)' do |page|
      let(:subject_page) { page }
      it_behaves_like 'To406(json/html)'
      it_behaves_like 'ToOK(json/json)'
    end

    shared_examples_for 'ページネーション表示' do |page, link_page|
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      let(:subject_page) { page }
      let(:url_page)     { link_page >= 2 ? link_page : nil }
      it "#{link_page}ページのパスが含まれる" do
        subject
        expect(response.body).to include("\"#{spaces_path(page: url_page)}\"")
      end
    end
    shared_examples_for 'ページネーション非表示' do |page, link_page|
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      let(:subject_page) { page }
      let(:url_page)     { link_page >= 2 ? link_page : nil }
      it "#{link_page}ページのパスが含まれない" do
        subject
        expect(response.body).not_to include("\"#{spaces_path(page: url_page)}\"")
      end
    end

    shared_examples_for 'リスト表示' do |page|
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      let(:subject_page) { page }
      let(:start_no)     { (Settings['default_spaces_limit'] * (page - 1)) + 1 }
      let(:end_no)       { [@user_spaces.count, Settings['default_spaces_limit'] * page].min }
      it '対象項目が含まれる' do
        subject
        (start_no..end_no).each do |no|
          space = @user_spaces[@user_spaces.count - no]
          expect(response.body).to include(space.image_url(:small))
          expect(response.body).to include(space.name)
          expect(response.body).to include(space.description)
          expect(response.body).to include('非公開') if space.private
          expect(response.body).to include(I18n.l(space.destroy_schedule_at.to_date)) if space.destroy_reserved?
          expect(response.body).to include(Member.powers_i18n[members[space.id]]) if members[space.id].present?
        end
      end
    end
    shared_examples_for 'リスト表示(json)' do |page|
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      let(:subject_page) { page }
      let(:start_no)     { (Settings['default_spaces_limit'] * (page - 1)) + 1 }
      let(:end_no)       { [spaces.count, Settings['default_spaces_limit'] * page].min }
      it '件数・対象項目が一致する' do
        subject
        response_json = JSON.parse(response.body)['spaces']
        expect(response_json.count).to eq(end_no - start_no + 1)
        (start_no..end_no).each do |no|
          data = response_json[no - start_no]
          space = spaces[spaces.count - no]
          expect(data['code']).to eq(space.code)
          expect(data['image_url']['mini']).to eq("#{Settings['base_image_url']}#{space.image_url(:mini)}")
          expect(data['image_url']['small']).to eq("#{Settings['base_image_url']}#{space.image_url(:small)}")
          expect(data['image_url']['medium']).to eq("#{Settings['base_image_url']}#{space.image_url(:medium)}")
          expect(data['image_url']['large']).to eq("#{Settings['base_image_url']}#{space.image_url(:large)}")
          expect(data['image_url']['xlarge']).to eq("#{Settings['base_image_url']}#{space.image_url(:xlarge)}")
          expect(data['name']).to eq(space.name)
          expect(data['description']).to eq(space.description)
          expect(data['private']).to eq(space.private)
          destroy_requested_at = space.destroy_requested_at.present? ? I18n.l(space.destroy_requested_at, format: :json) : nil
          expect(data['destroy_requested_at']).to eq(destroy_requested_at)
          destroy_schedule_at = space.destroy_schedule_at.present? ? I18n.l(space.destroy_schedule_at, format: :json) : nil
          expect(data['destroy_schedule_at']).to eq(destroy_schedule_at)
          power = members[space.id]
          if power.blank?
            expect(data['member']).to be_nil
          else
            expect(data['member']['power']).to eq(power)
            expect(data['member']['power_i18n']).to eq(Member.powers_i18n[power])
          end
        end
      end
    end

    shared_examples_for 'リダイレクト' do |page, redirect_page|
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      let(:subject_page) { page }
      let(:url_page)     { redirect_page >= 2 ? redirect_page : nil }
      it '最終ページにリダイレクトする' do
        is_expected.to redirect_to(spaces_path(page: url_page))
      end
    end
    shared_examples_for 'リダイレクト(json)' do |page|
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      let(:subject_page) { page }
      it 'リダイレクトしない' do
        is_expected.to eq(200)
      end
    end

    # テストケース
    shared_examples_for '[*]スペースがない' do
      include_context 'スペース一覧作成', 0, 0, 0, 0
      it_behaves_like 'ToOK', 1
      it_behaves_like 'ページネーション非表示', 1, 2
      it_behaves_like 'リダイレクト', 2, 1
      it_behaves_like 'ToOK(json)', 1
      it_behaves_like 'リダイレクト(json)', 2
    end
    shared_examples_for '[未ログイン]スペースが最大表示数と同じ' do
      count = Settings['test_spaces']
      include_context 'スペース一覧作成', 0, count['public_admin_count'] + count['public_none_count'] + count['private_admin_count'] + count['private_reader_count'], 0, 0
      it_behaves_like 'ToOK', 1
      it_behaves_like 'ページネーション非表示', 1, 2
      it_behaves_like 'リスト表示', 1
      it_behaves_like 'リダイレクト', 2, 1
      it_behaves_like 'ToOK(json)', 1
      it_behaves_like 'リスト表示(json)', 1
      it_behaves_like 'リダイレクト(json)', 2
    end
    shared_examples_for '[ログイン中/削除予約済み]スペースが最大表示数と同じ' do
      count = Settings['test_spaces']
      include_context 'スペース一覧作成', count['public_admin_count'], count['public_none_count'], count['private_admin_count'], count['private_reader_count']
      it_behaves_like 'ToOK', 1
      it_behaves_like 'ページネーション非表示', 1, 2
      it_behaves_like 'リスト表示', 1
      it_behaves_like 'リダイレクト', 2, 1
      it_behaves_like 'ToOK(json)', 1
      it_behaves_like 'リスト表示(json)', 1
      it_behaves_like 'リダイレクト(json)', 2
    end
    shared_examples_for '[APIログイン中/削除予約済み]スペースが最大表示数と同じ' do
      count = Settings['test_spaces']
      include_context 'スペース一覧作成', count['public_admin_count'], count['public_none_count'], count['private_admin_count'], count['private_reader_count']
      it_behaves_like 'ToOK', 1
      it_behaves_like 'ページネーション非表示', 1, 2
      it_behaves_like 'リスト表示', 1
      it_behaves_like 'リダイレクト', 2, 1
      it_behaves_like 'ToOK(json)', 1
      it_behaves_like 'リスト表示(json)', 1
      it_behaves_like 'リダイレクト(json)', 2
    end
    shared_examples_for '[未ログイン]スペースが最大表示数より多い' do
      count = Settings['test_spaces']
      include_context 'スペース一覧作成', 0, count['public_admin_count'] + count['public_none_count'] + count['private_admin_count'] + count['private_reader_count'] + 1, 0, 0
      it_behaves_like 'ToOK', 1
      it_behaves_like 'ToOK', 2
      it_behaves_like 'ページネーション表示', 1, 2
      it_behaves_like 'ページネーション表示', 2, 1
      it_behaves_like 'リスト表示', 1
      it_behaves_like 'リスト表示', 2
      it_behaves_like 'リダイレクト', 3, 2
      it_behaves_like 'ToOK(json)', 1
      it_behaves_like 'ToOK(json)', 2
      it_behaves_like 'リスト表示(json)', 1
      it_behaves_like 'リスト表示(json)', 2
      it_behaves_like 'リダイレクト(json)', 3
    end
    shared_examples_for '[ログイン中/削除予約済み]スペースが最大表示数より多い' do
      count = Settings['test_spaces']
      include_context 'スペース一覧作成', count['public_admin_count'], count['public_none_count'] + 1, count['private_admin_count'], count['private_reader_count']
      it_behaves_like 'ToOK', 1
      it_behaves_like 'ToOK', 2
      it_behaves_like 'ページネーション表示', 1, 2
      it_behaves_like 'ページネーション表示', 2, 1
      it_behaves_like 'リスト表示', 1
      it_behaves_like 'リスト表示', 2
      it_behaves_like 'リダイレクト', 3, 2
      # it_behaves_like 'ToOK(json)', 1 # Tips: APIは未ログイン扱いの為
      # it_behaves_like 'ToOK(json)', 2
      # it_behaves_like 'リスト表示(json)', 1
      # it_behaves_like 'リスト表示(json)', 2
      # it_behaves_like 'リダイレクト(json)', 3
    end
    shared_examples_for '[APIログイン中/削除予約済み]スペースが最大表示数より多い' do
      count = Settings['test_spaces']
      include_context 'スペース一覧作成', count['public_admin_count'], count['public_none_count'] + 1, count['private_admin_count'], count['private_reader_count']
      it_behaves_like 'ToOK', 1
      it_behaves_like 'ToOK', 2
      it_behaves_like 'ページネーション表示', 1, 2
      it_behaves_like 'ページネーション表示', 2, 1
      it_behaves_like 'リスト表示', 1
      it_behaves_like 'リスト表示', 2
      it_behaves_like 'リダイレクト', 3, 2
      it_behaves_like 'ToOK(json)', 1
      it_behaves_like 'ToOK(json)', 2
      it_behaves_like 'リスト表示(json)', 1
      it_behaves_like 'リスト表示(json)', 2
      it_behaves_like 'リダイレクト(json)', 3
    end

    context '未ログイン' do
      let(:spaces)  { @all_spaces }
      let(:members) { {} }
      include_context '未ログイン処理'
      it_behaves_like '[*]スペースがない'
      it_behaves_like '[未ログイン]スペースが最大表示数と同じ'
      it_behaves_like '[未ログイン]スペースが最大表示数より多い'
    end
    context 'ログイン中' do
      let(:spaces)  { @all_spaces } # Tips: APIは未ログイン扱いの為、公開しか見れない
      let(:members) { {} }
      include_context 'ログイン処理'
      it_behaves_like '[*]スペースがない'
      it_behaves_like '[ログイン中/削除予約済み]スペースが最大表示数と同じ'
      it_behaves_like '[ログイン中/削除予約済み]スペースが最大表示数より多い'
    end
    context 'ログイン中（削除予約済み）' do
      let(:spaces)  { @all_spaces } # Tips: APIは未ログイン扱いの為、公開しか見れない
      let(:members) { {} }
      include_context 'ログイン処理', :destroy_reserved
      it_behaves_like '[*]スペースがない'
      it_behaves_like '[ログイン中/削除予約済み]スペースが最大表示数と同じ'
      it_behaves_like '[ログイン中/削除予約済み]スペースが最大表示数より多い'
    end
    context 'APIログイン中' do
      let(:spaces)  { @user_spaces }
      let(:members) { @members }
      include_context 'APIログイン処理'
      it_behaves_like '[*]スペースがない'
      it_behaves_like '[APIログイン中/削除予約済み]スペースが最大表示数と同じ'
      it_behaves_like '[APIログイン中/削除予約済み]スペースが最大表示数より多い'
    end
    context 'APIログイン中（削除予約済み）' do
      let(:spaces)  { @user_spaces }
      let(:members) { @members }
      include_context 'APIログイン処理', :destroy_reserved
      it_behaves_like '[*]スペースがない'
      it_behaves_like '[APIログイン中/削除予約済み]スペースが最大表示数と同じ'
      it_behaves_like '[APIログイン中/削除予約済み]スペースが最大表示数より多い'
    end
  end

  # 前提条件
  #   ログイン中（URLの拡張子がない/AcceptヘッダにHTMLが含まれる）, APIログイン中（URLの拡張子が.json/AcceptヘッダにJSONが含まれる）
  #   検索文字列あり（部分一致, 大文字・小文字を区別しない）
  # テストパターン
  #   参加スペース: 含む, 除く
  describe 'GET #index' do
    subject { get spaces_path(format: subject_format), params: { text: text, exclude_member_space: exclude_member_space }, headers: auth_headers.merge(accept_headers) }
    let_it_be(:space)        { FactoryBot.create(:space, :public, name: 'space(Aaa)', description: 'description(Bbb)') }
    let_it_be(:member_space) { FactoryBot.create(:space, :public, name: 'space(Bbb)', description: 'description(Aaa)') }
    let(:text) { 'aaa' }

    # テスト内容
    shared_examples_for 'リスト表示' do
      it '対象の名称が含まれ、対象外は含まない' do
        subject
        inside_spaces.each do |space|
          expect(response.body).to include(space.name)
        end
        outside_spaces.each do |space|
          expect(response.body).not_to include(space.name)
        end
      end
    end
    shared_examples_for 'リスト表示(json)' do
      it '件数・名称が一致する' do
        subject
        response_json = JSON.parse(response.body)['spaces']
        expect(response_json.count).to eq(inside_spaces.count)
        inside_spaces.each_with_index do |space, index|
          expect(response_json[index]['name']).to eq(space.name)
        end
      end
    end

    # テストケース
    context 'ログイン中（URLの拡張子がない/AcceptヘッダにHTMLが含まれる）' do
      include_context 'ログイン処理'
      before_all { FactoryBot.create(:member, :admin, space_id: member_space.id, user_id: user.id) }
      let(:subject_format) { nil }
      let(:accept_headers) { ACCEPT_INC_HTML }
      context '参加スペースを含む' do
        let(:exclude_member_space) { nil }
        let(:inside_spaces) { [member_space, space] }
        let(:outside_spaces) { [] }
        it_behaves_like 'リスト表示'
      end
      context '参加スペースを除く' do
        let(:exclude_member_space) { '1' }
        let(:inside_spaces) { [space] }
        let(:outside_spaces) { [member_space] }
        it_behaves_like 'リスト表示'
      end
    end
    context 'APIログイン中（URLの拡張子が.json/AcceptヘッダにJSONが含まれる）' do
      include_context 'APIログイン処理'
      before_all { FactoryBot.create(:member, :admin, space_id: member_space.id, user_id: user.id) }
      let(:subject_format) { :json }
      let(:accept_headers) { ACCEPT_INC_JSON }
      context '参加スペースを含む' do
        let(:exclude_member_space) { nil }
        let(:inside_spaces) { [member_space, space] }
        it_behaves_like 'リスト表示(json)'
      end
      context '参加スペースを除く' do
        let(:exclude_member_space) { '1' }
        let(:inside_spaces) { [space] }
        it_behaves_like 'リスト表示(json)'
      end
    end
  end
end
