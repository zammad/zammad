# -*- coding: utf-8 -*-
###############################################################################
#
# A test for WriteExcel.
#
# Tests date and time handling.
#
# reverse('©'), May 2004, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#
############################################################################
require 'helper'
require 'stringio'

class TC_data_time < Test::Unit::TestCase

  def setup
    @workbook  = WriteExcel.new(StringIO.new)
    @worksheet = @workbook.add_worksheet
    @fit_delta = 0.5/(24*60*60*1000)
  end

  def fit_cmp(a, b)
    return (a-b).abs < @fit_delta
  end

  def test_convert_date_time_should_not_change_date_time_string
    date_time = ' 1899-12-31T00:00:00.0004Z '
    @worksheet.convert_date_time(date_time)

    assert_equal(' 1899-12-31T00:00:00.0004Z ', date_time)
  end

  def test_float_comparison_function
    # pass: diff < @fit_delta
    date_time = '1899-12-31T00:00:00.0004'
    number = 0
    result = @worksheet.__send__("convert_date_time", date_time)
    result = -1 if result.nil?
    assert(fit_cmp(number, result),
    "Testing convert_date_time: #{date_time} => #{result} <> #{number}")

    # fail: diff > @fit_delta
    date_time = '1989-12-31%00:00:00.0005'
    number = 0
    result = @worksheet.__send__("convert_date_time", date_time)
    result = -1 if result.nil?
    assert(!fit_cmp(number, result),
    "Testing convert_date_time: #{date_time} => #{result} <> #{number}")
  end

  def test_the_time_data_generated_in_excel
    lines = data_generated_excel.split(/\n/)
    while !lines.empty?
      line = lines.shift
      braak if line =~ /^\s*# stop/  # For debugging
      next  unless line =~ /\S/      # Ignore blank lines
      next  if line =~ /^\s*#/       # Ignore comments

      if line =~ /"DateTime">([^<]+)/
        date_time = $1
        line      = lines.shift

        if line =~ /"Number">([^<]+)/
          number = $1.to_f
          result = @worksheet.__send__("convert_date_time", date_time)
          result = -1 if result.nil?
          assert(fit_cmp(number, result),
          "date_time: #{date_time}\n"                    +
          "difference between #{number} and #{result}\n" +
          "= #{(number - result).abs.to_s}\n"            +
          "> #{@fit_delta.to_s}")
        end
      end
    end
  end

  def data_generated_excel

    return <<-__DATA_END__

    # Test data taken from Excel in XML format.
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">1899-12-31T00:00:00.000</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">0</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">1982-08-25T00:15:20.213</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">30188.010650613425</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">2065-04-19T00:16:48.290</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">60376.011670023145</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">2147-12-15T00:55:25.446</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">90565.038488958337</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">2230-08-10T01:02:46.891</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">120753.04359827546</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">2313-04-06T01:04:15.597</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">150942.04462496529</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">2395-11-30T01:09:40.889</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">181130.04838991899</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">2478-07-25T01:11:32.560</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">211318.04968240741</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">2561-03-21T01:30:19.169</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">241507.06272186342</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">2643-11-15T01:48:25.580</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">271695.07529606484</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">2726-07-12T02:03:31.919</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">301884.08578609955</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">2809-03-06T02:11:11.986</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">332072.09111094906</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">2891-10-31T02:24:37.095</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">362261.10042934027</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">2974-06-26T02:35:07.220</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">392449.10772245371</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">3057-02-19T02:45:12.109</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">422637.1147234838</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">3139-10-17T03:06:39.990</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">452826.12962951389</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">3222-06-11T03:08:08.251</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">483014.13065105322</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">3305-02-05T03:19:12.576</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">513203.13834</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">3387-10-01T03:29:42.574</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">543391.14563164348</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">3470-05-27T03:37:30.813</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">573579.15105107636</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">3553-01-21T04:14:38.231</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">603768.17683137732</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">3635-09-16T04:16:28.559</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">633956.17810832174</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">3718-05-13T04:17:58.222</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">664145.17914608796</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">3801-01-06T04:21:41.794</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">694333.18173372687</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">3883-09-02T04:56:35.792</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">724522.20596981479</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">3966-04-28T05:25:14.885</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">754710.2258667245</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">4048-12-21T05:26:05.724</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">784898.22645513888</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">4131-08-18T05:46:44.068</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">815087.24078782403</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">4214-04-13T05:48:01.141</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">845275.24167987274</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">4296-12-07T05:53:52.315</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">875464.24574438657</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">4379-08-03T06:14:48.580</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">905652.26028449077</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">4462-03-28T06:46:15.738</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">935840.28212659725</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">4544-11-22T07:31:20.407</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">966029.31343063654</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">4627-07-19T07:58:33.754</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">996217.33233511576</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">4710-03-15T08:07:43.130</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">1026406.3386936343</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">4792-11-07T08:29:11.091</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">1056594.3536005903</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">4875-07-04T09:08:15.328</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">1086783.3807329629</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">4958-02-27T09:30:41.781</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">1116971.3963169097</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">5040-10-23T09:34:04.462</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">1147159.3986627546</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">5123-06-20T09:37:23.945</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">1177348.4009715857</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">5206-02-12T09:37:56.655</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">1207536.4013501736</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">5288-10-08T09:45:12.230</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">1237725.406391551</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">5371-06-04T09:54:14.782</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">1267913.412671088</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">5454-01-28T09:54:22.108</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">1298101.4127558796</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">5536-09-24T10:01:36.151</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">1328290.4177795255</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">5619-05-20T12:09:48.602</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">1358478.5068125231</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">5702-01-14T12:34:08.549</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">1388667.5237100578</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">5784-09-08T12:56:06.495</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">1418855.5389640625</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">5867-05-06T12:58:58.217</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">1449044.5409515856</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">5949-12-30T12:59:54.263</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">1479232.5416002662</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">6032-08-24T13:34:41.331</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">1509420.5657561459</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">6115-04-21T13:58:28.601</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">1539609.5822754744</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">6197-12-14T14:02:16.899</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">1569797.5849178126</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">6280-08-10T14:36:17.444</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">1599986.6085352316</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">6363-04-06T14:37:57.451</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">1630174.60969272</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">6445-11-30T14:57:42.757</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">1660363.6234115392</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">6528-07-26T15:10:48.307</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">1690551.6325035533</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">6611-03-22T15:14:39.890</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">1720739.635183912</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">6693-11-15T15:19:47.988</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">1750928.6387498612</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">6776-07-11T16:04:24.344</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">1781116.6697262037</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">6859-03-07T16:22:23.952</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">1811305.6822216667</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">6941-10-31T16:29:55.999</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">1841493.6874536921</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">7024-06-26T16:58:20.259</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">1871681.7071789235</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">7107-02-21T17:04:02.415</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">1901870.7111390624</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">7189-10-16T17:18:29.630</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">1932058.7211762732</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">7272-06-11T17:47:21.323</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">1962247.7412190163</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">7355-02-05T17:53:29.866</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">1992435.7454845603</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">7437-10-02T17:53:41.076</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">2022624.7456143056</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">7520-05-28T17:55:06.044</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">2052812.7465977315</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">7603-01-21T18:14:49.151</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">2083000.7602910995</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">7685-09-16T18:17:45.738</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">2113189.7623349307</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">7768-05-12T18:29:59.700</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">2143377.7708298611</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">7851-01-07T18:33:21.233</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">2173566.773162419</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">7933-09-02T19:14:24.673</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">2203754.8016744559</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">8016-04-27T19:17:12.816</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">2233942.8036205554</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">8098-12-22T19:23:36.418</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">2264131.8080603937</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">8181-08-17T19:46:25.908</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">2294319.8239109721</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">8264-04-13T20:07:47.314</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">2324508.8387420601</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">8346-12-08T20:31:37.603</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">2354696.855296331</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">8429-08-03T20:39:57.770</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">2384885.8610853008</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">8512-03-29T20:50:17.067</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">2415073.8682530904</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">8594-11-22T21:02:57.827</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">2445261.8770581828</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">8677-07-19T21:23:05.519</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">2475450.8910360998</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">8760-03-14T21:34:49.572</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">2505638.8991848612</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">8842-11-08T21:39:05.944</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">2535827.9021521294</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">8925-07-04T21:39:18.426</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">2566015.9022965971</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">9008-02-28T21:46:07.769</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">2596203.9070343636</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">9090-10-24T21:57:55.662</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">2626392.9152275696</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">9173-06-19T22:19:11.732</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">2656580.9299968979</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">9256-02-13T22:23:51.376</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">2686769.9332335186</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">9338-10-09T22:27:58.771</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">2716957.9360968866</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">9421-06-05T22:43:30.392</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">2747146.9468795368</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">9504-01-30T22:48:25.834</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">2777334.9502990046</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">9586-09-24T22:53:51.727</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">2807522.9540709145</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">9669-05-20T23:12:56.536</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">2837711.9673210187</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">9752-01-14T23:15:54.109</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">2867899.9693762613</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">9834-09-10T23:17:12.632</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">2898088.9702850925</Data></Cell>
    </Row>
    <Row>
    <Cell ss:StyleID="s21"><Data ss:Type="DateTime">9999-12-31T23:59:59.000</Data></Cell>
    <Cell ss:StyleID="s22" ss:Formula="=RC[-1]"><Data ss:Type="Number">2958465.999988426</Data></Cell>
    </Row>

    __DATA_END__

  end

end
