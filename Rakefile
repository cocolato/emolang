# frozen_string_literal: true
# typed: true

require "bundler/gem_tasks"
require "minitest/test_task"
Minitest::TestTask.create
Minitest::TestTask.create(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.warning = false
  t.test_globs = ['test/**/*_test.rb']

end

