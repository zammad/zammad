require 'spec_helper'

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe V8::Error do

  before do
    @cxt = V8::Context.new
    @cxt['one'] = lambda do
      @cxt.eval('two()', 'one.js')
    end
    @cxt['two'] = lambda do
      @cxt.eval('three()', 'two.js')
    end
  end

  it "captures a message without over nesting when the error is an error" do
    throw! do |e|
      e.message.should == "BOOM!"
    end
  end

  it "captures the js message without over nesting when the error is a normal object" do
    throw!('{foo: "bar"}') do |e|
      e.message.should == "[object Object]"
    end
    throw!('{message: "bar"}') do |e|
      e.message.should == "bar"
    end
  end

  it "captures a thrown value as the message" do
    throw!('"BOOM!"') do |e|
      e.message.should == "BOOM!"
    end
    throw!('6') do |e|
      e.message.should == '6'
    end
  end

  it "has a reference to the root javascript cause" do
    throw!('"I am a String"') do |e|
      e.should_not be_in_ruby
      e.should be_in_javascript
      e.value['message'].should == "I am a String"
    end
  end

  it "has a reference to the root ruby cause if one exists" do
    StandardError.new("BOOM!").tap do |bomb|
      @cxt['boom'] = lambda do
        raise bomb
      end
      lambda {
        @cxt.eval('boom()', 'boom.js')
      }.should(raise_error do |raised|
        raised.should be_in_ruby
        raised.should_not be_in_javascript
        raised.root_cause.should be(bomb)
      end)
    end
  end

  describe "backtrace" do
    it "is mixed with ruby and javascript" do
      throw! do |e|
        backtrace = e.backtrace.reject { |l| /kernel\// =~ l }
        backtrace.first.should eql  "at three.js:1:7"
        backtrace[1].should  match(/error_spec.rb/)
        backtrace[2].should eql "at two.js:1:1"
        backtrace[3].should match(/error_spec.rb/)
        backtrace[4].should eql "at one.js:1:1"
      end
    end

    it "can be set to show only ruby frames" do
      throw! do |e|
        e.backtrace(:ruby).each do |frame|
          frame.should =~ /(\.rb|):\d+/
        end
      end
    end

    it "can be set to show only javascript frames" do
      throw! do |e|
        e.backtrace(:javascript).each do |frame|
          frame.should =~ /\.js:\d:\d/
        end
      end
    end

    it "includes a mystery marker when the original frame is unavailable because what got thrown wasn't an error" do
      throw!("6") do |e|
        e.backtrace.first.should == 'at three.js:1:1'
      end
    end

    it "has a source name and line number when there is a javascript SyntaxError" do
      lambda do
        @cxt.eval(<<-INVALID, 'source.js')
"this line is okay";
"this line has a syntax error because it ends with a colon":
"this line is also okay";
"how do I find out that line 2 has the syntax error?";
INVALID
      end.should raise_error(V8::JSError) {|error|
        error.message.should eql 'Unexpected token : at source.js:2:61'
      }
    end

    it "can start with ruby at the bottom" do
      @cxt['boom'] = lambda do
        raise StandardError, "Bif!"
      end
      lambda {
        @cxt.eval('boom()', "boom.js")
      }.should(raise_error {|e|
        backtrace = e.backtrace.reject { |l| /kernel\// =~ l }
        backtrace.first.should =~ /error_spec\.rb/
        backtrace[1].should =~ /boom.js/
      })
    end
  end


  def throw!(js = "new Error('BOOM!')", &block)
    @cxt['three'] = lambda do
      @cxt.eval("throw #{js}", 'three.js')
    end
    lambda do
      @cxt['one'].call()
    end.should(raise_error(V8::JSError, &block))
  end
end


# describe V8::Error do
#   describe "A ruby exception thrown inside JavaScript" do
#     before do
#       @error = StandardError.new('potato')
#       begin
#         V8::Context.new do |cxt|
#           cxt['one'] = lambda do
#             cxt.eval('two()', 'one.js')
#           end
#           cxt['two'] = lambda do
#             cxt.eval('three()', 'two.js')
#           end
#           cxt['three'] = lambda do
#             raise @error
#           end
#           cxt.eval('one()')
#         end
#       rescue StandardError => e
#         @thrown = e
#       end
#     end
#     it "is raised up through the call stack" do
#       @thrown.should be(@error)
#     end
#
#     it "shows both the javascript and the ruby callframes" do
#       puts @error.backtrace.join('<br/>')
#     end
#
#   end
# end
