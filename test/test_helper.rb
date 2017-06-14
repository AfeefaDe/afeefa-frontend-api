ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

# TODO: Handle this fuckup! We do not want do run seeds anytime we load this helper...
require File.expand_path('../../db/seeds', __FILE__)
::Seeds.recreate_all

class ActiveSupport::TestCase

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  # fixtures :all

  # Add more helper methods to be used by all tests here...
end
