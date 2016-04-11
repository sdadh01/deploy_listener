# Overview

deploy_listener listens for a RESTful command and updates a file with the contents of 
the path following a set prefix

eg. if the prefix is /deploy then curl http://hostname/deploy/xxxxyyyy will populate
the given release file with xxxxyyyy

It can also be setup as a Github webhook in addition to the above to trigger a deploy
based on a commit to a given branch.

deploy_listener is available as Open Source with no underlying support. Please fork and 
modify for your own use. Maintenance on this project will be ad hoc. I'll watch for pull requests 
but can't guarantee a turn around time.

deploy_listener should run on any server supporting ruby. However, it has only been tested on
Linux (Ubuntu, RHEL and CentOS).

# Usage

- Create a deploy_listener_config.yml file as described below
- Copy config/unicorn.rb and modify as required
- bundle install the gems
- start unicorn using 'bundle exec unicorn -c ./config/unicorn.rb -E development -D' (change environment to production to prevent listening on TCP port) 
- Add nginx to the front end in production to proxy back to deploy_listener

Config YAML file example :

```
auth_key: "1234567890"
use_auth: true
releasefile: ".release"
urlprefix: "/deploy"
```

Run as non-root user with privileges to file only as there is only basic security 
involved. Basic authentication can be added by setting use_auth and auth_key in the 
config file. Then the AUTH_KEY header will need to be sent along with the request.
In the example above setting use_auth to true and auth_key to 1234567890 the curl
example above becomes :

```
curl -H "AUTH_KEY: 1234567890" http://localhost:2000/deploy/xxxxyyyy
```

To add extra security either use iptables or put nginx in front and add SSL at
that level.

This listener should be used along with incron to listen to see if that file has 
changed and launch a separate script if the file changes.

An incrontab should look something like :

```
/path/to/release/file IN_CLOSE_WRITE /usr/bin/chef-client >/dev/null
```
A chef setup to use the above 

metadata.rb must require incron from chef supermarket

recipe snippet:

```  
  incron_user "root" do
    action :allow
  end
  
  incron_d "release_file_changes" do
    path "/path/to/release/file"
    mask "IN_CLOSE_WRITE"
    command "/usr/bin/chef-client >/dev/null"
  end
```
The 'deploy' section of a chef-client run can then be done only if the release file has
changed since the last current link was created by adding :

```
only_if File.mtime(release_file) > File.mtime(currentlink)
```

It is suggested to use a template to create the config yaml and unicorn.rb files. 

An example cookbook for deploy_listener can be found here (URL>>>)

git rev-parse production or look at github latest commit and get the FULL sha revision


## Inbound Github Webhook

On Github set up a webhook with the 'Payload URL' set to the URL that deploy_listener is
listening on. For example :

```
https://677acac1.ngrok.io/webhook/github
```
The 'Content type' should be set to 

```
application/x-www-form-urlencoded
```

The shared secret should be created at the command line using :

```
$ ruby -rsecurerandom -e 'puts SecureRandom.hex(20)'
8e897bdf9ed3e1d84a2efe57b02e1fa1ffaab509 
```
Copy this to the 'Secrets' field

The deploy_listener config file should then be set up to include the following snipit :

```
use_github_webhook: true
github_urlprefix: "/webhook/github"
github_deploy_branch: "refs/heads/production"
github_secret_token: "8e897bdf9ed3e1d84a2efe57b02e1fa1ffaab509"
```


## Inbound Gitlab Webhook

Note: There is no security token available for a Gitlab webhook at time of writing and so it is 
recommended that deploy_listener is either set up with nginx only accepting requests from
the Gitlab server IP address or iptables is used to provide some sort of security. Without security 
setup please use this feature at your own risk.

On Gitlab set up a webhook with the 'URL' set to the URL that deploy_listener is
listening on. For example :

```
https://677acac1.ngrok.io/webhook/gitlab
```

The deploy_listener config file should then be set up to include the following snipit :

```
use_gitlab_webhook: true
gitlab_urlprefix: "/webhook/gitlab"
gitlab_deploy_branch: "refs/heads/production"
```