# encoding: UTF-8
require 'spec_helper'

RSpec.describe Mysql2::Result do
  before(:each) do
    @result = @client.query "SELECT 1"
  end

  it "should raise a TypeError exception when it doesn't wrap a result set" do
    r = Mysql2::Result.new
    expect { r.count }.to raise_error(TypeError)
    expect { r.fields }.to raise_error(TypeError)
    expect { r.size }.to raise_error(TypeError)
    expect { r.each }.to raise_error(TypeError)
  end

  it "should have included Enumerable" do
    expect(Mysql2::Result.ancestors.include?(Enumerable)).to be true
  end

  it "should respond to #each" do
    expect(@result).to respond_to(:each)
  end

  it "should respond to #free" do
    expect(@result).to respond_to(:free)
  end

  it "should raise a Mysql2::Error exception upon a bad query" do
    expect {
      @client.query "bad sql"
    }.to raise_error(Mysql2::Error)

    expect {
      @client.query "SELECT 1"
    }.not_to raise_error
  end

  it "should respond to #count, which is aliased as #size" do
    r = @client.query "SELECT 1"
    expect(r).to respond_to :count
    expect(r).to respond_to :size
  end

  it "should be able to return the number of rows in the result set" do
    r = @client.query "SELECT 1"
    expect(r.count).to eql(1)
    expect(r.size).to eql(1)
  end

  context "metadata queries" do
    it "should show tables" do
      @result = @client.query "SHOW TABLES"
    end
  end

  context "#each" do
    it "should yield rows as hash's" do
      @result.each do |row|
        expect(row).to be_an_instance_of(Hash)
      end
    end

    it "should yield rows as hash's with symbol keys if :symbolize_keys was set to true" do
      @result.each(:symbolize_keys => true) do |row|
        expect(row.keys.first).to be_an_instance_of(Symbol)
      end
    end

    it "should be able to return results as an array" do
      @result.each(:as => :array) do |row|
        expect(row).to be_an_instance_of(Array)
      end
    end

    it "should cache previously yielded results by default" do
      expect(@result.first.object_id).to eql(@result.first.object_id)
    end

    it "should not cache previously yielded results if cache_rows is disabled" do
      result = @client.query "SELECT 1", :cache_rows => false
      expect(result.first.object_id).not_to eql(result.first.object_id)
    end

    it "should be able to iterate a second time even if cache_rows is disabled" do
      result = @client.query "SELECT 1 UNION SELECT 2", :cache_rows => false
      expect(result.to_a).to eql(result.to_a)
    end

    it "should yield different value for #first if streaming" do
      result = @client.query "SELECT 1 UNION SELECT 2", :stream => true, :cache_rows => false
      expect(result.first).not_to eql(result.first)
    end

    it "should yield the same value for #first if streaming is disabled" do
      result = @client.query "SELECT 1 UNION SELECT 2", :stream => false
      expect(result.first).to eql(result.first)
    end

    it "should throw an exception if we try to iterate twice when streaming is enabled" do
      result = @client.query "SELECT 1 UNION SELECT 2", :stream => true, :cache_rows => false

      expect {
        result.each.to_a
        result.each.to_a
      }.to raise_exception(Mysql2::Error)
    end
  end

  context "#fields" do
    before(:each) do
      @test_result = @client.query("SELECT * FROM mysql2_test ORDER BY id DESC LIMIT 1")
    end

    it "method should exist" do
      expect(@test_result).to respond_to(:fields)
    end

    it "should return an array of field names in proper order" do
      result = @client.query "SELECT 'a', 'b', 'c'"
      expect(result.fields).to eql(%w(a b c))
    end
  end

  context "streaming" do
    it "should maintain a count while streaming" do
      result = @client.query('SELECT 1', :stream => true, :cache_rows => false)
      expect(result.count).to eql(0)
      result.each.to_a
      expect(result.count).to eql(1)
    end

    it "should retain the count when mixing first and each" do
      result = @client.query("SELECT 1 UNION SELECT 2", :stream => true, :cache_rows => false)
      expect(result.count).to eql(0)
      result.first
      expect(result.count).to eql(1)
      result.each.to_a
      expect(result.count).to eql(2)
    end

    it "should not yield nil at the end of streaming" do
      result = @client.query('SELECT * FROM mysql2_test', :stream => true, :cache_rows => false)
      result.each { |r| expect(r).not_to be_nil }
    end

    it "#count should be zero for rows after streaming when there were no results" do
      @client.query "USE test"
      result = @client.query("SELECT * FROM mysql2_test WHERE null_test IS NOT NULL", :stream => true, :cache_rows => false)
      expect(result.count).to eql(0)
      result.each.to_a
      expect(result.count).to eql(0)
    end

    it "should raise an exception if streaming ended due to a timeout" do
      @client.query "CREATE TEMPORARY TABLE streamingTest (val BINARY(255)) ENGINE=MEMORY"

      # Insert enough records to force the result set into multiple reads
      # (the BINARY type is used simply because it forces full width results)
      10000.times do |i|
        @client.query "INSERT INTO streamingTest (val) VALUES ('Foo #{i}')"
      end

      @client.query "SET net_write_timeout = 1"
      res = @client.query "SELECT * FROM streamingTest", :stream => true, :cache_rows => false

      expect {
        res.each_with_index do |_, i|
          # Exhaust the first result packet then trigger a timeout
          sleep 2 if i > 0 && i % 1000 == 0
        end
      }.to raise_error(Mysql2::Error, /Lost connection/)
    end
  end

  context "row data type mapping" do
    before(:each) do
      @test_result = @client.query("SELECT * FROM mysql2_test ORDER BY id DESC LIMIT 1").first
    end

    it "should return nil values for NULL and strings for everything else when :cast is false" do
      result = @client.query('SELECT null_test, tiny_int_test, bool_cast_test, int_test, date_test, enum_test FROM mysql2_test WHERE bool_cast_test = 1 LIMIT 1', :cast => false).first
      expect(result["null_test"]).to be_nil
      expect(result["tiny_int_test"]).to eql("1")
      expect(result["bool_cast_test"]).to eql("1")
      expect(result["int_test"]).to eql("10")
      expect(result["date_test"]).to eql("2010-04-04")
      expect(result["enum_test"]).to eql("val1")
    end

    it "should return nil for a NULL value" do
      expect(@test_result['null_test']).to be_an_instance_of(NilClass)
      expect(@test_result['null_test']).to eql(nil)
    end

    it "should return String for a BIT(64) value" do
      expect(@test_result['bit_test']).to be_an_instance_of(String)
      expect(@test_result['bit_test']).to eql("\000\000\000\000\000\000\000\005")
    end

    it "should return String for a BIT(1) value" do
      expect(@test_result['single_bit_test']).to be_an_instance_of(String)
      expect(@test_result['single_bit_test']).to eql("\001")
    end

    it "should return Fixnum for a TINYINT value" do
      expect([Fixnum, Bignum]).to include(@test_result['tiny_int_test'].class)
      expect(@test_result['tiny_int_test']).to eql(1)
    end

    context "cast booleans for TINYINT if :cast_booleans is enabled" do
      # rubocop:disable Style/Semicolon
      let(:id1) { @client.query 'INSERT INTO mysql2_test (bool_cast_test) VALUES ( 1)'; @client.last_id }
      let(:id2) { @client.query 'INSERT INTO mysql2_test (bool_cast_test) VALUES ( 0)'; @client.last_id }
      let(:id3) { @client.query 'INSERT INTO mysql2_test (bool_cast_test) VALUES (-1)'; @client.last_id }
      # rubocop:enable Style/Semicolon

      after do
        @client.query "DELETE from mysql2_test WHERE id IN(#{id1},#{id2},#{id3})"
      end

      it "should return TrueClass or FalseClass for a TINYINT value if :cast_booleans is enabled" do
        result1 = @client.query "SELECT bool_cast_test FROM mysql2_test WHERE id = #{id1} LIMIT 1", :cast_booleans => true
        result2 = @client.query "SELECT bool_cast_test FROM mysql2_test WHERE id = #{id2} LIMIT 1", :cast_booleans => true
        result3 = @client.query "SELECT bool_cast_test FROM mysql2_test WHERE id = #{id3} LIMIT 1", :cast_booleans => true
        expect(result1.first['bool_cast_test']).to be true
        expect(result2.first['bool_cast_test']).to be false
        expect(result3.first['bool_cast_test']).to be true
      end
    end

    context "cast booleans for BIT(1) if :cast_booleans is enabled" do
      # rubocop:disable Style/Semicolon
      let(:id1) { @client.query 'INSERT INTO mysql2_test (single_bit_test) VALUES (1)'; @client.last_id }
      let(:id2) { @client.query 'INSERT INTO mysql2_test (single_bit_test) VALUES (0)'; @client.last_id }
      # rubocop:enable Style/Semicolon

      after do
        @client.query "DELETE from mysql2_test WHERE id IN(#{id1},#{id2})"
      end

      it "should return TrueClass or FalseClass for a BIT(1) value if :cast_booleans is enabled" do
        result1 = @client.query "SELECT single_bit_test FROM mysql2_test WHERE id = #{id1}", :cast_booleans => true
        result2 = @client.query "SELECT single_bit_test FROM mysql2_test WHERE id = #{id2}", :cast_booleans => true
        expect(result1.first['single_bit_test']).to be true
        expect(result2.first['single_bit_test']).to be false
      end
    end

    it "should return Fixnum for a SMALLINT value" do
      expect([Fixnum, Bignum]).to include(@test_result['small_int_test'].class)
      expect(@test_result['small_int_test']).to eql(10)
    end

    it "should return Fixnum for a MEDIUMINT value" do
      expect([Fixnum, Bignum]).to include(@test_result['medium_int_test'].class)
      expect(@test_result['medium_int_test']).to eql(10)
    end

    it "should return Fixnum for an INT value" do
      expect([Fixnum, Bignum]).to include(@test_result['int_test'].class)
      expect(@test_result['int_test']).to eql(10)
    end

    it "should return Fixnum for a BIGINT value" do
      expect([Fixnum, Bignum]).to include(@test_result['big_int_test'].class)
      expect(@test_result['big_int_test']).to eql(10)
    end

    it "should return Fixnum for a YEAR value" do
      expect([Fixnum, Bignum]).to include(@test_result['year_test'].class)
      expect(@test_result['year_test']).to eql(2009)
    end

    it "should return BigDecimal for a DECIMAL value" do
      expect(@test_result['decimal_test']).to be_an_instance_of(BigDecimal)
      expect(@test_result['decimal_test']).to eql(10.3)
    end

    it "should return Float for a FLOAT value" do
      expect(@test_result['float_test']).to be_an_instance_of(Float)
      expect(@test_result['float_test']).to eql(10.3)
    end

    it "should return Float for a DOUBLE value" do
      expect(@test_result['double_test']).to be_an_instance_of(Float)
      expect(@test_result['double_test']).to eql(10.3)
    end

    it "should return Time for a DATETIME value when within the supported range" do
      expect(@test_result['date_time_test']).to be_an_instance_of(Time)
      expect(@test_result['date_time_test'].strftime("%Y-%m-%d %H:%M:%S")).to eql('2010-04-04 11:44:00')
    end

    it "should return Time values with microseconds" do
      now = Time.now
      if RUBY_VERSION =~ /1.8/ || @client.server_info[:id] / 100 < 506
        result = @client.query("SELECT CAST('#{now.strftime('%F %T %z')}' AS DATETIME) AS a")
        expect(result.first['a'].strftime('%F %T %z')).to eql(now.strftime('%F %T %z'))
      else
        result = @client.query("SELECT CAST('#{now.strftime('%F %T.%6N %z')}' AS DATETIME(6)) AS a")
        # microseconds is 6 digits after the decimal, but only test on 5 significant figures
        expect(result.first['a'].strftime('%F %T.%5N %z')).to eql(now.strftime('%F %T.%5N %z'))
      end
    end

    it "should return DateTime values with microseconds" do
      now = DateTime.now
      if RUBY_VERSION =~ /1.8/ || @client.server_info[:id] / 100 < 506
        result = @client.query("SELECT CAST('#{now.strftime('%F %T %z')}' AS DATETIME)  AS a")
        expect(result.first['a'].strftime('%F %T %z')).to eql(now.strftime('%F %T %z'))
      else
        result = @client.query("SELECT CAST('#{now.strftime('%F %T.%6N %z')}' AS DATETIME(6)) AS a")
        # microseconds is 6 digits after the decimal, but only test on 5 significant figures
        expect(result.first['a'].strftime('%F %T.%5N %z')).to eql(now.strftime('%F %T.%5N %z'))
      end
    end

    if 1.size == 4 # 32bit
      klass = if RUBY_VERSION =~ /1.8/
        DateTime
      else
        Time
      end

      it "should return DateTime when timestamp is < 1901-12-13 20:45:52" do
        # 1901-12-13T20:45:52 is the min for 32bit Ruby 1.8
        r = @client.query("SELECT CAST('1901-12-13 20:45:51' AS DATETIME) as test")
        expect(r.first['test']).to be_an_instance_of(klass)
      end

      it "should return DateTime when timestamp is > 2038-01-19T03:14:07" do
        # 2038-01-19T03:14:07 is the max for 32bit Ruby 1.8
        r = @client.query("SELECT CAST('2038-01-19 03:14:08' AS DATETIME) as test")
        expect(r.first['test']).to be_an_instance_of(klass)
      end
    elsif 1.size == 8 # 64bit
      if RUBY_VERSION =~ /1.8/
        it "should return Time when timestamp is > 0138-12-31 11:59:59" do
          r = @client.query("SELECT CAST('0139-1-1 00:00:00' AS DATETIME) as test")
          expect(r.first['test']).to be_an_instance_of(Time)
        end

        it "should return DateTime when timestamp is < 0139-1-1T00:00:00" do
          r = @client.query("SELECT CAST('0138-12-31 11:59:59' AS DATETIME) as test")
          expect(r.first['test']).to be_an_instance_of(DateTime)
        end

        it "should return Time when timestamp is > 2038-01-19T03:14:07" do
          r = @client.query("SELECT CAST('2038-01-19 03:14:08' AS DATETIME) as test")
          expect(r.first['test']).to be_an_instance_of(Time)
        end
      else
        it "should return Time when timestamp is < 1901-12-13 20:45:52" do
          r = @client.query("SELECT CAST('1901-12-13 20:45:51' AS DATETIME) as test")
          expect(r.first['test']).to be_an_instance_of(Time)
        end

        it "should return Time when timestamp is > 2038-01-19T03:14:07" do
          r = @client.query("SELECT CAST('2038-01-19 03:14:08' AS DATETIME) as test")
          expect(r.first['test']).to be_an_instance_of(Time)
        end
      end
    end

    it "should return Time for a TIMESTAMP value when within the supported range" do
      expect(@test_result['timestamp_test']).to be_an_instance_of(Time)
      expect(@test_result['timestamp_test'].strftime("%Y-%m-%d %H:%M:%S")).to eql('2010-04-04 11:44:00')
    end

    it "should return Time for a TIME value" do
      expect(@test_result['time_test']).to be_an_instance_of(Time)
      expect(@test_result['time_test'].strftime("%Y-%m-%d %H:%M:%S")).to eql('2000-01-01 11:44:00')
    end

    it "should return Date for a DATE value" do
      expect(@test_result['date_test']).to be_an_instance_of(Date)
      expect(@test_result['date_test'].strftime("%Y-%m-%d")).to eql('2010-04-04')
    end

    it "should return String for an ENUM value" do
      expect(@test_result['enum_test']).to be_an_instance_of(String)
      expect(@test_result['enum_test']).to eql('val1')
    end

    it "should raise an error given an invalid DATETIME" do
      expect { @client.query("SELECT CAST('1972-00-27 00:00:00' AS DATETIME) as bad_datetime").each }.to \
        raise_error(Mysql2::Error, "Invalid date in field 'bad_datetime': 1972-00-27 00:00:00")
    end

    context "string encoding for ENUM values" do
      before { pending('Encoding is undefined') unless defined?(Encoding) }

      it "should default to the connection's encoding if Encoding.default_internal is nil" do
        with_internal_encoding nil do
          result = @client.query("SELECT * FROM mysql2_test ORDER BY id DESC LIMIT 1").first
          expect(result['enum_test'].encoding).to eql(Encoding::UTF_8)

          client2 = new_client(:encoding => 'ascii')
          result = client2.query("SELECT * FROM mysql2_test ORDER BY id DESC LIMIT 1").first
          expect(result['enum_test'].encoding).to eql(Encoding::ASCII)
        end
      end

      it "should use Encoding.default_internal" do
        with_internal_encoding Encoding::UTF_8 do
          result = @client.query("SELECT * FROM mysql2_test ORDER BY id DESC LIMIT 1").first
          expect(result['enum_test'].encoding).to eql(Encoding.default_internal)
        end

        with_internal_encoding Encoding::ASCII do
          result = @client.query("SELECT * FROM mysql2_test ORDER BY id DESC LIMIT 1").first
          expect(result['enum_test'].encoding).to eql(Encoding.default_internal)
        end
      end
    end

    it "should return String for a SET value" do
      expect(@test_result['set_test']).to be_an_instance_of(String)
      expect(@test_result['set_test']).to eql('val1,val2')
    end

    context "string encoding for SET values" do
      before { pending('Encoding is undefined') unless defined?(Encoding) }

      it "should default to the connection's encoding if Encoding.default_internal is nil" do
        with_internal_encoding nil do
          result = @client.query("SELECT * FROM mysql2_test ORDER BY id DESC LIMIT 1").first
          expect(result['set_test'].encoding).to eql(Encoding::UTF_8)

          client2 = new_client(:encoding => 'ascii')
          result = client2.query("SELECT * FROM mysql2_test ORDER BY id DESC LIMIT 1").first
          expect(result['set_test'].encoding).to eql(Encoding::ASCII)
        end
      end

      it "should use Encoding.default_internal" do
        with_internal_encoding Encoding::UTF_8 do
          result = @client.query("SELECT * FROM mysql2_test ORDER BY id DESC LIMIT 1").first
          expect(result['set_test'].encoding).to eql(Encoding.default_internal)
        end

        with_internal_encoding Encoding::ASCII do
          result = @client.query("SELECT * FROM mysql2_test ORDER BY id DESC LIMIT 1").first
          expect(result['set_test'].encoding).to eql(Encoding.default_internal)
        end
      end
    end

    it "should return String for a BINARY value" do
      expect(@test_result['binary_test']).to be_an_instance_of(String)
      expect(@test_result['binary_test']).to eql("test#{"\000" * 6}")
    end

    context "string encoding for BINARY values" do
      before { pending('Encoding is undefined') unless defined?(Encoding) }

      it "should default to binary if Encoding.default_internal is nil" do
        with_internal_encoding nil do
          result = @client.query("SELECT * FROM mysql2_test ORDER BY id DESC LIMIT 1").first
          expect(result['binary_test'].encoding).to eql(Encoding::BINARY)
        end
      end

      it "should not use Encoding.default_internal" do
        with_internal_encoding Encoding::UTF_8 do
          result = @client.query("SELECT * FROM mysql2_test ORDER BY id DESC LIMIT 1").first
          expect(result['binary_test'].encoding).to eql(Encoding::BINARY)
        end

        with_internal_encoding Encoding::ASCII do
          result = @client.query("SELECT * FROM mysql2_test ORDER BY id DESC LIMIT 1").first
          expect(result['binary_test'].encoding).to eql(Encoding::BINARY)
        end
      end
    end

    {
      'char_test' => 'CHAR',
      'varchar_test' => 'VARCHAR',
      'varbinary_test' => 'VARBINARY',
      'tiny_blob_test' => 'TINYBLOB',
      'tiny_text_test' => 'TINYTEXT',
      'blob_test' => 'BLOB',
      'text_test' => 'TEXT',
      'medium_blob_test' => 'MEDIUMBLOB',
      'medium_text_test' => 'MEDIUMTEXT',
      'long_blob_test' => 'LONGBLOB',
      'long_text_test' => 'LONGTEXT',
    }.each do |field, type|
      it "should return a String for #{type}" do
        expect(@test_result[field]).to be_an_instance_of(String)
        expect(@test_result[field]).to eql("test")
      end

      context "string encoding for #{type} values" do
        before { pending('Encoding is undefined') unless defined?(Encoding) }

        if %w(VARBINARY TINYBLOB BLOB MEDIUMBLOB LONGBLOB).include?(type)
          it "should default to binary if Encoding.default_internal is nil" do
            with_internal_encoding nil do
              result = @client.query("SELECT * FROM mysql2_test ORDER BY id DESC LIMIT 1").first
              expect(result['binary_test'].encoding).to eql(Encoding::BINARY)
            end
          end

          it "should not use Encoding.default_internal" do
            with_internal_encoding Encoding::UTF_8 do
              result = @client.query("SELECT * FROM mysql2_test ORDER BY id DESC LIMIT 1").first
              expect(result['binary_test'].encoding).to eql(Encoding::BINARY)
            end

            with_internal_encoding Encoding::ASCII do
              result = @client.query("SELECT * FROM mysql2_test ORDER BY id DESC LIMIT 1").first
              expect(result['binary_test'].encoding).to eql(Encoding::BINARY)
            end
          end
        else
          it "should default to utf-8 if Encoding.default_internal is nil" do
            with_internal_encoding nil do
              result = @client.query("SELECT * FROM mysql2_test ORDER BY id DESC LIMIT 1").first
              expect(result[field].encoding).to eql(Encoding::UTF_8)

              client2 = new_client(:encoding => 'ascii')
              result = client2.query("SELECT * FROM mysql2_test ORDER BY id DESC LIMIT 1").first
              expect(result[field].encoding).to eql(Encoding::ASCII)
            end
          end

          it "should use Encoding.default_internal" do
            with_internal_encoding Encoding::UTF_8 do
              result = @client.query("SELECT * FROM mysql2_test ORDER BY id DESC LIMIT 1").first
              expect(result[field].encoding).to eql(Encoding.default_internal)
            end

            with_internal_encoding Encoding::ASCII do
              result = @client.query("SELECT * FROM mysql2_test ORDER BY id DESC LIMIT 1").first
              expect(result[field].encoding).to eql(Encoding.default_internal)
            end
          end
        end
      end
    end
  end
end
