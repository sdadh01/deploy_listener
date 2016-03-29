# set path to app that will be used to configure unicorn
@dir = "/Users/adh/work/techopsguru/src/deploy_listener"

worker_processes 2
working_directory @dir

timeout 30

# Specify path to socket unicorn listens to,
listen "#{@dir}/tmp/sockets/unicorn.sock", :backlog => 64
listen 2000, :tcp_nopush => true

# Set process id path
pid "#{@dir}/tmp/pids/unicorn.pid"

# Set log file paths
stderr_path "#{@dir}/log/unicorn.stderr.log"
stdout_path "#{@dir}/log/unicorn.stdout.log"