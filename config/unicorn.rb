unicorn_env = {
  worker_processes: ENV['WORKER_PROCESSES'] == '' ? nil : ENV['WORKER_PROCESSES'],
  timeout: ENV['TIMEOUT'] == '' ? nil : ENV['TIMEOUT'],
  working_directory: ENV['WORKING_DIRECTORY'] == '' ? nil : ENV['WORKING_DIRECTORY'],
  listen: ENV['LISTEN'] == '' ? nil : ENV['LISTEN'],
  listen_backlog: ENV['LISTEN_BACKLOG'] == '' ? nil : ENV['LISTEN_BACKLOG'],
  pid_path: ENV['PID_PATH'] == '' ? nil : ENV['PID_PATH'],
  stderr_path: ENV['STDERR_PATH'] == '' ? nil : ENV['STDERR_PATH'],
  stdout_path: ENV['STDOUT_PATH'] == '' ? nil : ENV['STDOUT_PATH']
}
unicorn_using = {
  worker_processes: (unicorn_env[:worker_processes] || 2).to_i,
  timeout: (unicorn_env[:timeout] || 60).to_i,
  working_directory: File.expand_path(unicorn_env[:working_directory] || '../', __dir__),
  listen: unicorn_env[:listen].to_i > 0 ? unicorn_env[:listen] : File.expand_path(unicorn_env[:listen] || '../tmp/sockets/unicorn.sock', __dir__),
  listen_backlog: (unicorn_env[:listen_backlog] || 1024).to_i,
  pid_path: File.expand_path(unicorn_env[:pid_path] || '../tmp/pids/unicorn.pid', __dir__),
  stderr_path: File.expand_path(unicorn_env[:stderr_path] || '../log/unicorn_stderr.log', __dir__),
  stdout_path: File.expand_path(unicorn_env[:stdout_path] || '../log/unicorn_stdout.log', __dir__)
}

p "WORKER_PROCESSES: #{unicorn_using[:worker_processes]}#{'(default)' if unicorn_env[:worker_processes].nil?}"
worker_processes unicorn_using[:worker_processes]

p "TIMEOUT: #{unicorn_using[:timeout]}#{'(default)' if unicorn_env[:timeout].nil?}"
timeout unicorn_using[:timeout]
preload_app true

p "WORKING_DIRECTORY: #{unicorn_using[:working_directory]}#{'(default)' if unicorn_env[:working_directory].nil?}"
working_directory unicorn_using[:working_directory]

p "LISTEN: #{unicorn_using[:listen]}#{'(default)' if unicorn_env[:listen].nil?}"
p "LISTEN_BACKLOG: #{unicorn_using[:listen_backlog]}#{'(default)' if unicorn_env[:listen_backlog].nil?}"
listen unicorn_using[:listen], backlog: unicorn_using[:listen_backlog]

pid_info = File.exist?(unicorn_using[:pid_path]) ? File.read(unicorn_using[:pid_path]).to_i : 'Not found'
p "PID_PATH: #{unicorn_using[:pid_path]}#{'(default)' if unicorn_env[:pid_path].nil?}[#{pid_info}]"
pid unicorn_using[:pid_path]

if ENV['RAILS_LOG_TO_STDOUT'].nil?
  p "STDERR_PATH: #{unicorn_using[:stderr_path]}#{'(default)' if unicorn_env[:stderr_path].nil?}"
  stderr_path unicorn_using[:stderr_path]

  p "STDOUT_PATH: #{unicorn_using[:stdout_path]}#{'(default)' if unicorn_env[:stdout_path].nil?}"
  stdout_path unicorn_using[:stdout_path]
else
  p "RAILS_LOG_TO_STDOUT: #{ENV['RAILS_LOG_TO_STDOUT']}"
end

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
