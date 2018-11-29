# -*- coding: utf-8 -*-
#
# OLE::Storage_Lite
#  by Kawai, Takanori (Hippo2000) 2000.11.4, 8, 14
# This Program is Still ALPHA version.
#//////////////////////////////////////////////////////////////////////////////
#
# converted from CPAN's OLE::Storage_Lite.
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#

require 'tempfile'
require 'stringio'

class OLEStorageLite       #:nodoc:
  PPS_TYPE_ROOT   = 5
  PPS_TYPE_DIR    = 1
  PPS_TYPE_FILE   = 2
  DATA_SIZE_SMALL = 0x1000
  LONG_INT_SIZE   = 4
  PPS_SIZE        = 0x80

  attr_reader :file

  def initialize(file = nil)
    @file = file
  end

  def getPpsTree(data)
    info = _initParse(file)
    info ? _getPpsTree(0, info, data) : nil
  end

  def getPpsSearch(name, data, icase)
    info = _initParse(file)
    info ? _getPpsSearch(0, info, name, data, icase) : nil
  end

  def getNthPps(no, data)
    info = _initParse(file)
    info ? _getNthPps(no, info, data) : nil
  end

  def _initParse(file)
    io = file.respond_to?(:to_str) ? open(file, 'rb') : file
    _getHeaderInfo(io)
  end
  private :_initParse

  def _getPpsTree(no, info, data, done)
    if done
      return [] if done.include?(no)
    else
      done = []
    end
    done << no

    rootblock = info[:root_start]

    #1. Get Information about itself
    pps = _getNthPps(no, info, data)

    #2. Child
    if pps.dir_pps !=  0xFFFFFFFF
      pps.child = _getPpsTree(pps.dir_pps, info, data, done)
    else
      pps.child = nil
    end

    #3. Previous,Next PPSs
    list = []
    list << _getPpsTree(pps.prev_pps, info, data, done) if pps.prev_pps != 0xFFFFFFFF
    list << pps
    list << _getPpsTree(pps.next_pps, info, data, done) if pps.next_pps != 0xFFFFFFFF
  end
  private :_getPpsTree

  def _getPpsSearch(no, info, name, data, icase, done = nil)
    rootblock = info[:root_start]
    #1. Check it self
    if done
      return [] if done.include?(no)
    else
      done = []
    end
    done << no
    pps  = _getNthPps(no, info, nil)

    re = Regexp.new("^\Q#{pps.name}\E$", Regexp::IGNORECASE)
    if (icase && !name.select { |v| v =~ re }.empty?) || name.include?(pps.name)
      pps = _getNthPps(no, info, data) if data
      res = [pps]
    else
      res = []
    end

    #2. Check Child, Previous, Next PPSs
    res +=
      _getPpsSearch(pps.dir_pps, info, name, data, icase, done) if pps.dir_pps !=  0xFFFFFFFF
    res +=
      _getPpsSearch(pps.prev_pps, info, name, data, icase, done) if pps.prev_pps != 0xFFFFFFFF
    res +=
      _getPpsSearch(pps.next_pps, info, name, data, icase, done) if pps.next_pps != 0xFFFFFFFF
    res
  end
  private :_getPpsSearch

  def _getHeaderInfo(io)
    info = { :fileh => io }

    #0. Check ID
    info[:fileh].seek(0, 0)
    return nil unless info[:fileh].read(8) == "\xD0\xCF\x11\xE0\xA1\xB1\x1A\xE1"

    # BIG BLOCK SIZE
    val = _getInfoFromFile(info[:fileh], 0x1E, 2, "v")
    return nil if val.nil?
    info[:big_block_size] = 2 ** val

    # SMALL BLOCK SIZE
    val = _getInfoFromFile(info[:fileh], 0x20, 2, "v")
    return nil if val.nil?
    info[:small_block_size] = 2 ** val

    # BDB Count
    val = _getInfoFromFile(info[:fileh], 0x2C, 4, "V")
    return nil if val.nil?
    info[:bdb_count] = val

    # START BLOCK
    val = _getInfoFromFile(info[:fileh], 0x30, 4, "V")
    return nil if val.nil?
    info[:root_start] = val

    # SMALL BD START
    val = _getInfoFromFile(info[:fileh], 0x3C, 4, "V")
    return nil if val.nil?
    info[:sbd_start] = val

    # SMALL BD COUNT
    val = _getInfoFromFile(info[:fileh], 0x40, 4, "V")
    return nil if val.nil?
    info[:sbd_count] = val

    # EXTRA BBD START
    val = _getInfoFromFile(info[:fileh], 0x44, 4, "V")
    return nil if val.nil?
    info[:extra_bbd_start] = val

    # EXTRA BBD COUNT
    val = _getInfoFromFile(info[:fileh], 0x48, 4, "V")
    return nil if val.nil?
    info[:extra_bbd_count] = val

    #GET BBD INFO
    info[:bbd_info] = _getBbdInfo(info)

    # GET ROOT PPS
    root = _getNthPps(0, info, nil)
    info[:sb_start] = root.start_block
    info[:sb_size]  = root.size
    info
  end
  private :_getHeaderInfo

  def _getInfoFromFile(io, pos, len, fmt)
    io.seek(pos, 0)
    str = io.read(len)
    if str.bytesize != len
      nil
    else
      str.unpack(fmt)[0]
    end
  end
  private :_getInfoFromFile

  def _getBbdInfo(info)
    bdlist = []
    iBdbCnt = info[:bdb_count]
    i1stCnt = (info[:big_block_size] - 0x4C) / LONG_INT_SIZE
    iBdlCnt = info[:big_block_size] / LONG_INT_SIZE - 1

    #1. 1st BDlist
    info[:fileh].seek(0x4C, 0)
    iGetCnt = iBdbCnt < i1stCnt ? iBdbCnt : i1stCnt
    str = info[:fileh].read(LONG_INT_SIZE * iGetCnt)
    bdlist += str.unpack("V#{iGetCnt}")
    iBdbCnt -= iGetCnt

    #2. Extra BDList
    iBlock = info[:extra_bbd_start]
    while iBdbCnt> 0 && _isNormalBlock(iBlock)
      _setFilePos(iBlock, 0, info)
      iGetCnt = iBdbCnt < iBdlCnt ? iBdbCnt : iBdlCnt
      str = info[:fileh].read(LONG_INT_SIZE * iGetCnt)
      bdlist += str.unpack("V#{iGetCnt}")
      iBdbCnt -= iGetCnt
      str = info[:fileh].read(LONG_INT_SIZE)
      iBlock = str.unpack("V")
    end

    #3.Get BDs
    hBd = Hash.new
    iBlkNo = 0
    iBdCnt = info[:big_block_size] / LONG_INT_SIZE
    bdlist.each do |iBdL|
      _setFilePos(iBdL, 0, info)
      str = info[:fileh].read(info[:big_block_size])
      arr = str.unpack("V#{iBdCnt}")
      (0...iBdCnt).each do |i|
        hBd[iBlkNo] = arr[i] if arr[i] != iBlkNo + 1
        iBlkNo += 1
      end
    end
    hBd
  end
  private :_getBbdInfo

  def _getNthPps(pos, info, data)
    ppsstart = info[:root_start]

    basecnt = info[:big_block_size] / PPS_SIZE
    ppsblock = pos / basecnt
    ppspos   = pos % basecnt

    block = _getNthBlockNo(ppsstart, ppsblock, info)
    return nil if block.nil?

    _setFilePos(block, PPS_SIZE * ppspos, info)
    str = info[:fileh].read(PPS_SIZE)
    return nil if str.nil? || str == ''
    nmsize = str[0x40, 2].unpack('v')[0]
    nmsize -= 2 if nmsize > 2
    nm = str[0, nmsize]
    type = str[0x42, 2].unpack('C')[0]
    ppsprev = str[0x44, LONG_INT_SIZE].unpack('V')[0]
    ppsnext = str[0x48, LONG_INT_SIZE].unpack('V')[0]
    dirpps  = str[0x4C, LONG_INT_SIZE].unpack('V')[0]
    time1st =
      (type == PPS_TYPE_ROOT || type == PPS_TYPE_DIR) ? oleData2Local(str[0x64, 8]) : nil
    time2nd =
      (type == PPS_TYPE_ROOT || type == PPS_TYPE_DIR) ? oleData2Local(str[0x6C, 8]) : nil
    start, size = str[0x74, 8].unpack('VV')
    if data
      sdata = _getData(type, start, size, info)
      OLEStorageLitePPS.new(pos, nm, type, ppsprev, ppsnext, dirpps,
                            time1st, time2nd, start, size, sdata, nil)
    else
      OLEStorageLitePPS.new(pos, nm, type, ppsprev, ppsnext, dirpps,
                            time1st, time2nd, start, size, nil, nil)
    end
  end
  private :_getNthPps

  def _setFilePos(iBlock, iPos, info)
    info[:fileh].seek((iBlock + 1) * info[:big_block_size] + iPos, 0)
  end
  private :_setFilePos

  def _getNthBlockNo(stblock, nth, info)
    inext = stblock
    (0...nth).each do |i|
      sv = inext
      inext = _getNextBlockNo(sv, info)
      return nil unless _isNormalBlock(inext)
    end
    inext
  end
  private :_getNthBlockNo

  def _getData(iType, iBlock, iSize, info)
    if iType == PPS_TYPE_FILE
      if iSize < DATA_SIZE_SMALL
        return _getSmallData(iBlock, iSize, info)
      else
        return _getBigData(iBlock, iSize, info)
      end
    elsif iType == PPS_TYPE_ROOT  # Root
      return _getBigData(iBlock, iSize, info)
    elsif iType == PPS_TYPE_DIR   # Directory
      return nil
    end
  end
  private :_getData

  def _getBigData(iBlock, iSize, info)
    return '' unless _isNormalBlock(iBlock)
    iRest = iSize
    sRes  = ''
    aKeys = info[:bbd_info].keys.sort

    while iRest > 0
      aRes = aKeys.select { |key| key >= iBlock }
      iNKey = aRes[0]
      i = iNKey - iBlock
      iNext = info[:bbd_info][iNKey]
      _setFilePos(iBlock, 0, info)
      iGetSize = info[:big_block_size] * (i + 1)
      iGetSize = iRest if iRest < iGetSize
      sRes += info[:fileh].read(iGetSize)
      iRest -= iGetSize
      iBlock = iNext
    end
    sRes
  end
  private :_getBigData

  def _getNextBlockNo(iBlockNo, info)
    iRes = info[:bbd_info][iBlockNo]
    iRes ? iRes : iBlockNo + 1
  end
  private :_getNextBlockNo

  def _isNormalBlock(iBlock)
    iBlock < 0xFFFFFFFC ? 1 : nil
  end
  private :_isNormalBlock

  def _getSmallData(iSmBlock, iSize, info)
    iRest = iSize
    sRes = ''
    while iRest > 0
      _setFilePosSmall(iSmBlock, info)
      sRes += info[:fileh].read(
          iRest >= info[:small_block_size] ? info[:small_block_size] : iRest)
      iRest -= info[:small_block_size]
      iSmBlock = _getNextSmallBlockNo(iSmBlock, info)
    end
    sRes
  end
  private :_getSmallData

  def _setFilePosSmall(iSmBlock, info)
    iSmStart = info[:sb_start]
    iBaseCnt = info[:big_block_size] / info[:small_block_size]
    iNth = iSmBlock / iBaseCnt
    iPos = iSmBlock % iBaseCnt

    iBlk = _getNthBlockNo(iSmStart, iNth, info)
    _setFilePos(iBlk, iPos * info[:small_block_size], info)
  end
  private :_setFilePosSmall

  def _getNextSmallBlockNo(iSmBlock, info)
    iBaseCnt = info[:big_block_size] / LONG_INT_SIZE
    iNth = iSmBlock / iBaseCnt
    iPos = iSmBlock % iBaseCnt
    iBlk = _getNthBlockNo(info[:sbd_start], iNth, info)
    _setFilePos(iBlk, iPos * LONG_INT_SIZE, info)
    info[:fileh].read(LONG_INT_SIZE).unpack('V')
  end
  private :_getNextSmallBlockNo

  def asc2ucs(str)
    str.split(//).join("\0") + "\0"
  end

  def ucs2asc(str)
    ary = str.unpack('v*').map { |s| [s].pack('c')}
    ary.join('')
  end

  #------------------------------------------------------------------------------
  # OLEDate2Local()
  #
  # Convert from a Window FILETIME structure to a localtime array. FILETIME is
  # a 64-bit value representing the number of 100-nanosecond intervals since
  # January 1 1601.
  #
  # We first convert the FILETIME to seconds and then subtract the difference
  # between the 1601 epoch and the 1970 Unix epoch.
  #
  def oleData2Local(oletime)
    # Unpack the FILETIME into high and low longs.
    lo, hi = oletime.unpack('V2')

    # Convert the longs to a double.
    nanoseconds = hi * 2 ** 32 +  lo

    # Convert the 100 nanosecond units into seconds.
    time = nanoseconds / 1e7

    # Subtract the number of seconds between the 1601 and 1970 epochs.
    time -= 11644473600

    # Convert to a localtime (actually gmtime) structure.
    if time >= 1
      ltime = Time.at(time).getgm.to_a[0, 9]
      ltime[4] -= 1    # month
      ltime[5] -= 1900 # year
      ltime[7] -= 1    # past from 1, Jan
      ltime[8] = ltime[8] ? 1 : 0
      ltime
    else
      []
    end
  end

  #------------------------------------------------------------------------------
  # LocalDate2OLE()
  #
  # Convert from a a localtime array to a Window FILETIME structure. FILETIME is
  # a 64-bit value representing the number of 100-nanosecond intervals since
  # January 1 1601.
  #
  # We first convert the localtime (actually gmtime) to seconds and then add the
  # difference between the 1601 epoch and the 1970 Unix epoch. We convert that to
  # 100 nanosecond units, divide it into high and low longs and return it as a
  # packed 64bit structure.
  #
  def localDate2OLE(localtime)
    return "\x00" * 8 unless localtime

    # Convert from localtime (actually gmtime) to seconds.
    args = localtime.reverse
    args[0] += 1900   # year
    args[1] += 1      # month
    time = Time.gm(*args)

    # Add the number of seconds between the 1601 and 1970 epochs.
    time = time.to_i + 11644473600

    # The FILETIME seconds are in units of 100 nanoseconds.
    nanoseconds = time * 10000000

    # Pack the total nanoseconds into 64 bits...
    hi, lo = nanoseconds.divmod 1 << 32

    [lo, hi].pack("VV")  # oletime
  end
end

class OLEStorageLitePPS < OLEStorageLite       #:nodoc:
  attr_accessor :no, :name, :type, :prev_pps, :next_pps, :dir_pps
  attr_accessor :time_1st, :time_2nd, :start_block, :size, :data, :child
  attr_reader   :pps_file

  def initialize(iNo, sNm, iType, iPrev, iNext, iDir,
                 raTime1st, raTime2nd, iStart, iSize, sData, raChild)
    @no          = iNo
    @name        = sNm
    @type        = iType
    @prev_pps    = iPrev
    @next_pps    = iNext
    @dir_pps     = iDir
    @time_1st    = raTime1st
    @time_2nd    = raTime2nd
    @start_block = iStart
    @size        = iSize
    @data        = sData
    @child       = raChild
    @pps_file    = nil
  end

  def _datalen
    return 0 if @data.nil?
    if @pps_file
      return @pps_file.lstat.size
    else
      return @data.bytesize
    end
  end
  protected :_datalen

  def _makeSmallData(aList, rh_info)
    file = rh_info[:fileh]
    iSmBlk = 0
    sRes = ''

    aList.each do |pps|
      #1. Make SBD, small data string
      if pps.type == PPS_TYPE_FILE
        next if pps.size <= 0
        if pps.size < rh_info[:small_size]
          iSmbCnt  = pps.size / rh_info[:small_block_size]
          iSmbCnt += 1 if pps.size % rh_info[:small_block_size] > 0
          #1.1 Add to SBD
          0.upto(iSmbCnt-1-1) do |i|
            file.write([i + iSmBlk+1].pack("V"))
          end
          file.write([-2].pack("V"))

          #1.2 Add to Data String(this will be written for RootEntry)
          #Check for update
          if pps.pps_file
            pps.pps_file.seek(0) #To The Top
            while sBuff = pps.pps_file.read(4096)
              sRes << sBuff
            end
          else
            sRes << pps.data
          end
          if pps.size % rh_info[:small_block_size] > 0
            cnt = rh_info[:small_block_size] - (pps.size % rh_info[:small_block_size])
            sRes << "\0" * cnt
          end
          #1.3 Set for PPS
          pps.start_block = iSmBlk
          iSmBlk += iSmbCnt
        end
      end
    end
    iSbCnt = rh_info[:big_block_size] / LONG_INT_SIZE
    file.write([-1].pack("V") * (iSbCnt - (iSmBlk % iSbCnt))) if iSmBlk % iSbCnt > 0
    #2. Write SBD with adjusting length for block
    sRes
  end
  private :_makeSmallData

  def _savePpsWk(rh_info)
    #1. Write PPS
    file = rh_info[:fileh]
    data = [
          @name,
          ("\x00" * (64 - @name.bytesize)),  #64
          [@name.bytesize + 2].pack("v"),    #66
          [@type].pack("c"),                 #67
          [0x00].pack("c"),            #UK   #68
          [@prev_pps].pack("V"),       #Prev #72
          [@next_pps].pack("V"),       #Next #76
          [@dir_pps].pack("V"),        #Dir  #80
          "\x00\x09\x02\x00",                #84
          "\x00\x00\x00\x00",                #88
          "\xc0\x00\x00\x00",                #92
          "\x00\x00\x00\x46",                #96
          "\x00\x00\x00\x00",                #100
          localDate2OLE(@time_1st),          #108
          localDate2OLE(@time_2nd)           #116
      ]
    file.write(
      ruby_18 { data.join('') } ||
      ruby_19 { data.collect { |d| d.force_encoding(Encoding::BINARY) }.join('') }
      )
    if @start_block != 0
      file.write([@start_block].pack('V'))
    else
      file.write([0].pack('V'))
    end
    if @size != 0                               #124
      file.write([@size].pack('V'))
    else
      file.write([0].pack('V'))
    end
    file.write([0].pack('V'))                   #128
  end
  protected :_savePpsWk
end

class OLEStorageLitePPSRoot < OLEStorageLitePPS       #:nodoc:
  def initialize(raTime1st, raTime2nd, raChild)
    super(
      nil,
      asc2ucs('Root Entry'),
      PPS_TYPE_ROOT,
      nil,
      nil,
      nil,
      raTime1st,
      raTime2nd,
      nil,
      nil,
      nil,
      raChild)
  end

  def save(sFile, bNoAs = nil, rh_info = nil)
    #0.Initial Setting for saving
    rh_info = Hash.new unless rh_info
    if rh_info[:big_block_size]
      rh_info[:big_block_size] = 2 ** adjust2(rh_info[:big_block_size])
    else
      rh_info[:big_block_size] = 2 ** 9
    end
    if rh_info[:small_block_size]
      rh_info[:small_block_size] = 2 ** adjust2(rh_info[:small_block_size])
    else
      rh_info[:small_block_size] = 2 ** 6
    end
    rh_info[:small_size] = 0x1000
    rh_info[:pps_size]   = 0x80

    close_file = true

    #1.Open File
    #1.1 sFile is Ref of scalar
    if sFile.respond_to?(:to_str)
      rh_info[:fileh] = open(sFile, "wb")
    else
      rh_info[:fileh] = sFile.binmode
    end

    iBlk = 0
    #1. Make an array of PPS (for Save)
    aList=[]
    if bNoAs
      _savePpsSetPnt2([self], aList, rh_info)
    else
      _savePpsSetPnt([self], aList, rh_info)
    end
    iSBDcnt, iBBcnt, iPPScnt = _calcSize(aList, rh_info)

    #2.Save Header
    _saveHeader(rh_info, iSBDcnt, iBBcnt, iPPScnt)

    #3.Make Small Data string (write SBD)
    # Small Datas become RootEntry Data
    @data = _makeSmallData(aList, rh_info)

    #4. Write BB
    iBBlk = iSBDcnt
    _saveBigData(iBBlk, aList, rh_info)

    #5. Write PPS
    _savePps(aList, rh_info)

    #6. Write BD and BDList and Adding Header informations
    _saveBbd(iSBDcnt, iBBcnt, iPPScnt, rh_info)

    #7.Close File
    rh_info[:fileh].close if close_file
  end

  def _calcSize(aList, rh_info)
    #0. Calculate Basic Setting
    iSBDcnt, iBBcnt, iPPScnt = [0,0,0]
    iSmallLen = 0
    iSBcnt = 0
    aList.each do |pps|
      if pps.type == PPS_TYPE_FILE
        pps.size = pps._datalen      #Mod
        if pps.size < rh_info[:small_size]
          iSBcnt += pps.size / rh_info[:small_block_size]
          iSBcnt += 1 if pps.size % rh_info[:small_block_size] > 0
        else
          iBBcnt += pps.size / rh_info[:big_block_size]
          iBBcnt += 1 if pps.size % rh_info[:big_block_size] > 0
        end
      end
    end
    iSmallLen = iSBcnt * rh_info[:small_block_size]
    iSlCnt   = rh_info[:big_block_size] / LONG_INT_SIZE
    iSBDcnt  = iSBcnt / iSlCnt
    iSBDcnt += 1 if iSBcnt % iSlCnt > 0
    iBBcnt  += iSmallLen / rh_info[:big_block_size]
    iBBcnt  += 1 if iSmallLen % rh_info[:big_block_size] > 0
    iCnt     = aList.size
    iBdCnt   = rh_info[:big_block_size] / PPS_SIZE
    iPPScnt  = iCnt / iBdCnt
    iPPScnt += 1 if iCnt % iBdCnt > 0
    [iSBDcnt, iBBcnt, iPPScnt]
  end
  private :_calcSize

  def _adjust2(i2)
    iWk = Math.log(i2)/Math.log(2)
    iWk > Integer(iWk) ? Integer(iWk) + 1 : iWk
  end
  private :_adjust2

  def _saveHeader(rh_info, iSBDcnt, iBBcnt, iPPScnt)
    file = rh_info[:fileh]

    #0. Calculate Basic Setting
    iBlCnt = rh_info[:big_block_size] / LONG_INT_SIZE
    i1stBdL = (rh_info[:big_block_size] - 0x4C) / LONG_INT_SIZE
    i1stBdMax = i1stBdL * iBlCnt  - i1stBdL
    iBdExL = 0
    iAll = iBBcnt + iPPScnt + iSBDcnt
    iAllW = iAll
    iBdCntW  = iAllW / iBlCnt
    iBdCntW += 1 if iAllW % iBlCnt > 0
    iBdCnt = ((iAll + iBdCntW) / iBlCnt).to_i
    iBdCnt += ((iAllW + iBdCntW) % iBlCnt) == 0 ? 0 : 1
    if iBdCnt > i1stBdL
      #0.1 Calculate BD count
      iBlCnt -= 1 #the BlCnt is reduced in the count of the last sect is used for a pointer the next Bl
      iBBleftover = iAll - i1stBdMax
      if iAll >i1stBdMax
        iBdCnt, iBdExL, iBBleftover = calc_idbcnt_idbexl_ibbleftover(iBBleftover, iBlCnt, iBdCnt, iBdExL)
      end
      iBdCnt += i1stBdL
      #print "iBdCnt = iBdCnt \n"
    end

    #1.Save Header
    data = [
          "\xD0\xCF\x11\xE0\xA1\xB1\x1A\xE1",
          "\x00\x00\x00\x00" * 4,
          [0x3b].pack("v"),
          [0x03].pack("v"),
          [-2].pack("v"),
          [9].pack("v"),
          [6].pack("v"),
          [0].pack("v"),
          "\x00\x00\x00\x00" * 2,
          [iBdCnt].pack("V"),
          [iBBcnt+iSBDcnt].pack("V"),        #ROOT START
          [0].pack("V"),
          [0x1000].pack("V"),
          [iSBDcnt == 0 ? -2 : 0].pack("V"),                     #Small Block Depot
          [iSBDcnt].pack("V")
      ]
    file.write(
      ruby_18 { data.join('') } ||
      ruby_19 { data.collect { |d| d.force_encoding(Encoding::BINARY) }.join('') }
      )
    #2. Extra BDList Start, Count
    if iAll <= i1stBdMax
      file.write(
          [-2].pack("V")                   + #Extra BDList Start
          [0].pack("V")                      #Extra BDList Count
        )
    else
      file.write(
          [iAll + iBdCnt].pack("V")        +
          [iBdExL].pack("V")
        )
    end

    #3. BDList
      cnt = i1stBdL
      cnt = iBdCnt if iBdCnt < i1stBdL
      0.upto(cnt-1) do |i|
        file.write([iAll + i].pack("V"))
      end
      file.write([-1].pack("V") * (i1stBdL - cnt)) if cnt < i1stBdL
  end
  private :_saveHeader

  def _saveBigData(iStBlk, aList, rh_info)
    iRes = 0
    file = rh_info[:fileh]

    #1.Write Big (ge 0x1000) Data into Block
    aList.each do |pps|
      if pps.type != PPS_TYPE_DIR
        #print "PPS: pps DEF:", defined(pps->{Data}), "\n"
        pps.size = pps._datalen   #Mod
        if (pps.size >= rh_info[:small_size]) ||
           ((pps.type == PPS_TYPE_ROOT) && !pps.data.nil?)
          #1.1 Write Data
          #Check for update
          if pps.pps_file
            iLen = 0
            pps.pps_file.seek(0, 0) #To The Top
            while sBuff = pps.pps_file.read(4096)
              iLen += sBuff.bytesize
              file.write(sBuff)           #Check for update
            end
          else
            file.write(pps.data)
          end
          if pps.size % rh_info[:big_block_size] > 0
            file.write(
              "\x00" *
               (rh_info[:big_block_size] -
                    (pps.size % rh_info[:big_block_size]))
              )
          end
          #1.2 Set For PPS
          pps.start_block = iStBlk
          iStBlk += pps.size / rh_info[:big_block_size]
          iStBlk += 1 if pps.size % rh_info[:big_block_size] > 0
        end
      end
    end
  end

  def _savePps(aList, rh_info)
    #0. Initial
    file = rh_info[:fileh]
    #2. Save PPS
    aList.each do |oItem|
      oItem._savePpsWk(rh_info)
    end
    #3. Adjust for Block
    iCnt = aList.size
    iBCnt = rh_info[:big_block_size] / rh_info[:pps_size]
    if iCnt % iBCnt > 0
      file.write("\x00" * ((iBCnt - (iCnt % iBCnt)) * rh_info[:pps_size]))
    end
    (iCnt / iBCnt) + ((iCnt % iBCnt) > 0 ? 1: 0)
  end
  private :_savePps

  def _savePpsSetPnt(pps_array, aList, rh_info)
    #1. make Array as Children-Relations
    #1.1 if No Children
    if pps_array.nil? || pps_array.size == 0
        return 0xFFFFFFFF
    #1.2 Just Only one
    elsif pps_array.size == 1
      aList << pps_array[0]
      pps_array[0].no = aList.size - 1
      pps_array[0].prev_pps = 0xFFFFFFFF
      pps_array[0].next_pps = 0xFFFFFFFF
      pps_array[0].dir_pps  = _savePpsSetPnt(pps_array[0].child, aList, rh_info)
      return pps_array[0].no
    #1.3 Array
    else
      iCnt = pps_array.size
      #1.3.1 Define Center
      iPos = Integer(iCnt / 2.0)     #$iCnt

      aList.push(pps_array[iPos])
      pps_array[iPos].no = aList.size - 1

      aWk = pps_array.dup
      #1.3.2 Devide a array into Previous,Next
      aPrev = aWk[0, iPos]
      aWk[0..iPos-1] = []
      aNext = aWk[1, iCnt - iPos - 1]
      aWk[1..(1 + iCnt - iPos -1 -1)] = []
      pps_array[iPos].prev_pps = _savePpsSetPnt(aPrev, aList, rh_info)
      pps_array[iPos].next_pps = _savePpsSetPnt(aNext, aList, rh_info)
      pps_array[iPos].dir_pps  = _savePpsSetPnt(pps_array[iPos].child, aList, rh_info)
      return pps_array[iPos].no
    end
  end
  private :_savePpsSetPnt

  def _savePpsSetPnt2(pps_array, aList, rh_info)
    #1. make Array as Children-Relations
    #1.1 if No Children
    if pps_array.nil? || pps_array.size == 0
        return 0xFFFFFFFF
    #1.2 Just Only one
    elsif pps_array.size == 1
      aList << pps_array[0]
      pps_array[0].no = aList.size - 1
      pps_array[0].prev_pps = 0xFFFFFFFF
      pps_array[0].next_pps = 0xFFFFFFFF
      pps_array[0].dir_pps  = _savePpsSetPnt2(pps_array[0].child, aList, rh_info)
      return pps_array[0].no
    #1.3 Array
    else
      iCnt = pps_array.size
      #1.3.1 Define Center
      iPos = 0  #int($iCnt/ 2);     #$iCnt

      aWk = pps_array.dup
      aPrev = aWk[1, 1]
      aWk[1..1] = []
      aNext = aWk[1..aWk.size]      #, $iCnt - $iPos -1);
      pps_array[iPos].prev_pps = _savePpsSetPnt2(pps_array, aList, rh_info)
      aList.push(pps_array[iPos])
      pps_array[iPos].no = aList.size

      #1.3.2 Devide a array into Previous,Next
      pps_array[iPos].next_pps = _savePpsSetPnt2(aNext, aList, rh_info)
      pps_array[iPos].dir_pps  = _savePpsSetPnt2(pps_array[iPos].child, aList, rh_info)
      return pps_array[iPos].no
    end
  end
  private :_savePpsSetPnt2

  def _saveBbd(iSbdSize, iBsize, iPpsCnt, rh_info)
    file = rh_info[:fileh]
    #0. Calculate Basic Setting
    iBbCnt    = rh_info[:big_block_size] / LONG_INT_SIZE
    iBlCnt    = iBbCnt - 1
    i1stBdL   = (rh_info[:big_block_size] - 0x4C) / LONG_INT_SIZE
    i1stBdMax = i1stBdL * iBbCnt  - i1stBdL
    iBdExL    = 0
    iAll      = iBsize + iPpsCnt + iSbdSize
    iAllW     = iAll
    iBdCntW   = iAllW / iBbCnt
    iBdCntW  += 1 if iAllW % iBbCnt > 0
    iBdCnt    = 0
    #0.1 Calculate BD count
    iBBleftover = iAll - i1stBdMax
    if iAll >i1stBdMax
      iBdCnt, iBdExL, iBBleftover = calc_idbcnt_idbexl_ibbleftover(iBBleftover, iBlCnt, iBdCnt, iBdExL)
    end
    iAllW  += iBdExL
    iBdCnt += i1stBdL
    #print "iBdCnt = iBdCnt \n"

    #1. Making BD
    #1.1 Set for SBD
    if iSbdSize > 0
      0.upto(iSbdSize-1-1) do |i|
        file.write([i + 1].pack('V'))
      end
      file.write([-2].pack('V'))
    end
    #1.2 Set for B
    0.upto(iBsize-1-1) do |i|
      file.write([i + iSbdSize + 1].pack('V'))
    end
    file.write([-2].pack('V'))

    #1.3 Set for PPS
    0.upto(iPpsCnt-1-1) do |i|
      file.write([i+iSbdSize+iBsize+1].pack("V"))
    end
    file.write([-2].pack('V'))
    #1.4 Set for BBD itself ( 0xFFFFFFFD : BBD)
    0.upto(iBdCnt-1) do |i|
      file.write([0xFFFFFFFD].pack("V"))
    end
    #1.5 Set for ExtraBDList
    0.upto(iBdExL-1) do |i|
      file.write([0xFFFFFFFC].pack("V"))
    end
    #1.6 Adjust for Block
    if (iAllW + iBdCnt) % iBbCnt > 0
      file.write([-1].pack('V') *  (iBbCnt - ((iAllW + iBdCnt) % iBbCnt)))
    end
    #2.Extra BDList
    if iBdCnt > i1stBdL
      iN  = 0
      iNb = 0
      i1stBdL.upto(iBdCnt-1) do |i|
        if iN >= iBbCnt-1
          iN   = 0
          iNb += 1
          file.write([iAll+iBdCnt+iNb].pack("V"))
        end
        file.write([iBsize+iSbdSize+iPpsCnt+i].pack("V"))
        iN += 1
      end
      if (iBdCnt-i1stBdL) % (iBbCnt-1) > 0
        file.write([-1].pack("V") * ((iBbCnt-1) - ((iBdCnt-i1stBdL) % (iBbCnt-1))))
      end
      file.write([-2].pack('V'))
    end
  end

  def calc_idbcnt_idbexl_ibbleftover(iBBleftover, iBlCnt, iBdCnt, iBdExL)
    while true
      iBdCnt       = iBBleftover / iBlCnt
      iBdCnt      += 1 if iBBleftover % iBlCnt > 0
      iBdExL       = iBdCnt / iBlCnt
      iBdExL      += 1 if iBdCnt % iBlCnt > 0
      iBBleftover += iBdExL
      break if iBdCnt == iBBleftover / iBlCnt + (iBBleftover % iBlCnt > 0 ? 1 : 0)
    end
    [iBdCnt, iBdExL, iBBleftover]
  end
  private :calc_idbcnt_idbexl_ibbleftover
end

class OLEStorageLitePPSFile < OLEStorageLitePPS       #:nodoc:
  def initialize(sNm, data = '')
    super(
        nil,
        sNm || '',
        PPS_TYPE_FILE,
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        data || '',
        nil
      )
  end

  def set_file(sFile = '')
    if sFile.nil? or sFile == ''
      @pps_file = Tempfile.new('OLEStorageLitePPSFile')
    elsif sFile.respond_to?(:write)
      @pps_file = sFile
    elsif sFile.respond_to?(:to_str)
      #File Name
      @pps_file = open(sFile, "r+")
      return nil unless @pps_file
    else
      return nil
    end
    @pps_file.seek(0, IO::SEEK_END)
    @pps_file.binmode
  end

  def append (data)
    return if data.nil?
    if @pps_file
      @pps_file << data
      @pps_file.flush
    else
      @data << data
    end
  end
end
