namespace :all do
  desc '全ての削除Taskを実行'
  task :destroy, [:dry_run] => :environment do |_task, args|
    Rake::Task['user:destroy'].execute('dry_run' => args['dry_run'])
  end
end
