require 'test_helper'

class VerboseFormatterTest < Minitest::Test
  def setup
    does_exist = does_exist = nil
    @error = assert_raises(NameError){ doesnt_exist }
  end

  def test_message
    assert_equal <<~MESSAGE.chomp, @error.message
      undefined local variable or method `doesnt_exist' for #{method(:to_s).super_method.call}

          Did you mean? does_exist
       
    MESSAGE
  end
end
