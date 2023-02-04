# config valid for current version and patch releases of Capistrano
lock '~> 3.17.1'

# set :application, 'my_app_name'
# set :repo_url, 'git@example.com:me/my_repo.git'
set :repo_url, `git remote get-url origin`.chomp

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, "/var/www/my_app_name"
set :deploy_to, '~/app'

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# append :linked_files, "config/database.yml", 'config/master.key'

# Default value for linked_dirs is []
# append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "tmp/webpacker", "public/system", "vendor", "storage"
append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'tmp/webpacker', 'public/system', 'vendor', 'storage', 'public/uploads'

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
# set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure

set :log_level, :info

set :rvm_type, :user
set :rvm_ruby_version, -> { `cat .ruby-version`.chomp }

set :unicorn_config_path, -> { "#{fetch(:deploy_to)}/current/config/unicorn.rb" }
set :unicorn_rack_env, 'production'

after 'deploy:symlink:linked_dirs', 'deploy:symlink:robots_txt'
after 'deploy:migrate', 'deploy:seed'
after 'deploy:publishing', 'unicorn:restart'

namespace :deploy do
  namespace :symlink do
    desc 'Runs ln -sfn public/<set :robots_txt> public/robots.txt'
    task :robots_txt do
      on roles(:web) do
        within "#{current_path}/public" do
          execute :ln, "-sfn #{fetch(:robots_txt)} robots.txt"
        end
      end
    end
  end

  desc 'Runs rake db:seed'
  task :seed do
    on roles(:db) do
      within current_path do
        execute :rake, 'db:seed'
      end
    end
  end
end
