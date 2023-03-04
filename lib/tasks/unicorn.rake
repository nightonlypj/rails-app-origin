DEFAULT_PID_PATH = File.expand_path('../../tmp/pids/unicorn.pid', __dir__).freeze

# :nocov:
namespace :unicorn do
  desc 'Unicorn起動(bundle exec unicorn)'
  task(:start) do
    pid_path = ENV['PID_PATH'] || DEFAULT_PID_PATH
    if File.exist?(pid_path)
      p "Found: #{pid_path}"
      exit 1
    end

    rails_env = ENV['RAILS_ENV'] || 'development'
    sh "bundle exec unicorn -c config/unicorn.rb -D -E #{rails_env}"
  end

  desc 'Unicorn停止(QUIT)'
  task(:stop) { process_kill(:QUIT) }

  desc 'Unicorn再起動(HUP)'
  task(:restart) { process_kill(:HUP) }

  desc 'Unicorn緩やかな再起動(USR2)'
  task(:graceful) { process_kill(:USR2) }

  desc 'Unicornのワーカープロセスを増やす(TTIN)'
  task(:increment) { process_kill(:TTIN) }

  desc 'Unicornのワーカープロセスを減らす(TTOU)'
  task(:decrement) { process_kill(:TTOU) }

  desc 'Unicornプロセスの親子関係を確認(pstree)'
  task(:pstree) do
    pid_path = ENV['PID_PATH'] || DEFAULT_PID_PATH
    unless File.exist?(pid_path)
      p "Not found: #{pid_path}"
      exit 1
    end

    sh "pstree `cat #{pid_path}`"
  end

  # killシグナルを送る
  def process_kill(signal)
    pid_path = ENV['PID_PATH'] || DEFAULT_PID_PATH
    unless File.exist?(pid_path)
      p "Not found: #{pid_path}"
      exit 1
    end

    sh "kill -#{signal} `cat #{pid_path}`"
  end
end
# :nocov:
