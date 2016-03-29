VERSION = "1.0.0"

################################################
# Config file parsing
require 'sinatra/base'
require 'sinatra/config_file'


class DeployListener < Sinatra::Base
  register Sinatra::ConfigFile
  
  config_file './config/deploy_listener_config.yml'
  
  ################################################
  # release file handling
  def write_release(releasefile, revision)
    File.delete(releasefile) if File.exists?(releasefile)
    File.open(releasefile, ::File::CREAT | ::File::EXCL | ::File::WRONLY){|f| f.write("#{revision}") }
    return :exited
  end

  ################################################
  # Main
  releasefile = File.expand_path(settings.releasefile)
  urlprefix = settings.urlprefix
  
  # basic token based authentication - could be improved
  if settings.use_auth
    before do
      if env['HTTP_AUTH_KEY'] != settings.auth_key
        error 401
      end
    end
  end
     
  get "#{urlprefix}/:revision" do
    revision = params['revision']
    write_release(releasefile,revision)
    "Updating revision to #{revision}\n"
  end
  
  not_found do
    "404 Not Found\n"
  end
end