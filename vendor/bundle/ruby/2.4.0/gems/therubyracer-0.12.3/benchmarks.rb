require 'rubygems'
require 'bundler/setup'
require 'v8'
require 'benchmark'
require 'optparse'

OPTIONS = {
  :times => 5,
  :mode => :object,
  :objects => 500
}

parser = OptionParser.new do |opts|
  opts.on("-t", "--times [T]", Integer, "run benchmark N times") do |t|
    OPTIONS[:times] = t
  end

  opts.on("-m", "--mode [MODE]", [:object, :function, :eval], "select the type of object access to stress test") do |mode|
    mode = mode.to_sym
    raise "unsupported mode #{mode}" unless [:object,:function,:eval].include?(mode)
    OPTIONS[:mode] = mode
  end

  opts.on("-o", "--objects [N]", Integer, "create N objects for each iteration") do |n|
    OPTIONS[:objects] = n
  end
  opts
end

parser.parse! ARGV

MODE = OPTIONS[:mode]
TIMES = OPTIONS[:times]
OBJECTS = OPTIONS[:objects]

puts "using #{OPTIONS[:mode]}"
if MODE==:object
    def get(i)
      @cxt["test"]["objects"][i]
    end
elsif  MODE==:function
    def get(i)
      @cxt["test"].getObject(i)
    end
elsif  MODE==:eval
    def get(i)
      @cxt.eval "test.getObject(#{i})"
    end
end

js= <<JS

function createTest()
{
    var test = {};
    test.objects = [];
    test.seed = 49734321;
    test.summ;

    test.random = function()
    {
        // Robert Jenkins' 32 bit integer hash function.
        test.seed = ((test.seed + 0x7ed55d16) + (test.seed << 12))  & 0xffffffff;
        test.seed = ((test.seed ^ 0xc761c23c) ^ (test.seed >>> 19)) & 0xffffffff;
        test.seed = ((test.seed + 0x165667b1) + (test.seed << 5))   & 0xffffffff;
        test.seed = ((test.seed + 0xd3a2646c) ^ (test.seed << 9))   & 0xffffffff;
        test.seed = ((test.seed + 0xfd7046c5) + (test.seed << 3))   & 0xffffffff;
        test.seed = ((test.seed ^ 0xb55a4f09) ^ (test.seed >>> 16)) & 0xffffffff;
        return (test.seed & 0xfffffff) / 0x10000000;
    };

    test.init = function()
    {
        test.objects = [];
        for(var i=0; i<#{OBJECTS}; i++)
        {
            var hash = {};
            for(var j=0; j<10; j++)
            {
                var isString = test.random();
                var key = "str" + test.random();
                var value;
                if(isString < 0.5)
                    value = "str" + test.random();
                else
                    value = test.random();
                hash[key] = value;
            }
            test.objects[i] = hash;
        }
        return test.objects.length;
    }

    test.findSum = function()
    {
        test.summ = 0;
        var length = test.objects.length;
        for(var i=0; i<length; i++)
        {
            var hash = test.objects[i];
            for (var k in hash)
            {
                if (hash.hasOwnProperty(k) && (typeof(hash[k]) == "number"))
                {
                    test.summ += hash[k];
                }
            }
        }
        return test.summ;
    };

    test.finalCheck = function()
    {
        var summ = 0;
        var length = test.objects.length;
        for(var i=0; i<length; i++)
        {
            var hash = test.objects[i];
            for (var k in hash)
            {
                if (hash.hasOwnProperty(k) && (typeof(hash[k]) == "number"))
                {
                    summ += hash[k];
                }
            }
        }
        return summ ;
    };

    test.getObject = function(index)
    {
        if(!test.objects[index]) return {};
        return test.objects[index];
    }

    test.setObject = function(index, object)
    {
        test.objects[index] = object;
    }

    return test;
}

JS





def profile
 Benchmark.realtime do
    yield
   end
end

def get_res result
  result.to_f
end





puts "init js context..."
cxt = V8::Context.new
@cxt=cxt
cxt.eval(js)

cxt.eval('var test = createTest()')

puts "run init test"
result =profile do
  TIMES.times do
    cxt['test'].init()
  end
end

puts "init time: #{get_res(result) / TIMES} sec."
sum1=sum2=0
puts "run findSum test"

result =profile do
  TIMES.times do
      sum1= cxt['test'].findSum
  end
end

puts "findSum time: #{get_res(result) / TIMES} sec."


puts "run Objects inversion in ruby test"
result =profile do
  TIMES.times do |j|
    puts j
    for i in 0..(OBJECTS-1) do
      obj = get(i)
      obj.each do |key, value|
        if value.instance_of? Float
          obj[key] = value * (-1)
        end
      end
    end
  end
end

puts "Objects time: #{get_res(result) / TIMES} sec."

puts "run finalCheck test"


result =profile do
  TIMES.times do
    sum2= cxt['test'].findSum
  end
end

puts "final check time: #{get_res(result) / TIMES} sec."
puts "#{sum1==sum2*(TIMES%2==0?1:-1) ? 'TEST PASS': 'TEST FAIL'}:  Sum before inversions: #{sum1} / Sum after inversions: #{sum2}"