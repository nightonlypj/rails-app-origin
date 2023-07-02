require 'rails_helper'
require 'rake'
require 'fileutils'

RSpec.configure do |config|
  # 全てのタスクを読み込む
  config.before(:suite) do
    Rails.application.load_tasks
  end

  # タスクを毎回実行するようにする
  config.before(:each) do
    Rake.application.tasks.each(&:reenable)
  end

  # ImageUploaderで作成したファイルをディレクトリごと削除
  config.after(:suite) do
    store_dir = User.new.image.store_dir
    if store_dir.start_with?('/tmp/')
      FileUtils.rm_rf(store_dir, secure: true)
    else
      # :nocov:
      p "[Skip]rm -rf #{store_dir}"
      # :nocov:
    end
  end
end
