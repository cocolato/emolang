# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'minitest/test_task'

Minitest::TestTask.create(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.warning = false
end

task default: :test
