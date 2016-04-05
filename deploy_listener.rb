VERSION = "1.0.0"

################################################
# Config file parsing
require 'json'
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
  # github signature verification
  def verify_signature(payload_body,secret_token)
    signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), secret_token, payload_body)
    return halt 500, "Signatures didn't match!" unless Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'])
  end

  ################################################
  # Main
  releasefile = File.expand_path(settings.releasefile)
  outputjson = File.expand_path(".splat.json")
  urlprefix = settings.urlprefix

  # basic token based authentication - could be improved
  if settings.use_basic_auth
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

  if settings.use_github_webhook
    github_deploy_branch = settings.github_deploy_branch
    github_webhook = settings.github_urlprefix
    github_secret_token = settings.github_secret_token
  
    post github_webhook do
      request.body.rewind
      payload_body = request.body.read
      verify_signature(payload_body,github_secret_token)
      @payload = JSON.parse(params[:payload])
      revision = @payload["head_commit"]["id"]
      if @payload["ref"] == github_deploy_branch
        write_release(releasefile,revision)
        "Updating deploy revision to #{revision}\n"
      else
        "NOT DEPLOYED: #{@payload["ref"]} is not deploy branch"
      end
    end
  end
  
  not_found do
    "404 Not Found\n"
  end
end
