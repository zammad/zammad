# Yhpg
#   https://gist.github.com/yancya/37d79e02a91afcfdeed1
#
# Author: yancya

require_relative 'helper'

class Yhpg
  MAPPING = [*'0'..'9', *'A'..'Z', *'a'..'z']

  def initialize(data)
    @n, @list = data.split(":").tap { |n, list| break [n.to_i, list.split(",").map { |str| Yhpg.decode(str) }] }
    x_nominee = @list.map { |x, _| x }.map { |x| [x, x + 1] }.flatten.tap { |a| a.push(*[0, 62])}.uniq
    y_nominee = @list.map { |_, y| y }.map { |y| [y, y + 1] }.flatten.tap { |a| a.push(*[0, 62])}.uniq
    x_range_patterns = x_nominee.combination(2).map { |a| (a.min..a.max) }
    y_range_patterns = y_nominee.combination(2).map { |a| (a.min..a.max) }
    squares = x_range_patterns.product(y_range_patterns)
    targets = squares.select { |xrange, yrange| @list.select { |p| check(xrange, yrange, p) }.size == @n }
    @areas = targets.map { |x, y| [(x.max - x.min) * (y.max - y.min), x, y] }
  end

  def debug
    p [@areas.min_by(&:first), @areas.max_by(&:first)]
  end

  def Yhpg.decode(str)
    str.chars.map { |w| MAPPING.index(w) }
  end

  def check(xrange, yrange, target)
    x, y = target
    (xrange.include?(x) && xrange.include?(x + 1)) &&
      (yrange.include?(y) && yrange.include?(y + 1))
  end

  def output
    case res = [@areas.map(&:first).min, @areas.map(&:first).max].join(',')
    when ','
      '-'
    else
      res
    end
  end
end

[
  ["4:00,11,zz,yy,1y,y1", "3600,3721"], # /*05*/
].each do |(actual, expect)|
  Benchmark.bm(30) do |x|
    x.report("expr") { Yhpg.new(actual).output == expect }
    x.report("TracePoint.trace { expr }") { TracePoint.new(:return, :c_return) {}.enable { Yhpg.new(actual).output == expect } }
    x.report("assertion_message { expr }") {
      assertion_message { Yhpg.new(actual).output == expect }
    }
    x.report("assertion_message { !expr }") {
      assertion_message { not Yhpg.new(actual).output == expect }
    }
  end
end
