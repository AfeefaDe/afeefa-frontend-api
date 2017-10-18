# config valid only for current version of Capistrano
lock '3.9.1'

# set :application, 'my_app_name'
# set :repo_url, 'git@example.com:me/my_repo.git'
set :application, 'afeefa-frontend-api'
set :repo_url, 'https://github.com/AfeefaDe/afeefa-frontend-api.git'

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, '/var/www/my_app_name'
set :deploy_to, '/home/afeefa/rails/afeefa-frontend-api'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: 'log/capistrano.log', color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# append :linked_files, 'config/database.yml', 'config/secrets.yml'
append :linked_files, 'config/database.yml'

# Default value for linked_dirs is []
# append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'public/system'
append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets'#, 'public/system'

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }
set :env, 'production'
set :rails_env, fetch(:env)

# Default value for keep_releases is 5
set :keep_releases, 5

# Defaults to nil (no asset cleanup is performed)
# If you use Rails 4+ and you'd like to clean up old assets after each deploy,
# set this to the number of versions to keep
set :keep_assets, 2

namespace :cache do

  task :rebuild_all do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      within release_path do
        execute "cd #{release_path} && bundle exec rails runner -e production 'CacheBuilder.new.build_all'"
      end
    end
  end

end

namespace :deploy do

  task :restart do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      within release_path do
        api =
            if fetch(:stage).to_s == 'production'
              'frontend-api'
            else
              'frontend-dev-api'
            end
        execute "svc -du ~/service/#{api}" # maybe we can use -h instead of -du
      end
    end
  end

  task :stop do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      within release_path do
        api =
            if fetch(:stage).to_s == 'production'
              'frontend-api'
            else
              'frontend-dev-api'
            end
        execute "svc -d ~/service/#{api}" # maybe we can use -h instead of -du
      end
    end
  end

  task :start do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      within release_path do
        api =
            if fetch(:stage).to_s == 'production'
              'frontend-api'
            else
              'frontend-dev-api'
            end
        execute "svc -u ~/service/#{api}" # maybe we can use -h instead of -du
      end
    end
  end

end

after 'deploy', 'cache:rebuild_all'
after 'deploy:rollback', 'cache:rebuild_all'
after 'cache:rebuild_all', 'deploy:restart'
