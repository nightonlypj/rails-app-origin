# This configuration file will be evaluated by Puma. The top-level methods that
# are invoked here are part of Puma's configuration DSL. For more information
# about methods provided by the DSL, see https://puma.io/puma/Puma/DSL.html.

# Puma starts a configurable number of processes (workers) and each process
# serves each request in a thread from an internal thread pool.
#
# The ideal number of threads per worker depends both on how much time the
# application spends waiting for IO operations and on how much you wish to
# to prioritize throughput over latency.
#
# As a rule of thumb, increasing the number of threads will increase how much
# traffic a given process can handle (throughput), but due to CRuby's
# Global VM Lock (GVL) it has diminishing returns and will degrade the
# response time (latency) of the application.
#
# The default is set to 3 threads as it's deemed a decent compromise between
# throughput and latency for the average Rails application.
#
# Any libraries that use a connection pool or another resource pool should
# be configured to provide at least as many connections as the number of
# threads. This includes Active Record's `pool` parameter in `database.yml`.
### START ###
# threads_count = ENV.fetch('RAILS_MAX_THREADS', 3)
# threads threads_count, threads_count
threads ENV.fetch('RAILS_MIN_THREADS', 3), ENV.fetch('RAILS_MAX_THREADS', 3) # MEMO: 増やすとスループットが向上するが、レイテンシは低下する
workers ENV.fetch('WEB_CONCURRENCY', 1) unless RUBY_PLATFORM.include?('darwin') # NOTE: vCPUと揃える。メモリ使用量が増える。macOSではエラーになる事がある為、設定しない
### END ###

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
### START ###
# port ENV.fetch('PORT', 3000)
puma_port = ENV.fetch('PUMA_PORT', nil)
puma_bind = ENV.fetch('PUMA_BIND', nil) # サンプル: 'unix:///workdir/tmp/sockets/puma.sock'
if puma_bind.nil? || puma_bind.empty? # NOTE: Railsの記法は使えない為 # rubocop:disable Rails/Blank
  port(puma_port.nil? || puma_port.empty? ? 3000 : puma_port.to_i) # rubocop:disable Rails/Blank
else
  bind puma_bind
end
### END ###

# Allow puma to be restarted by `bin/rails restart` command.
plugin :tmp_restart

# Specify the PID file. Defaults to tmp/pids/server.pid in development.
# In other environments, only set the PID file if requested.
### START ###
# pidfile ENV['PIDFILE'] if ENV['PIDFILE']
pidfile ENV.fetch('PIDFILE', 'tmp/pids/puma.pid')
### END ###
