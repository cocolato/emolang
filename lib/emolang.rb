# frozen_string_literal: true
# typed: true

require 'sorbet-runtime'

mydir = __dir__

module Emolang
  class Error < StandardError; end
  # Your code goes here...
end

Dir.glob(File.join(mydir, 'emolang', '/**/*.rb')).sort.each do |file|
  require file
end
