namespace :all do
  desc '全ての削除Taskを実行'
  task(:destroy, [:dry_run] => :environment) do |_, args|
    Rake::Task['user:destroy'].invoke(args.dry_run)
    Rake::Task['space:destroy'].invoke(args.dry_run)
    Rake::Task['invitation:destroy'].invoke(args.dry_run)
    Rake::Task['download:destroy'].invoke(args.dry_run)
  end
end
