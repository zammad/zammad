# -*- coding: utf-8 -*-
require 'helper'

class TC_add_worksheet < Test::Unit::TestCase

  def setup
    @workbook = WriteExcel.new(StringIO.new)
  end

  def test_ascii_worksheet_name

    name = "Test"

    assert_nothing_raised {
      sheet = @workbook.add_worksheet(name)
      assert_equal name, sheet.name
    }

  end

  def test_utf_8_worksheet_name

    name = "Décembre"

    assert_nothing_raised {
      sheet = @workbook.add_worksheet(name)
      assert_equal utf8_to_16be(name), sheet.name
    }

  end

  def test_utf_16be_worksheet_name

    name = utf8_to_16be("Décembre")

    assert_nothing_raised {
      sheet = @workbook.add_worksheet(name, true)
      assert_equal name, sheet.name
    }

  end

end
