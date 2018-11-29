# encoding: UTF-8
require './spec/spec_helper.rb'

RSpec.describe Mysql2::Statement do
  before :each do
    @client = new_client(:encoding => "utf8")
  end

  def stmt_count
    @client.query("SHOW STATUS LIKE 'Prepared_stmt_count'").first['Value'].to_i
  end

  it "should create a statement" do
    statement = nil
    expect { statement = @client.prepare 'SELECT 1' }.to change(&method(:stmt_count)).by(1)
    expect(statement).to be_an_instance_of(Mysql2::Statement)
  end

  it "should raise an exception when server disconnects" do
    @client.close
    expect { @client.prepare 'SELECT 1' }.to raise_error(Mysql2::Error)
  end

  it "should tell us the param count" do
    statement = @client.prepare 'SELECT ?, ?'
    expect(statement.param_count).to eq(2)

    statement2 = @client.prepare 'SELECT 1'
    expect(statement2.param_count).to eq(0)
  end

  it "should tell us the field count" do
    statement = @client.prepare 'SELECT ?, ?'
    expect(statement.field_count).to eq(2)

    statement2 = @client.prepare 'SELECT 1'
    expect(statement2.field_count).to eq(1)
  end

  it "should let us execute our statement" do
    statement = @client.prepare 'SELECT 1'
    expect(statement.execute).not_to eq(nil)
  end

  it "should raise an exception without a block" do
    statement = @client.prepare 'SELECT 1'
    expect { statement.execute.each }.to raise_error(LocalJumpError)
  end

  it "should tell us the result count" do
    statement = @client.prepare 'SELECT 1'
    result = statement.execute
    expect(result.count).to eq(1)
  end

  it "should let us iterate over results" do
    statement = @client.prepare 'SELECT 1'
    result = statement.execute
    rows = []
    result.each { |r| rows << r }
    expect(rows).to eq([{ "1" => 1 }])
  end

  it "should handle booleans" do
    stmt = @client.prepare('SELECT ? AS `true`, ? AS `false`')
    result = stmt.execute(true, false)
    expect(result.to_a).to eq(['true' => 1, 'false' => 0])
  end

  it "should handle bignum but in int64_t" do
    stmt = @client.prepare('SELECT ? AS max, ? AS min')
    int64_max = (1 << 63) - 1
    int64_min = -(1 << 63)
    result = stmt.execute(int64_max, int64_min)
    expect(result.to_a).to eq(['max' => int64_max, 'min' => int64_min])
  end

  it "should handle bignum but beyond int64_t" do
    stmt = @client.prepare('SELECT ? AS max1, ? AS max2, ? AS max3, ? AS min1, ? AS min2, ? AS min3')
    int64_max1 = (1 << 63)
    int64_max2 = (1 << 64) - 1
    int64_max3 = 1 << 64
    int64_min1 = -(1 << 63) - 1
    int64_min2 = -(1 << 64) + 1
    int64_min3 = -0xC000000000000000
    result = stmt.execute(int64_max1, int64_max2, int64_max3, int64_min1, int64_min2, int64_min3)
    expect(result.to_a).to eq(['max1' => int64_max1, 'max2' => int64_max2, 'max3' => int64_max3, 'min1' => int64_min1, 'min2' => int64_min2, 'min3' => int64_min3])
  end

  it "should keep its result after other query" do
    @client.query 'USE test'
    @client.query 'CREATE TABLE IF NOT EXISTS mysql2_stmt_q(a int)'
    @client.query 'INSERT INTO mysql2_stmt_q (a) VALUES (1), (2)'
    stmt = @client.prepare('SELECT a FROM mysql2_stmt_q WHERE a = ?')
    result1 = stmt.execute(1)
    result2 = stmt.execute(2)
    expect(result2.first).to eq("a" => 2)
    expect(result1.first).to eq("a" => 1)
    @client.query 'DROP TABLE IF EXISTS mysql2_stmt_q'
  end

  it "should be reusable 1000 times" do
    statement = @client.prepare 'SELECT 1'
    1000.times do
      result = statement.execute
      expect(result.to_a.length).to eq(1)
    end
  end

  it "should be reusable 10000 times" do
    statement = @client.prepare 'SELECT 1'
    10000.times do
      result = statement.execute
      expect(result.to_a.length).to eq(1)
    end
  end

  it "should handle comparisons and likes" do
    @client.query 'USE test'
    @client.query 'CREATE TABLE IF NOT EXISTS mysql2_stmt_q(a int, b varchar(10))'
    @client.query 'INSERT INTO mysql2_stmt_q (a, b) VALUES (1, "Hello"), (2, "World")'
    statement = @client.prepare 'SELECT * FROM mysql2_stmt_q WHERE a < ?'
    results = statement.execute(2)
    expect(results.first).to eq("a" => 1, "b" => "Hello")

    statement = @client.prepare 'SELECT * FROM mysql2_stmt_q WHERE b LIKE ?'
    results = statement.execute('%orld')
    expect(results.first).to eq("a" => 2, "b" => "World")

    @client.query 'DROP TABLE IF EXISTS mysql2_stmt_q'
  end

  it "should select dates" do
    statement = @client.prepare 'SELECT NOW()'
    result = statement.execute
    expect(result.first.first[1]).to be_an_instance_of(Time)
  end

  it "should prepare Date values" do
    now = Date.today
    statement = @client.prepare('SELECT ? AS a')
    result = statement.execute(now)
    expect(result.first['a'].to_s).to eql(now.strftime('%F'))
  end

  it "should prepare Time values with microseconds" do
    now = Time.now
    statement = @client.prepare('SELECT ? AS a')
    result = statement.execute(now)
    if RUBY_VERSION =~ /1.8/
      expect(result.first['a'].strftime('%F %T %z')).to eql(now.strftime('%F %T %z'))
    else
      # microseconds is six digits after the decimal, but only test on 5 significant figures
      expect(result.first['a'].strftime('%F %T.%5N %z')).to eql(now.strftime('%F %T.%5N %z'))
    end
  end

  it "should prepare DateTime values with microseconds" do
    now = DateTime.now
    statement = @client.prepare('SELECT ? AS a')
    result = statement.execute(now)
    if RUBY_VERSION =~ /1.8/
      expect(result.first['a'].strftime('%F %T %z')).to eql(now.strftime('%F %T %z'))
    else
      # microseconds is six digits after the decimal, but only test on 5 significant figures
      expect(result.first['a'].strftime('%F %T.%5N %z')).to eql(now.strftime('%F %T.%5N %z'))
    end
  end

  it "should tell us about the fields" do
    statement = @client.prepare 'SELECT 1 as foo, 2'
    statement.execute
    list = statement.fields
    expect(list.length).to eq(2)
    expect(list.first).to eq('foo')
    expect(list[1]).to eq('2')
  end

  it "should handle as a decimal binding a BigDecimal" do
    stmt = @client.prepare('SELECT ? AS decimal_test')
    test_result = stmt.execute(BigDecimal.new("123.45")).first
    expect(test_result['decimal_test']).to be_an_instance_of(BigDecimal)
    expect(test_result['decimal_test']).to eql(123.45)
  end

  it "should update a DECIMAL value passing a BigDecimal" do
    @client.query 'USE test'
    @client.query 'DROP TABLE IF EXISTS mysql2_stmt_decimal_test'
    @client.query 'CREATE TABLE mysql2_stmt_decimal_test (decimal_test DECIMAL(10,3))'

    @client.prepare("INSERT INTO mysql2_stmt_decimal_test VALUES (?)").execute(BigDecimal.new("123.45"))

    test_result = @client.query("SELECT * FROM mysql2_stmt_decimal_test").first
    expect(test_result['decimal_test']).to eql(123.45)
  end

  it "should warn but still work if cache_rows is set to false" do
    @client.query_options.merge!(:cache_rows => false)
    statement = @client.prepare 'SELECT 1'
    result = nil
    expect { result = statement.execute.to_a }.to output(/:cache_rows is forced for prepared statements/).to_stderr
    expect(result.length).to eq(1)
  end

  context "utf8_db" do
    before(:each) do
      @client.query("DROP DATABASE IF EXISTS test_mysql2_stmt_utf8")
      @client.query("CREATE DATABASE test_mysql2_stmt_utf8")
      @client.query("USE test_mysql2_stmt_utf8")
      @client.query("CREATE TABLE テーブル (整数 int, 文字列 varchar(32)) charset=utf8")
      @client.query("INSERT INTO テーブル (整数, 文字列) VALUES (1, 'イチ'), (2, '弐'), (3, 'さん')")
    end

    after(:each) do
      @client.query("DROP DATABASE test_mysql2_stmt_utf8")
    end

    it "should be able to retrieve utf8 field names correctly" do
      stmt = @client.prepare 'SELECT * FROM `テーブル`'
      expect(stmt.fields).to eq(%w(整数 文字列))
      result = stmt.execute

      expect(result.to_a).to eq([{ "整数" => 1, "文字列" => "イチ" }, { "整数" => 2, "文字列" => "弐" }, { "整数" => 3, "文字列" => "さん" }])
    end

    it "should be able to retrieve utf8 param query correctly" do
      stmt = @client.prepare 'SELECT 整数 FROM テーブル WHERE 文字列 = ?'
      expect(stmt.param_count).to eq(1)

      result = stmt.execute 'イチ'

      expect(result.to_a).to eq([{ "整数" => 1 }])
    end

    it "should be able to retrieve query with param in different encoding correctly" do
      stmt = @client.prepare 'SELECT 整数 FROM テーブル WHERE 文字列 = ?'
      expect(stmt.param_count).to eq(1)

      param = 'イチ'.encode("EUC-JP")
      result = stmt.execute param

      expect(result.to_a).to eq([{ "整数" => 1 }])
    end
  end if defined? Encoding

  context "streaming result" do
    it "should be able to stream query result" do
      n = 1
      stmt = @client.prepare("SELECT 1 UNION SELECT 2")

      @client.query_options.merge!(:stream => true, :cache_rows => false, :as => :array)

      stmt.execute.each do |r|
        case n
        when 1
          expect(r).to eq([1])
        when 2
          expect(r).to eq([2])
        else
          violated "returned more than two rows"
        end
        n += 1
      end
    end
  end

  context "#each" do
    # note: The current impl. of prepared statement requires results to be cached on #execute except for streaming queries
    #       The drawback of this is that args of Result#each is ignored...

    it "should yield rows as hash's" do
      @result = @client.prepare("SELECT 1").execute
      @result.each do |row|
        expect(row).to be_an_instance_of(Hash)
      end
    end

    it "should yield rows as hash's with symbol keys if :symbolize_keys was set to true" do
      @client.query_options[:symbolize_keys] = true
      @result = @client.prepare("SELECT 1").execute
      @result.each do |row|
        expect(row.keys.first).to be_an_instance_of(Symbol)
      end
      @client.query_options[:symbolize_keys] = false
    end

    it "should be able to return results as an array" do
      @client.query_options[:as] = :array

      @result = @client.prepare("SELECT 1").execute
      @result.each do |row|
        expect(row).to be_an_instance_of(Array)
      end

      @client.query_options[:as] = :hash
    end

    it "should cache previously yielded results by default" do
      @result = @client.prepare("SELECT 1").execute
      expect(@result.first.object_id).to eql(@result.first.object_id)
    end

    it "should yield different value for #first if streaming" do
      @client.query_options[:stream] = true
      @client.query_options[:cache_rows] = false

      result = @client.prepare("SELECT 1 UNION SELECT 2").execute
      expect(result.first).not_to eql(result.first)

      @client.query_options[:stream] = false
      @client.query_options[:cache_rows] = true
    end

    it "should yield the same value for #first if streaming is disabled" do
      @client.query_options[:stream] = false
      result = @client.prepare("SELECT 1 UNION SELECT 2").execute
      expect(result.first).to eql(result.first)
    end

    it "should throw an exception if we try to iterate twice when streaming is enabled" do
      @client.query_options[:stream] = true
      @client.query_options[:cache_rows] = false

      result = @client.prepare("SELECT 1 UNION SELECT 2").execute

      expect {
        result.each {}
        result.each {}
      }.to raise_exception(Mysql2::Error)

      @client.query_options[:stream] = false
      @client.query_options[:cache_rows] = true
    end
  end

  context "#fields" do
    it "method should exist" do
      stmt = @client.prepare("SELECT 1")
      expect(stmt).to respond_to(:fields)
    end

    it "should return an array of field names in proper order" do
      stmt = @client.prepare("SELECT 'a', 'b', 'c'")
      expect(stmt.fields).to eql(%w(a b c))
    end

    it "should return nil for statement with no result fields" do
      stmt = @client.prepare("INSERT INTO mysql2_test () VALUES ()")
      expect(stmt.fields).to eql(nil)
    end
  end

  context "row data type mapping" do
    before(:each) do
      @client.query "USE test"
      @test_result = @client.prepare("SELECT * FROM mysql2_test ORDER BY id DESC LIMIT 1").execute.first
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
      let(:client) { new_client(:cast_booleans => true) }
      let(:id1) { client.query 'INSERT INTO mysql2_test (bool_cast_test) VALUES ( 1)'; client.last_id }
      let(:id2) { client.query 'INSERT INTO mysql2_test (bool_cast_test) VALUES ( 0)'; client.last_id }
      let(:id3) { client.query 'INSERT INTO mysql2_test (bool_cast_test) VALUES (-1)'; client.last_id }
      # rubocop:enable Style/Semicolon

      after do
        client.query "DELETE from mysql2_test WHERE id IN(#{id1},#{id2},#{id3})"
      end

      it "should return TrueClass or FalseClass for a TINYINT value if :cast_booleans is enabled" do
        query = client.prepare 'SELECT bool_cast_test FROM mysql2_test WHERE id = ?'
        result1 = query.execute id1
        result2 = query.execute id2
        result3 = query.execute id3
        expect(result1.first['bool_cast_test']).to be true
        expect(result2.first['bool_cast_test']).to be false
        expect(result3.first['bool_cast_test']).to be true
      end
    end

    context "cast booleans for BIT(1) if :cast_booleans is enabled" do
      # rubocop:disable Style/Semicolon
      let(:client) { new_client(:cast_booleans => true) }
      let(:id1) { client.query 'INSERT INTO mysql2_test (single_bit_test) VALUES (1)'; client.last_id }
      let(:id2) { client.query 'INSERT INTO mysql2_test (single_bit_test) VALUES (0)'; client.last_id }
      # rubocop:enable Style/Semicolon

      after do
        client.query "DELETE from mysql2_test WHERE id IN(#{id1},#{id2})"
      end

      it "should return TrueClass or FalseClass for a BIT(1) value if :cast_booleans is enabled" do
        query = client.prepare 'SELECT single_bit_test FROM mysql2_test WHERE id = ?'
        result1 = query.execute id1
        result2 = query.execute id2
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
      expect(@test_result['float_test']).to be_within(1e-5).of(10.3)
    end

    it "should return Float for a DOUBLE value" do
      expect(@test_result['double_test']).to be_an_instance_of(Float)
      expect(@test_result['double_test']).to eql(10.3)
    end

    it "should return Time for a DATETIME value when within the supported range" do
      expect(@test_result['date_time_test']).to be_an_instance_of(Time)
      expect(@test_result['date_time_test'].strftime("%Y-%m-%d %H:%M:%S")).to eql('2010-04-04 11:44:00')
    end

    if 1.size == 4 # 32bit
      klass = if RUBY_VERSION =~ /1.8/
        DateTime
      else
        Time
      end

      it "should return DateTime when timestamp is < 1901-12-13 20:45:52" do
        # 1901-12-13T20:45:52 is the min for 32bit Ruby 1.8
        r = @client.prepare("SELECT CAST('1901-12-13 20:45:51' AS DATETIME) as test").execute
        expect(r.first['test']).to be_an_instance_of(klass)
      end

      it "should return DateTime when timestamp is > 2038-01-19T03:14:07" do
        # 2038-01-19T03:14:07 is the max for 32bit Ruby 1.8
        r = @client.prepare("SELECT CAST('2038-01-19 03:14:08' AS DATETIME) as test").execute
        expect(r.first['test']).to be_an_instance_of(klass)
      end
    elsif 1.size == 8 # 64bit
      if RUBY_VERSION =~ /1.8/
        it "should return Time when timestamp is > 0138-12-31 11:59:59" do
          r = @client.prepare("SELECT CAST('0139-1-1 00:00:00' AS DATETIME) as test").execute
          expect(r.first['test']).to be_an_instance_of(Time)
        end

        it "should return DateTime when timestamp is < 0139-1-1T00:00:00" do
          r = @client.prepare("SELECT CAST('0138-12-31 11:59:59' AS DATETIME) as test").execute
          expect(r.first['test']).to be_an_instance_of(DateTime)
        end

        it "should return Time when timestamp is > 2038-01-19T03:14:07" do
          r = @client.prepare("SELECT CAST('2038-01-19 03:14:08' AS DATETIME) as test").execute
          expect(r.first['test']).to be_an_instance_of(Time)
        end
      else
        it "should return Time when timestamp is < 1901-12-13 20:45:52" do
          r = @client.prepare("SELECT CAST('1901-12-13 20:45:51' AS DATETIME) as test").execute
          expect(r.first['test']).to be_an_instance_of(Time)
        end

        it "should return Time when timestamp is > 2038-01-19T03:14:07" do
          r = @client.prepare("SELECT CAST('2038-01-19 03:14:08' AS DATETIME) as test").execute
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
          expect(result['enum_test'].encoding).to eql(Encoding::US_ASCII)
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
          expect(result['set_test'].encoding).to eql(Encoding::US_ASCII)
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
              expect(result[field].encoding).to eql(Encoding::US_ASCII)
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

  context 'last_id' do
    before(:each) do
      @client.query 'USE test'
      @client.query 'CREATE TABLE IF NOT EXISTS lastIdTest (`id` BIGINT NOT NULL AUTO_INCREMENT, blah INT(11), PRIMARY KEY (`id`))'
    end

    after(:each) do
      @client.query 'DROP TABLE lastIdTest'
    end

    it 'should return last insert id' do
      stmt = @client.prepare 'INSERT INTO lastIdTest (blah) VALUES (?)'
      expect(stmt.last_id).to eq 0
      stmt.execute 1
      expect(stmt.last_id).to eq 1
    end

    it 'should handle bigint ids' do
      stmt = @client.prepare 'INSERT INTO lastIdTest (id, blah) VALUES (?, ?)'
      stmt.execute 5000000000, 5000
      expect(stmt.last_id).to eql(5000000000)

      stmt = @client.prepare 'INSERT INTO lastIdTest (blah) VALUES (?)'
      stmt.execute 5001
      expect(stmt.last_id).to eql(5000000001)
    end
  end

  context 'affected_rows' do
    before :each do
      @client.query 'USE test'
      @client.query 'CREATE TABLE IF NOT EXISTS lastIdTest (`id` BIGINT NOT NULL AUTO_INCREMENT, blah INT(11), PRIMARY KEY (`id`))'
    end

    after :each do
      @client.query 'DROP TABLE lastIdTest'
    end

    it 'should return number of rows affected by an insert' do
      stmt = @client.prepare 'INSERT INTO lastIdTest (blah) VALUES (?)'
      expect(stmt.affected_rows).to eq 0
      stmt.execute 1
      expect(stmt.affected_rows).to eq 1
    end

    it 'should return number of rows affected by an update' do
      stmt = @client.prepare 'INSERT INTO lastIdTest (blah) VALUES (?)'
      stmt.execute 1
      expect(stmt.affected_rows).to eq 1
      stmt.execute 2
      expect(stmt.affected_rows).to eq 1

      stmt = @client.prepare 'UPDATE lastIdTest SET blah=? WHERE blah=?'
      stmt.execute 0, 1
      expect(stmt.affected_rows).to eq 1
    end

    it 'should return number of rows affected by a delete' do
      stmt = @client.prepare 'INSERT INTO lastIdTest (blah) VALUES (?)'
      stmt.execute 1
      expect(stmt.affected_rows).to eq 1
      stmt.execute 2
      expect(stmt.affected_rows).to eq 1

      stmt = @client.prepare 'DELETE FROM lastIdTest WHERE blah=?'
      stmt.execute 1
      expect(stmt.affected_rows).to eq 1
    end
  end

  context 'close' do
    it 'should free server resources' do
      stmt = @client.prepare 'SELECT 1'
      expect { stmt.close }.to change(&method(:stmt_count)).by(-1)
    end

    it 'should raise an error on subsequent execution' do
      stmt = @client.prepare 'SELECT 1'
      stmt.close
      expect { stmt.execute }.to raise_error(Mysql2::Error, /Invalid statement handle/)
    end
  end
end
