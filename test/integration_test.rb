# frozen_string_literal: true

require_relative 'test_helper'

class IntegrationTest < Minitest::Test
  def test_demo_program
    result = nil
    out, = capture_io do
      result = Emolang.run(File.read(File.expand_path('demo.emo', __dir__)))
    end
    refute_instance_of Emolang::Obj::Error, result
    assert_equal ['[1, 2, 3]', '2', "It's True!", "It's a ship function!", 'c++', '[1, 2, 3, 4]'],
                 out.split("\n")
  end

  def test_legacy_runner
    out, = capture_io do
      Emolang::LegacyRunner.new(File.expand_path('legacy.emo', __dir__)).execute
    end
    assert_equal ['[1, 2, 3]', '2', '"It\'s True！"', '"It\'s a ship function!"', '"c++"'],
                 out.split("\n")
  end
end
