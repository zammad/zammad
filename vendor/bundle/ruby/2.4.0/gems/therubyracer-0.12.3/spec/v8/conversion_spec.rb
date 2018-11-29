require 'spec_helper'
require 'bigdecimal'
describe V8::Conversion do

  let(:cxt) { V8::Context.new }

  it "can embed BigDecimal values" do
    cxt['big'] = BigDecimal.new('1.1')
    cxt['big'].should eql BigDecimal.new('1.1')
  end

  it "doesn't try to use V8::Conversion::Class::* as root objects" do
    klass = Class.new do
      class << self
        def test
          Set.new
        end
      end
    end

    klass.test.should be_instance_of(::Set)
  end

  context "::Integer" do
    context "for 32-bit numbers" do
      it "should convert positive integer" do
        cxt['integer_a'] = 123
        cxt['integer_a'].should == 123
        cxt['integer_a'].should be_kind_of(Integer)
      end

      it "should convert negative integer" do
        cxt['integer_b'] = -123
        cxt['integer_b'].should == -123
        cxt['integer_b'].should be_kind_of(Integer)
      end
    end

    context "for 64-bit numbers" do
      it "should convert positive integer" do
        cxt['integer_c'] = 0x100000000
        cxt['integer_c'].should == 0x100000000
      end

      it "should convert negative integer" do
        cxt['integer_d'] = -0x100000000
        cxt['integer_d'].should == -0x100000000
      end
    end

  end
end
