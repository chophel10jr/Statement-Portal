threads_count = ENV.fetch("RAILS_MAX_THREADS", 3)
threads threads_count, threads_count

# Only bind Unix socket in production
if ENV["RAILS_ENV"] == "production"
  bind "unix:///var/www/Statement-Portal/shared/sockets/puma.sock"
  pidfile "/var/www/Statement-Portal/tmp/pids/puma.pid"
else
  # default development port
  port ENV.fetch("PORT", 3000)
end

# Allow puma to be restarted by `bin/rails restart` command.
plugin :tmp_restart

# Run the Solid Queue supervisor inside of Puma for single-server deployments
plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]

