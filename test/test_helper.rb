require 'coveralls'
require "simplecov"

Coveralls.wear!

# Coverage format
SimpleCov.formatter = if ENV['TRAVIS']
  Coveralls::SimpleCov::Formatter
else
  SimpleCov::Formatter::HTMLFormatter
end

SimpleCov.start do
  add_filter '/test/'
end
