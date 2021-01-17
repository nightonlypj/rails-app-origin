unless defined?(DEFAULT_WORKER_PROCESSES)
  DEFAULT_WORKER_PROCESSES = 2
  DEFAULT_TIMEOUT = 60
  DEFAULT_LISTEN = File.expand_path('../tmp/sockets/unicorn.sock', __dir__).freeze
  DEFAULT_PID_PATH = File.expand_path('../tmp/pids/unicorn.pid', __dir__).freeze
  DEFAULT_STDERR_PATH = File.expand_path('../log/unicorn_stderr.log', __dir__).freeze
  DEFAULT_STDOUT_PATH = File.expand_path('../log/unicorn_stdout.log', __dir__).freeze
end
p "RAILS_ENV: #{ENV['RAILS_ENV'] || 'development(default)'}"
p "WORKER_PROCESSES: #{ENV['WORKER_PROCESSES'] || "#{DEFAULT_WORKER_PROCESSES}(default)"}"
p "TIMEOUT: #{ENV['TIMEOUT'] || "#{DEFAULT_TIMEOUT}(default)"}"
p "LISTEN: #{ENV['LISTEN'] || "#{DEFAULT_LISTEN}(default)"}"
pid_path = ENV['PID_PATH'] || DEFAULT_PID_PATH
p "PID_PATH: #{ENV['PID_PATH'] || "#{DEFAULT_PID_PATH}(default)"}[#{File.exist?(pid_path) ? File.read(pid_path).to_i : 'Not found'}]"
p "STDERR_PATH: #{ENV['STDERR_PATH'] || "#{DEFAULT_STDERR_PATH}(default)"}"
p "STDOUT_PATH: #{ENV['STDOUT_PATH'] || "#{DEFAULT_STDOUT_PATH}(default)"}"

worker_processes Integer(ENV['WORKER_PROCESSES'] || DEFAULT_WORKER_PROCESSES)
timeout Integer(ENV['TIMEOUT'] || DEFAULT_TIMEOUT)
preload_app true

listen ENV['LISTEN'] || DEFAULT_LISTEN
pid pid_path

stderr_path ENV['STDERR_PATH'] || DEFAULT_STDERR_PATH
stdout_path ENV['STDOUT_PATH'] || DEFAULT_STDOUT_PATH

before_fork do |server, worker|
  defined?(ActiveRecord::Base) and ActiveRecord::Base.connection.disconnect!

  old_pid = "#{server.config[:pid]}.oldbin"
  if (old_pid != server.pid) && File.exist?(old_pid)
    begin
      signal = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
      Process.kill(signal, File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH => e
      p e
    end
  end
end

after_fork do |_server, _worker|
  defined?(ActiveRecord::Base) and ActiveRecord::Base.establish_connection
end
