APP = "deploy_listener"
environment = ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'production'

# set path to app that will be used to configure unicorn
@dir = "/Users/adh/work/techopsguru/src/#{APP}"

worker_processes 2
working_directory @dir

timeout 30

# Specify path to socket unicorn listens to,
listen "#{@dir}/tmp/sockets/unicorn_#{APP}.sock", :backlog => 64
listen(2000, backlog: 64) if environment == 'development'

# Set process id path
pid "#{@dir}/tmp/pids/unicorn_#{APP}.pid"

# Set log file paths
stderr_path "#{@dir}/log/unicorn_#{APP}.stderr.log"
stdout_path "#{@dir}/log/unicorn_#{APP}.stdout.log"

# set process name
class Unicorn::HttpServer
  def proc_name(tag)
    $0 = ([ File.basename(START_CTX[0]), APP,
            tag ]).concat(START_CTX[:argv]).join(' ')
  end
end