# -*- coding: utf-8 -*-
##########################################################################
# test_42_set_properties.rb
#
# Tests for Workbook property_sets() interface.
#
# some test is commented out because related method was set to
# private method. Before that, all test passed.
#
#
#
#
# reverse('©'), September 2005, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#
#########################################################################
require 'helper'
require 'stringio'

class TC_set_properties < Test::Unit::TestCase

  def test_dummy
    assert(true)
  end

  def setup
    @test_file = StringIO.new
  end

  def teardown
    if @workbook.instance_variable_get(:@filehandle)
      @workbook.instance_variable_get(:@filehandle).close(true)
    end
    if @worksheet.instance_variable_get(:@filehandle)
      @worksheet.instance_variable_get(:@filehandle).close(true)
    end
  end

  def test_same_as_previous_plus_creation_date
    smiley = '☺'   # chr 0x263A;    in perl

    workbook  = WriteExcel.new(@test_file)
    worksheet = workbook.add_worksheet

=begin
    ###############################################################################
    #
    # Test 1. _get_property_set_codepage() for default latin1 strings.
    #
    params ={
                    :title       => 'Title',
                    :subject     => 'Subject',
                    :author      => 'Author',
                    :keywords    => 'Keywords',
                    :comments    => 'Comments',
                    :last_author => 'Username',
            }

    strings = %w(title subject author keywords comments last_author)

    caption    = " \t_get_property_set_codepage('latin1')"
    target     = 0x04E4

    result     = workbook.get_property_set_codepage(params, strings)
    assert_equal(target, result, caption)

    ###############################################################################
    #
    # Test 2. _get_property_set_codepage() for manual utf8 strings.
    #

    params =   {
                    :title       => 'Title',
                    :subject     => 'Subject',
                    :author      => 'Author',
                    :keywords    => 'Keywords',
                    :comments    => 'Comments',
                    :last_author => 'Username',
                    :utf8        => 1,
            }

    strings = %w(title subject author keywords comments last_author)

    caption    = " \t_get_property_set_codepage('utf8')"
    target     = 0xFDE9

    result     = workbook.get_property_set_codepage(params, strings)
    assert_equal(target, result, caption)

    ###############################################################################
    #
    # Test 3. _get_property_set_codepage() for utf8 strings.
    #
    params =   {
                    :title       => 'Title' + smiley,
                    :subject     => 'Subject',
                    :author      => 'Author',
                    :keywords    => 'Keywords',
                    :comments    => 'Comments',
                    :last_author => 'Username',
                }

    strings = %w(title subject author keywords comments last_author)

    caption    = " \t_get_property_set_codepage('utf8')";
    target     = 0xFDE9;

    result     = workbook.get_property_set_codepage(params, strings)
    assert_equal(target, result, caption)
