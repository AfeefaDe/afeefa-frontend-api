source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end


# Use mysql2 as the database for Active Record
gem 'mysql2'
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.0.2'
# Use Unicorn (not puma) as the app server
platforms :ruby do
  # keep this version of unicorn, because 5.5.0 seems not to be stable, update later
  gem 'unicorn', '~> 5.4.1'
end
# Use Puma as the app server
# gem 'puma', '~> 3.0'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

gem 'rack-cors'

# incorporate settings.yml
gem 'config'

# http requests
gem 'http'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platform: :mri
  gem 'ruby-debug-ide'
  # TODO: Do we need this anymore?
  gem 'debase'

  # test framework
  gem 'minitest-rails'

  # for tests
  gem 'factory_bot_rails'
  gem 'timecop'
  gem 'minitest-rails-capybara'
  gem 'minitest', '5.10.2'
  gem 'mocha'
  gem 'shoulda-context'

  # code coverage
  gem 'ruby-prof'
  gem 'simplecov', require: false

  # We do not longer use sqlite3:
  # gem 'sqlite3'
end

group :test, :development do
  gem 'rails_best_practices'
  gem 'bullet'

  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  # gem 'byebug', platform: :mri
  # comfortable rails console and debugger, also useful in production:
  gem 'pry'
  gem 'pry-rails'
  gem 'pry-byebug'
end

group :development do
  # documentation
  gem 'railroady'
  gem 'rails-erd'

  gem 'listen'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen'

  # Use Capistrano for deployment
  gem 'capistrano-rails'
  gem 'capistrano-rbenv'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
