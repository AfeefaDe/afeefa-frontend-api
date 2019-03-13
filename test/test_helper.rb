require 'simplecov'
SimpleCov.start 'rails' do
  add_group 'Decorators', 'app/decorators'
end

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'minitest/rails'
require 'mocha/minitest'

# TODO: This is needed because of the strange issues in frontend api... DAMN!
require File.expand_path('../../db/seeds', __FILE__)
::Seeds.recreate_all

class ActiveSupport::TestCase

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  # fixtures :all

  # Add more helper methods to be used by all tests here...

  include FactoryBot::Syntax::Methods
end