=end

  ###############################################################################
  #
  # Note, the "created => nil" parameters in some of the following tests is
  # used to avoid adding the default date to the property sets.


  ###############################################################################
  #
  # Test 4. Codepage only.
  #

  workbook.set_properties(
                              :created     => nil
                           )

  caption    = " \tset_properties(codepage)"
  target     = %w(
                              FE FF 00 00 05 01 02 00 00 00 00 00 00 00 00 00
                              00 00 00 00 00 00 00 00 01 00 00 00 E0 85 9F F2
                              F9 4F 68 10 AB 91 08 00 2B 27 B3 D9 30 00 00 00
                              18 00 00 00 01 00 00 00 01 00 00 00 10 00 00 00
                              02 00 00 00 E4 04 00 00
                 ).join(' ')

  result     = unpack_record(workbook.summary)
  assert_equal(target, result, caption)

  ###############################################################################
  #
  # Test 5. Same as previous + Title.
  #

  workbook.set_properties(
                              :title       => 'Title',
                              :created     => nil
                           )

  caption    = " \tset_properties('Title')"
  target     = %w(
                              FE FF 00 00 05 01 02 00 00 00 00 00 00 00 00 00
                              00 00 00 00 00 00 00 00 01 00 00 00 E0 85 9F F2
                              F9 4F 68 10 AB 91 08 00 2B 27 B3 D9 30 00 00 00
                              30 00 00 00 02 00 00 00 01 00 00 00 18 00 00 00
                              02 00 00 00 20 00 00 00 02 00 00 00 E4 04 00 00
                              1E 00 00 00 06 00 00 00 54 69 74 6C 65 00 00 00
                ).join(' ')

  result     = unpack_record(workbook.summary)
  assert_equal(target, result, caption)

  ###############################################################################
  #
  # Test 6. Same as previous + Subject.
  #

  workbook.set_properties(
                              :title       => 'Title',
                              :subject     => 'Subject',
                              :created     => nil
                           )

  caption    = " \tset_properties('+ Subject')"
  target     = %w(
                              FE FF 00 00 05 01 02 00 00 00 00 00 00 00 00 00
                              00 00 00 00 00 00 00 00 01 00 00 00 E0 85 9F F2
                              F9 4F 68 10 AB 91 08 00 2B 27 B3 D9 30 00 00 00
                              48 00 00 00 03 00 00 00 01 00 00 00 20 00 00 00
                              02 00 00 00 28 00 00 00 03 00 00 00 38 00 00 00
                              02 00 00 00 E4 04 00 00 1E 00 00 00 06 00 00 00
                              54 69 74 6C 65 00 00 00 1E 00 00 00 08 00 00 00
                              53 75 62 6A 65 63 74 00
                 ).join(' ')

  result     = unpack_record(workbook.summary)
  assert_equal(target, result, caption)

  ###############################################################################
  #
  # Test 7. Same as previous + Author.
  #

  workbook.set_properties(
                              :title       => 'Title',
                              :subject     => 'Subject',
                              :author      => 'Author',
                              :created     => nil
                           )

  caption    = " \tset_properties('+ Author')"
  target     = %w(
                              FE FF 00 00 05 01 02 00 00 00 00 00 00 00 00 00
                              00 00 00 00 00 00 00 00 01 00 00 00 E0 85 9F F2
                              F9 4F 68 10 AB 91 08 00 2B 27 B3 D9 30 00 00 00
                              60 00 00 00 04 00 00 00 01 00 00 00 28 00 00 00
                              02 00 00 00 30 00 00 00 03 00 00 00 40 00 00 00
                              04 00 00 00 50 00 00 00 02 00 00 00 E4 04 00 00
                              1E 00 00 00 06 00 00 00 54 69 74 6C 65 00 00 00
                              1E 00 00 00 08 00 00 00 53 75 62 6A 65 63 74 00
                              1E 00 00 00 07 00 00 00 41 75 74 68 6F 72 00 00
                 ).join(' ')

  result     = unpack_record(workbook.summary)
  assert_equal(target, result, caption)

  ###############################################################################
  #
  # Test 8. Same as previous + Keywords.
  #

  workbook.set_properties(
                              :title       => 'Title',
                              :subject     => 'Subject',
                              :author      => 'Author',
                              :keywords    => 'Keywords',
                              :created     => nil
                           )

  caption    = " \tset_properties('+ Keywords')"
  target     = %w(
                              FE FF 00 00 05 01 02 00 00 00 00 00 00 00 00 00
                              00 00 00 00 00 00 00 00 01 00 00 00 E0 85 9F F2
                              F9 4F 68 10 AB 91 08 00 2B 27 B3 D9 30 00 00 00
                              7C 00 00 00 05 00 00 00 01 00 00 00 30 00 00 00
                              02 00 00 00 38 00 00 00 03 00 00 00 48 00 00 00
                              04 00 00 00 58 00 00 00 05 00 00 00 68 00 00 00
                              02 00 00 00 E4 04 00 00 1E 00 00 00 06 00 00 00
                              54 69 74 6C 65 00 00 00 1E 00 00 00 08 00 00 00
                              53 75 62 6A 65 63 74 00 1E 00 00 00 07 00 00 00
                              41 75 74 68 6F 72 00 00 1E 00 00 00 09 00 00 00
                              4B 65 79 77 6F 72 64 73 00 00 00 00
                 ).join(' ')

  result     = unpack_record(workbook.summary)
  assert_equal(target, result, caption)

  ###############################################################################
  #
  # Test 9. Same as previous + Comments.
  #

  workbook.set_properties(
                              :title       => 'Title',
                              :subject     => 'Subject',
                              :author      => 'Author',
                              :keywords    => 'Keywords',
                              :comments    => 'Comments',
                              :created     => nil
                           )

  caption    = " \tset_properties('+ Comments')"
  target     = %w(
                              FE FF 00 00 05 01 02 00 00 00 00 00 00 00 00 00
                              00 00 00 00 00 00 00 00 01 00 00 00 E0 85 9F F2
                              F9 4F 68 10 AB 91 08 00 2B 27 B3 D9 30 00 00 00
                              98 00 00 00 06 00 00 00 01 00 00 00 38 00 00 00
                              02 00 00 00 40 00 00 00 03 00 00 00 50 00 00 00
                              04 00 00 00 60 00 00 00 05 00 00 00 70 00 00 00
                              06 00 00 00 84 00 00 00 02 00 00 00 E4 04 00 00
                              1E 00 00 00 06 00 00 00 54 69 74 6C 65 00 00 00
                              1E 00 00 00 08 00 00 00 53 75 62 6A 65 63 74 00
                              1E 00 00 00 07 00 00 00 41 75 74 68 6F 72 00 00
                              1E 00 00 00 09 00 00 00 4B 65 79 77 6F 72 64 73
                              00 00 00 00 1E 00 00 00 09 00 00 00 43 6F 6D 6D
                              65 6E 74 73 00 00 00 00
                 ).join(' ')

  result     = unpack_record(workbook.summary)
  assert_equal(target, result, caption)

  ###############################################################################
  #
  # Test 10. Same as previous + Last author.
  #

  workbook.set_properties(
                              :title       => 'Title',
                              :subject     => 'Subject',
                              :author      => 'Author',
                              :keywords    => 'Keywords',
                              :comments    => 'Comments',
                              :last_author => 'Username',
                              :created     => nil
                           )

  caption    = " \tset_properties('+ Last author')"
  target     = %w(
                            FE FF 00 00 05 01 02 00 00 00 00 00 00 00 00 00
                            00 00 00 00 00 00 00 00 01 00 00 00 E0 85 9F F2
                            F9 4F 68 10 AB 91 08 00 2B 27 B3 D9 30 00 00 00
                            B4 00 00 00 07 00 00 00 01 00 00 00 40 00 00 00
                            02 00 00 00 48 00 00 00 03 00 00 00 58 00 00 00
                            04 00 00 00 68 00 00 00 05 00 00 00 78 00 00 00
                            06 00 00 00 8C 00 00 00 08 00 00 00 A0 00 00 00
                            02 00 00 00 E4 04 00 00 1E 00 00 00 06 00 00 00
                            54 69 74 6C 65 00 00 00 1E 00 00 00 08 00 00 00
                            53 75 62 6A 65 63 74 00 1E 00 00 00 07 00 00 00
                            41 75 74 68 6F 72 00 00 1E 00 00 00 09 00 00 00
                            4B 65 79 77 6F 72 64 73 00 00 00 00 1E 00 00 00
                            09 00 00 00 43 6F 6D 6D 65 6E 74 73 00 00 00 00
                            1E 00 00 00 09 00 00 00 55 73 65 72 6E 61 6D 65
                            00 00 00 00
                 ).join(' ')

  result     = unpack_record(workbook.summary)
  assert_equal(target, result, caption)

  ###############################################################################
  #
  # Test 11. Same as previous + Creation date.
  #

  # Aug 19 23:20:13 2008
  # $sec,$min,$hour,$mday,$mon,$year
  # We normalise the time using timegm() so that the tests don't fail due to
  # different timezones.

  filetime   = Time.gm(2008,8,19,23,20,13)
  workbook.set_properties(
                              :title       => 'Title',
                              :subject     => 'Subject',
                              :author      => 'Author',
                              :keywords    => 'Keywords',
                              :comments    => 'Comments',
                              :last_author => 'Username',
                              :created     => filetime
                           )

  caption    = " \tset_properties('+ Creation date')"
  target     = %w(
                            FE FF 00 00 05 01 02 00 00 00 00 00 00 00 00 00
                            00 00 00 00 00 00 00 00 01 00 00 00 E0 85 9F F2
                            F9 4F 68 10 AB 91 08 00 2B 27 B3 D9 30 00 00 00
                            C8 00 00 00 08 00 00 00 01 00 00 00 48 00 00 00
                            02 00 00 00 50 00 00 00 03 00 00 00 60 00 00 00
                            04 00 00 00 70 00 00 00 05 00 00 00 80 00 00 00
                            06 00 00 00 94 00 00 00 08 00 00 00 A8 00 00 00
                            0C 00 00 00 BC 00 00 00 02 00 00 00 E4 04 00 00
                            1E 00 00 00 06 00 00 00 54 69 74 6C 65 00 00 00
                            1E 00 00 00 08 00 00 00 53 75 62 6A 65 63 74 00
                            1E 00 00 00 07 00 00 00 41 75 74 68 6F 72 00 00
                            1E 00 00 00 09 00 00 00 4B 65 79 77 6F 72 64 73
                            00 00 00 00 1E 00 00 00 09 00 00 00 43 6F 6D 6D
                            65 6E 74 73 00 00 00 00 1E 00 00 00 09 00 00 00
                            55 73 65 72 6E 61 6D 65 00 00 00 00 40 00 00 00
                            80 74 89 21 52 02 C9 01
                 ).join(' ')

  result     = unpack_record(workbook.summary)
  assert_equal(target, result, caption)

  ###############################################################################
  #
  # Test 12. Same as previous. Date set at the workbook level.
  #

  # Wed Aug 20 00:20:13 2008
  # $sec,$min,$hour,$mday,$mon,$year
  # We normalise the time using timegm() so that the tests don't fail due to
  # different timezones.
  workbook.localtime  = Time.gm(2008,8,19,23,20,13)

  workbook.set_properties(
                              :title       => 'Title',
                              :subject     => 'Subject',
                              :author      => 'Author',
                              :keywords    => 'Keywords',
                              :comments    => 'Comments',
                              :last_author => 'Username'
                           )

  caption    = " \tset_properties('+ Creation date')"
  target     = %w(
                              FE FF 00 00 05 01 02 00 00 00 00 00 00 00 00 00
                              00 00 00 00 00 00 00 00 01 00 00 00 E0 85 9F F2
                              F9 4F 68 10 AB 91 08 00 2B 27 B3 D9 30 00 00 00
                              C8 00 00 00 08 00 00 00 01 00 00 00 48 00 00 00
                              02 00 00 00 50 00 00 00 03 00 00 00 60 00 00 00
                              04 00 00 00 70 00 00 00 05 00 00 00 80 00 00 00
                              06 00 00 00 94 00 00 00 08 00 00 00 A8 00 00 00
                              0C 00 00 00 BC 00 00 00 02 00 00 00 E4 04 00 00
                              1E 00 00 00 06 00 00 00 54 69 74 6C 65 00 00 00
                              1E 00 00 00 08 00 00 00 53 75 62 6A 65 63 74 00
                              1E 00 00 00 07 00 00 00 41 75 74 68 6F 72 00 00
                              1E 00 00 00 09 00 00 00 4B 65 79 77 6F 72 64 73
                              00 00 00 00 1E 00 00 00 09 00 00 00 43 6F 6D 6D
                              65 6E 74 73 00 00 00 00 1E 00 00 00 09 00 00 00
                              55 73 65 72 6E 61 6D 65 00 00 00 00 40 00 00 00
                              80 74 89 21 52 02 C9 01
                 ).join(' ')

  result     = unpack_record(workbook.summary)
  assert_equal(target, result, caption)

  ###############################################################################
  #
  # Test 14. UTF-8 string used.
  #

  workbook.set_properties(
                              :title       => 'Title' + smiley,
                              :created     => nil
                           )

  caption    = " \tset_properties(utf8)"
  target     = %w(
                              FE FF 00 00 05 01 02 00 00 00 00 00 00 00 00 00
                              00 00 00 00 00 00 00 00 01 00 00 00 E0 85 9F F2
                              F9 4F 68 10 AB 91 08 00 2B 27 B3 D9 30 00 00 00
                              34 00 00 00 02 00 00 00 01 00 00 00 18 00 00 00
                              02 00 00 00 20 00 00 00 02 00 00 00 E9 FD 00 00
                              1E 00 00 00 09 00 00 00 54 69 74 6C 65 E2 98 BA
                              00 00 00 00
                 ).join(' ')

  result     = unpack_record(workbook.summary)
  assert_equal(target, result, caption)

  workbook.close

  end
end
