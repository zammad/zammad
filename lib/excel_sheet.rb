# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ExcelSheet

  def initialize(title:, header:, records:, locale:, timezone: nil)
    @title           = title
    @header          = header
    @records         = records
    @timezone        = timezone.presence || Setting.get('timezone_default')
    @locale          = locale || Locale.default
    @tempfile        = Tempfile.new('excel-export.xls')
    @workbook        = WriteExcel.new(@tempfile)
    @worksheet       = @workbook.add_worksheet
    @contents        = nil
    @current_row     = 0
    @current_column  = 0

    @lookup_cache = {}

    @format_time = @workbook.add_format(num_format: 'yyyy-mm-dd hh:mm:ss')
    @format_date = @workbook.add_format(num_format: 'yyyy-mm-dd')

    @format_headline = @workbook.add_format
    @format_headline.set_bold
    @format_headline.set_size(14)
    @format_headline.set_color('black')

    @format_header = @workbook.add_format
    @format_header.set_italic
    @format_header.set_bg_color('gray')
    @format_header.set_color('white')

    @format_footer = @workbook.add_format
    @format_footer.set_italic
    @format_footer.set_color('gray')
    @format_footer.set_size(8)
  end

  def contents
    file = File.new(@tempfile, 'r')
    contents = file.read
    file.close
    contents
  end

  def content
    gen_header
    gen_rows
    gen_footer
    contents
  end

  def gen_header
    @worksheet.write_string(@current_row, @current_column, @title, @format_headline)
    @worksheet.set_row(0, 18)

    @current_row += 2
    @current_column = 0
    @header.each do |header|
      if header[:width]
        @worksheet.set_column(@current_column, @current_column, header[:width])
      end
      @worksheet.write_string(@current_row, @current_column, header[:display] || header[:name], @format_header)
      @current_column += 1
    end
  end

  def gen_rows
    @records.each do |record|
      gen_row_by_array(record)
    end
  end

  def gen_row_by_array(record)
    @current_row += 1
    @current_column = 0
    record.each do |item|
      begin
        if item.acts_like?(:time) || item.acts_like?(:date)
          value_convert(item, nil, { data_type: 'datetime' })
        elsif item.is_a?(Integer) || item.is_a?(Float)
          value_convert(item, nil, { data_type: 'integer' })
        else
          value_convert(item, nil, { data_type: 'string' })
        end
      rescue => e
        Rails.logger.error e
      end
      @current_column += 1
    end
  end

  def gen_row_by_header(record, additional = {})
    @current_row += 1
    @current_column = 0
    @header.each do |header|
      begin
        value_convert(record, header[:name], header, additional)
      rescue => e
        Rails.logger.error e
      end
      @current_column += 1
    end
  end

  def gen_footer
    @current_row += 2
    @worksheet.write_string(@current_row, 0, "#{Translation.translate(@locale, 'Timezone')}: #{@timezone}", @format_footer)
    @workbook.close
  end

  def timestamp_in_localtime(time)
    return if time.blank?

    time.in_time_zone(@timezone).strftime('%F %T') # "2019-08-19 16:21:52"
  end

  def value_lookup(record, attribute, additional)
    value = record[attribute.to_sym]
    if attribute[-3, 3] == '_id'
      ref = attribute[0, attribute.length - 3]
      if record.respond_to?(ref.to_sym)
        @lookup_cache[attribute] ||= {}
        return @lookup_cache[attribute][value] if @lookup_cache[attribute][value]

        ref_object = record.send(ref.to_sym)
        ref_name = value
        if ref_object.respond_to?(:fullname)
          ref_name = ref_object.fullname
        elsif ref_object.respond_to?(:name)
          ref_name = ref_object.name
        end
        @lookup_cache[attribute][value] = ref_name
        return ref_name
      end
    end
    value = record.try(attribute)

    # if no value exists, check additional values
    if !value && additional && additional[attribute.to_sym]
      value = additional[attribute.to_sym]
    end
    if value.is_a?(Array)
      value = value.join(',')
    end
    value
  end

  def value_convert(record, attribute, object, additional = {})
    value = if attribute
              value_lookup(record, attribute, additional)
            else
              record
            end
    case object[:data_type]
    when 'boolean', 'select'
      if object[:data_option] && object[:data_option]['options'] && object[:data_option]['options'][value]
        value = object[:data_option]['options'][value]
      end
      @worksheet.write_string(@current_row, @current_column, value) if value.present?
    when 'datetime'
      @worksheet.write_date_time(@current_row, @current_column, timestamp_in_localtime(value), @format_time) if value.present?
    when 'date'
      @worksheet.write_date_time(@current_row, @current_column, value.to_s, @format_date) if value.present?
    when 'integer'
      @worksheet.write_number(@current_row, @current_column, value) if value.present?
    else
      @worksheet.write_string(@current_row, @current_column, value.to_s) if value.present?
    end
  end

end
