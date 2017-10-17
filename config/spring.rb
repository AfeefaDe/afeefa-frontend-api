%w(
  .ruby-version
  .rbenv-vars
  config/settings.yml
  config/settings/test.yml
  tmp/restart.txt
  tmp/caching-dev.txt
).each { |path| Spring.watch(path) }