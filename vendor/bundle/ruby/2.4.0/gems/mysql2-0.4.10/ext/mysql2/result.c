#include <mysql2_ext.h>

#include "mysql_enc_to_ruby.h"

#ifdef HAVE_RUBY_ENCODING_H
static rb_encoding *binaryEncoding;
#endif

#if (SIZEOF_INT < SIZEOF_LONG) || defined(HAVE_RUBY_ENCODING_H)
/* on 64bit platforms we can handle dates way outside 2038-01-19T03:14:07
 *
 * (9999*31557600) + (12*2592000) + (31*86400) + (11*3600) + (59*60) + 59
 */
#define MYSQL2_MAX_TIME 315578267999ULL
#else
/**
 * On 32bit platforms the maximum date the Time class can handle is 2038-01-19T03:14:07
 * 2038 years + 1 month + 19 days + 3 hours + 14 minutes + 7 seconds = 64318634047 seconds
 *
 * (2038*31557600) + (1*2592000) + (19*86400) + (3*3600) + (14*60) + 7
 */
#define MYSQL2_MAX_TIME 64318634047ULL
#endif

#if defined(HAVE_RUBY_ENCODING_H)
/* 0000-1-1 00:00:00 UTC
 *
 * (0*31557600) + (1*2592000) + (1*86400) + (0*3600) + (0*60) + 0
 */
#define MYSQL2_MIN_TIME 2678400ULL
#elif SIZEOF_INT < SIZEOF_LONG /* 64bit Ruby 1.8 */
/* 0139-1-1 00:00:00 UTC
 *
 * (139*31557600) + (1*2592000) + (1*86400) + (0*3600) + (0*60) + 0
 */
#define MYSQL2_MIN_TIME 4389184800ULL
#elif defined(NEGATIVE_TIME_T)
/* 1901-12-13 20:45:52 UTC : The oldest time in 32-bit signed time_t.
 *
 * (1901*31557600) + (12*2592000) + (13*86400) + (20*3600) + (45*60) + 52
 */
#define MYSQL2_MIN_TIME 60023299552ULL
#else
/* 1970-01-01 00:00:01 UTC : The Unix epoch - the oldest time in portable time_t.
 *
 * (1970*31557600) + (1*2592000) + (1*86400) + (0*3600) + (0*60) + 1
 */
#define MYSQL2_MIN_TIME 62171150401ULL
#endif

#define GET_RESULT(self) \
  mysql2_result_wrapper *wrapper; \
  Data_Get_Struct(self, mysql2_result_wrapper, wrapper);

typedef struct {
  int symbolizeKeys;
  int asArray;
  int castBool;
  int cacheRows;
  int cast;
  int streaming;
  ID db_timezone;
  ID app_timezone;
  VALUE block_given;
} result_each_args;

VALUE cBigDecimal, cDateTime, cDate;
static VALUE cMysql2Result;
static VALUE opt_decimal_zero, opt_float_zero, opt_time_year, opt_time_month, opt_utc_offset;
extern VALUE mMysql2, cMysql2Client, cMysql2Error;
static ID intern_new, intern_utc, intern_local, intern_localtime, intern_local_offset, intern_civil, intern_new_offset;
static VALUE sym_symbolize_keys, sym_as, sym_array, sym_database_timezone, sym_application_timezone,
          sym_local, sym_utc, sym_cast_booleans, sym_cache_rows, sym_cast, sym_stream, sym_name;
static ID intern_merge;

/* Mark any VALUEs that are only referenced in C, so the GC won't get them. */
static void rb_mysql_result_mark(void * wrapper) {
  mysql2_result_wrapper * w = wrapper;
  if (w) {
    rb_gc_mark(w->fields);
    rb_gc_mark(w->rows);
    rb_gc_mark(w->encoding);
    rb_gc_mark(w->client);
    rb_gc_mark(w->statement);
  }
}

/* this may be called manually or during GC */
static void rb_mysql_result_free_result(mysql2_result_wrapper * wrapper) {
  if (!wrapper) return;

  if (wrapper->resultFreed != 1) {
    if (wrapper->stmt_wrapper) {
      if (!wrapper->stmt_wrapper->closed) {
        mysql_stmt_free_result(wrapper->stmt_wrapper->stmt);

        /* MySQL BUG? If the statement handle was previously used, and so
         * mysql_stmt_bind_result was called, and if that result set and bind buffers were freed,
         * MySQL still thinks the result set buffer is available and will prefetch the
         * first result in mysql_stmt_execute. This will corrupt or crash the program.
         * By setting bind_result_done back to 0, we make MySQL think that a result set
         * has never been bound to this statement handle before to prevent the prefetch.
         */
        wrapper->stmt_wrapper->stmt->bind_result_done = 0;
      }

      if (wrapper->statement != Qnil) {
        decr_mysql2_stmt(wrapper->stmt_wrapper);
      }

      if (wrapper->result_buffers) {
        unsigned int i;
        for (i = 0; i < wrapper->numberOfFields; i++) {
          if (wrapper->result_buffers[i].buffer) {
            xfree(wrapper->result_buffers[i].buffer);
          }
        }
        xfree(wrapper->result_buffers);
        xfree(wrapper->is_null);
        xfree(wrapper->error);
        xfree(wrapper->length);
      }
      /* Clue that the next statement execute will need to allocate a new result buffer. */
      wrapper->result_buffers = NULL;
    }
    /* FIXME: this may call flush_use_result, which can hit the socket */
    /* For prepared statements, wrapper->result is the result metadata */
    mysql_free_result(wrapper->result);
    wrapper->resultFreed = 1;
  }
}

/* this is called during GC */
static void rb_mysql_result_free(void *ptr) {
  mysql2_result_wrapper *wrapper = ptr;
  rb_mysql_result_free_result(wrapper);

  // If the GC gets to client first it will be nil
  if (wrapper->client != Qnil) {
    decr_mysql2_client(wrapper->client_wrapper);
  }

  xfree(wrapper);
}

static VALUE rb_mysql_result_free_(VALUE self) {
  GET_RESULT(self);
  rb_mysql_result_free_result(wrapper);
  return Qnil;
}

/*
 * for small results, this won't hit the network, but there's no
 * reliable way for us to tell this so we'll always release the GVL
 * to be safe
 */
static void *nogvl_fetch_row(void *ptr) {
  MYSQL_RES *result = ptr;

  return mysql_fetch_row(result);
}

static void *nogvl_stmt_fetch(void *ptr) {
  MYSQL_STMT *stmt = ptr;
  uintptr_t r = mysql_stmt_fetch(stmt);

  return (void *)r;
}

static VALUE rb_mysql_result_fetch_field(VALUE self, unsigned int idx, int symbolize_keys) {
  VALUE rb_field;
  GET_RESULT(self);

  if (wrapper->fields == Qnil) {
    wrapper->numberOfFields = mysql_num_fields(wrapper->result);
    wrapper->fields = rb_ary_new2(wrapper->numberOfFields);
  }

  rb_field = rb_ary_entry(wrapper->fields, idx);
  if (rb_field == Qnil) {
    MYSQL_FIELD *field = NULL;
#ifdef HAVE_RUBY_ENCODING_H
    rb_encoding *default_internal_enc = rb_default_internal_encoding();
    rb_encoding *conn_enc = rb_to_encoding(wrapper->encoding);
#endif

    field = mysql_fetch_field_direct(wrapper->result, idx);
    if (symbolize_keys) {
#ifdef HAVE_RB_INTERN3
      rb_field = rb_intern3(field->name, field->name_length, rb_utf8_encoding());
      rb_field = ID2SYM(rb_field);
#else
      VALUE colStr;
      colStr = rb_str_new(field->name, field->name_length);
      rb_field = ID2SYM(rb_to_id(colStr));
#endif
    } else {
      rb_field = rb_str_new(field->name, field->name_length);
#ifdef HAVE_RUBY_ENCODING_H
      rb_enc_associate(rb_field, conn_enc);
      if (default_internal_enc) {
        rb_field = rb_str_export_to_enc(rb_field, default_internal_enc);
      }
#endif
    }
    rb_ary_store(wrapper->fields, idx, rb_field);
  }

  return rb_field;
}

#ifdef HAVE_RUBY_ENCODING_H
static VALUE mysql2_set_field_string_encoding(VALUE val, MYSQL_FIELD field, rb_encoding *default_internal_enc, rb_encoding *conn_enc) {
  /* if binary flag is set, respect its wishes */
  if (field.flags & BINARY_FLAG && field.charsetnr == 63) {
    rb_enc_associate(val, binaryEncoding);
  } else if (!field.charsetnr) {
    /* MySQL 4.x may not provide an encoding, binary will get the bytes through */
    rb_enc_associate(val, binaryEncoding);
  } else {
    /* lookup the encoding configured on this field */
    const char *enc_name;
    int enc_index;

    enc_name = mysql2_mysql_enc_to_rb[field.charsetnr-1];
    if (enc_name != NULL) {
      /* use the field encoding we were able to match */
      enc_index = rb_enc_find_index(enc_name);
      rb_enc_set_index(val, enc_index);
    } else {
      /* otherwise fall-back to the connection's encoding */
      rb_enc_associate(val, conn_enc);
    }

    if (default_internal_enc) {
      val = rb_str_export_to_enc(val, default_internal_enc);
    }
  }
  return val;
}
#endif

/* Interpret microseconds digits left-aligned in fixed-width field.
 * e.g. 10.123 seconds means 10 seconds and 123000 microseconds,
 * because the microseconds are to the right of the decimal point.
 */
static unsigned int msec_char_to_uint(char *msec_char, size_t len)
{
  size_t i;
  for (i = 0; i < (len - 1); i++) {
    if (msec_char[i] == '\0') {
      msec_char[i] = '0';
    }
  }
  return (unsigned int)strtoul(msec_char, NULL, 10);
}

static void rb_mysql_result_alloc_result_buffers(VALUE self, MYSQL_FIELD *fields) {
  unsigned int i;
  GET_RESULT(self);

  if (wrapper->result_buffers != NULL) return;

  wrapper->result_buffers = xcalloc(wrapper->numberOfFields, sizeof(MYSQL_BIND));
  wrapper->is_null = xcalloc(wrapper->numberOfFields, sizeof(bool));
  wrapper->error = xcalloc(wrapper->numberOfFields, sizeof(bool));
  wrapper->length = xcalloc(wrapper->numberOfFields, sizeof(unsigned long));

  for (i = 0; i < wrapper->numberOfFields; i++) {
    wrapper->result_buffers[i].buffer_type = fields[i].type;

    //      mysql type    |            C type
    switch(fields[i].type) {
      case MYSQL_TYPE_NULL:         // NULL
        break;
      case MYSQL_TYPE_TINY:         // signed char
        wrapper->result_buffers[i].buffer = xcalloc(1, sizeof(signed char));
        wrapper->result_buffers[i].buffer_length = sizeof(signed char);
        break;
      case MYSQL_TYPE_SHORT:        // short int
        wrapper->result_buffers[i].buffer = xcalloc(1, sizeof(short int));
        wrapper->result_buffers[i].buffer_length = sizeof(short int);
        break;
      case MYSQL_TYPE_INT24:        // int
      case MYSQL_TYPE_LONG:         // int
      case MYSQL_TYPE_YEAR:         // int
        wrapper->result_buffers[i].buffer = xcalloc(1, sizeof(int));
        wrapper->result_buffers[i].buffer_length = sizeof(int);
        break;
      case MYSQL_TYPE_LONGLONG:     // long long int
        wrapper->result_buffers[i].buffer = xcalloc(1, sizeof(long long int));
        wrapper->result_buffers[i].buffer_length = sizeof(long long int);
        break;
      case MYSQL_TYPE_FLOAT:        // float
      case MYSQL_TYPE_DOUBLE:       // double
        wrapper->result_buffers[i].buffer = xcalloc(1, sizeof(double));
        wrapper->result_buffers[i].buffer_length = sizeof(double);
        break;
      case MYSQL_TYPE_TIME:         // MYSQL_TIME
      case MYSQL_TYPE_DATE:         // MYSQL_TIME
      case MYSQL_TYPE_NEWDATE:      // MYSQL_TIME
      case MYSQL_TYPE_DATETIME:     // MYSQL_TIME
      case MYSQL_TYPE_TIMESTAMP:    // MYSQL_TIME
        wrapper->result_buffers[i].buffer = xcalloc(1, sizeof(MYSQL_TIME));
        wrapper->result_buffers[i].buffer_length = sizeof(MYSQL_TIME);
        break;
      case MYSQL_TYPE_DECIMAL:      // char[]
      case MYSQL_TYPE_NEWDECIMAL:   // char[]
      case MYSQL_TYPE_STRING:       // char[]
      case MYSQL_TYPE_VAR_STRING:   // char[]
      case MYSQL_TYPE_VARCHAR:      // char[]
      case MYSQL_TYPE_TINY_BLOB:    // char[]
      case MYSQL_TYPE_BLOB:         // char[]
      case MYSQL_TYPE_MEDIUM_BLOB:  // char[]
      case MYSQL_TYPE_LONG_BLOB:    // char[]
      case MYSQL_TYPE_BIT:          // char[]
      case MYSQL_TYPE_SET:          // char[]
      case MYSQL_TYPE_ENUM:         // char[]
      case MYSQL_TYPE_GEOMETRY:     // char[]
      default:
        wrapper->result_buffers[i].buffer = xmalloc(fields[i].max_length);
        wrapper->result_buffers[i].buffer_length = fields[i].max_length;
        break;
    }

    wrapper->result_buffers[i].is_null = &wrapper->is_null[i];
    wrapper->result_buffers[i].length  = &wrapper->length[i];
    wrapper->result_buffers[i].error   = &wrapper->error[i];
    wrapper->result_buffers[i].is_unsigned = ((fields[i].flags & UNSIGNED_FLAG) != 0);
  }
}

static VALUE rb_mysql_result_fetch_row_stmt(VALUE self, MYSQL_FIELD * fields, const result_each_args *args)
{
  VALUE rowVal;
  unsigned int i = 0;

#ifdef HAVE_RUBY_ENCODING_H
  rb_encoding *default_internal_enc;
  rb_encoding *conn_enc;
#endif
  GET_RESULT(self);

#ifdef HAVE_RUBY_ENCODING_H
  default_internal_enc = rb_default_internal_encoding();
  conn_enc = rb_to_encoding(wrapper->encoding);
#endif

  if (wrapper->fields == Qnil) {
    wrapper->numberOfFields = mysql_num_fields(wrapper->result);
    wrapper->fields = rb_ary_new2(wrapper->numberOfFields);
  }
  if (args->asArray) {
    rowVal = rb_ary_new2(wrapper->numberOfFields);
  } else {
    rowVal = rb_hash_new();
  }

  if (wrapper->result_buffers == NULL) {
    rb_mysql_result_alloc_result_buffers(self, fields);
  }

  if (mysql_stmt_bind_result(wrapper->stmt_wrapper->stmt, wrapper->result_buffers)) {
    rb_raise_mysql2_stmt_error(wrapper->stmt_wrapper);
  }

  {
    switch((uintptr_t)rb_thread_call_without_gvl(nogvl_stmt_fetch, wrapper->stmt_wrapper->stmt, RUBY_UBF_IO, 0)) {
      case 0:
        /* success */
        break;

      case 1:
        /* error */
        rb_raise_mysql2_stmt_error(wrapper->stmt_wrapper);

      case MYSQL_NO_DATA:
        /* no more row */
        return Qnil;

      case MYSQL_DATA_TRUNCATED:
        rb_raise(cMysql2Error, "IMPLBUG: caught MYSQL_DATA_TRUNCATED. should not come here as buffer_length is set to fields[i].max_length.");
    }
  }

  for (i = 0; i < wrapper->numberOfFields; i++) {
    VALUE field = rb_mysql_result_fetch_field(self, i, args->symbolizeKeys);
    VALUE val = Qnil;
    MYSQL_TIME *ts;

    if (wrapper->is_null[i]) {
      val = Qnil;
    } else {
      const MYSQL_BIND* const result_buffer = &wrapper->result_buffers[i];

      switch(result_buffer->buffer_type) {
        case MYSQL_TYPE_TINY:         // signed char
          if (args->castBool && fields[i].length == 1) {
            val = (*((unsigned char*)result_buffer->buffer) != 0) ? Qtrue : Qfalse;
            break;
          }
          if (result_buffer->is_unsigned) {
            val = UINT2NUM(*((unsigned char*)result_buffer->buffer));
          } else {
            val = INT2NUM(*((signed char*)result_buffer->buffer));
          }
          break;
        case MYSQL_TYPE_BIT:        /* BIT field (MySQL 5.0.3 and up) */
          if (args->castBool && fields[i].length == 1) {
            val = (*((unsigned char*)result_buffer->buffer) != 0) ? Qtrue : Qfalse;
          }else{
            val = rb_str_new(result_buffer->buffer, *(result_buffer->length));
          }
          break;
        case MYSQL_TYPE_SHORT:        // short int
          if (result_buffer->is_unsigned) {
            val = UINT2NUM(*((unsigned short int*)result_buffer->buffer));
          } else  {
            val = INT2NUM(*((short int*)result_buffer->buffer));
          }
          break;
        case MYSQL_TYPE_INT24:        // int
        case MYSQL_TYPE_LONG:         // int
        case MYSQL_TYPE_YEAR:         // int
          if (result_buffer->is_unsigned) {
            val = UINT2NUM(*((unsigned int*)result_buffer->buffer));
          } else {
            val = INT2NUM(*((int*)result_buffer->buffer));
          }
          break;
        case MYSQL_TYPE_LONGLONG:     // long long int
          if (result_buffer->is_unsigned) {
            val = ULL2NUM(*((unsigned long long int*)result_buffer->buffer));
          } else {
            val = LL2NUM(*((long long int*)result_buffer->buffer));
          }
          break;
        case MYSQL_TYPE_FLOAT:        // float
          val = rb_float_new((double)(*((float*)result_buffer->buffer)));
          break;
        case MYSQL_TYPE_DOUBLE:       // double
          val = rb_float_new((double)(*((double*)result_buffer->buffer)));
          break;
        case MYSQL_TYPE_DATE:         // MYSQL_TIME
        case MYSQL_TYPE_NEWDATE:      // MYSQL_TIME
          ts = (MYSQL_TIME*)result_buffer->buffer;
          val = rb_funcall(cDate, intern_new, 3, INT2NUM(ts->year), INT2NUM(ts->month), INT2NUM(ts->day));
          break;
        case MYSQL_TYPE_TIME:         // MYSQL_TIME
          ts = (MYSQL_TIME*)result_buffer->buffer;
          val = rb_funcall(rb_cTime, args->db_timezone, 7, opt_time_year, opt_time_month, opt_time_month, UINT2NUM(ts->hour), UINT2NUM(ts->minute), UINT2NUM(ts->second), ULONG2NUM(ts->second_part));
          if (!NIL_P(args->app_timezone)) {
            if (args->app_timezone == intern_local) {
              val = rb_funcall(val, intern_localtime, 0);
            } else { // utc
              val = rb_funcall(val, intern_utc, 0);
            }
          }
          break;
        case MYSQL_TYPE_DATETIME:     // MYSQL_TIME
        case MYSQL_TYPE_TIMESTAMP: {  // MYSQL_TIME
          uint64_t seconds;

          ts = (MYSQL_TIME*)result_buffer->buffer;
          seconds = (ts->year*31557600ULL) + (ts->month*2592000ULL) + (ts->day*86400ULL) + (ts->hour*3600ULL) + (ts->minute*60ULL) + ts->second;

          if (seconds < MYSQL2_MIN_TIME || seconds > MYSQL2_MAX_TIME) { // use DateTime instead
            VALUE offset = INT2NUM(0);
            if (args->db_timezone == intern_local) {
              offset = rb_funcall(cMysql2Client, intern_local_offset, 0);
            }
            val = rb_funcall(cDateTime, intern_civil, 7, UINT2NUM(ts->year), UINT2NUM(ts->month), UINT2NUM(ts->day), UINT2NUM(ts->hour), UINT2NUM(ts->minute), UINT2NUM(ts->second), offset);
            if (!NIL_P(args->app_timezone)) {
              if (args->app_timezone == intern_local) {
                offset = rb_funcall(cMysql2Client, intern_local_offset, 0);
                val = rb_funcall(val, intern_new_offset, 1, offset);
              } else { // utc
                val = rb_funcall(val, intern_new_offset, 1, opt_utc_offset);
              }
            }
          } else {
            val = rb_funcall(rb_cTime, args->db_timezone, 7, UINT2NUM(ts->year), UINT2NUM(ts->month), UINT2NUM(ts->day), UINT2NUM(ts->hour), UINT2NUM(ts->minute), UINT2NUM(ts->second), ULONG2NUM(ts->second_part));
            if (!NIL_P(args->app_timezone)) {
              if (args->app_timezone == intern_local) {
                val = rb_funcall(val, intern_localtime, 0);
              } else { // utc
                val = rb_funcall(val, intern_utc, 0);
              }
            }
          }
          break;
        }
        case MYSQL_TYPE_DECIMAL:      // char[]
        case MYSQL_TYPE_NEWDECIMAL:   // char[]
          val = rb_funcall(cBigDecimal, intern_new, 1, rb_str_new(result_buffer->buffer, *(result_buffer->length)));
          break;
        case MYSQL_TYPE_STRING:       // char[]
        case MYSQL_TYPE_VAR_STRING:   // char[]
        case MYSQL_TYPE_VARCHAR:      // char[]
        case MYSQL_TYPE_TINY_BLOB:    // char[]
        case MYSQL_TYPE_BLOB:         // char[]
        case MYSQL_TYPE_MEDIUM_BLOB:  // char[]
        case MYSQL_TYPE_LONG_BLOB:    // char[]
        case MYSQL_TYPE_SET:          // char[]
        case MYSQL_TYPE_ENUM:         // char[]
        case MYSQL_TYPE_GEOMETRY:     // char[]
        default:
          val = rb_str_new(result_buffer->buffer, *(result_buffer->length));
#ifdef HAVE_RUBY_ENCODING_H
          val = mysql2_set_field_string_encoding(val, fields[i], default_internal_enc, conn_enc);
#endif
          break;
      }
    }

    if (args->asArray) {
      rb_ary_push(rowVal, val);
    } else {
      rb_hash_aset(rowVal, field, val);
    }
  }

  return rowVal;
}

static VALUE rb_mysql_result_fetch_row(VALUE self, MYSQL_FIELD * fields, const result_each_args *args)
{
  VALUE rowVal;
  MYSQL_ROW row;
  unsigned int i = 0;
  unsigned long * fieldLengths;
  void * ptr;
#ifdef HAVE_RUBY_ENCODING_H
  rb_encoding *default_internal_enc;
  rb_encoding *conn_enc;
#endif
  GET_RESULT(self);

#ifdef HAVE_RUBY_ENCODING_H
  default_internal_enc = rb_default_internal_encoding();
  conn_enc = rb_to_encoding(wrapper->encoding);
#endif

  ptr = wrapper->result;
  row = (MYSQL_ROW)rb_thread_call_without_gvl(nogvl_fetch_row, ptr, RUBY_UBF_IO, 0);
  if (row == NULL) {
    return Qnil;
  }

  if (wrapper->fields == Qnil) {
    wrapper->numberOfFields = mysql_num_fields(wrapper->result);
    wrapper->fields = rb_ary_new2(wrapper->numberOfFields);
  }
  if (args->asArray) {
    rowVal = rb_ary_new2(wrapper->numberOfFields);
  } else {
    rowVal = rb_hash_new();
  }
  fieldLengths = mysql_fetch_lengths(wrapper->result);

  for (i = 0; i < wrapper->numberOfFields; i++) {
    VALUE field = rb_mysql_result_fetch_field(self, i, args->symbolizeKeys);
    if (row[i]) {
      VALUE val = Qnil;
      enum enum_field_types type = fields[i].type;

      if (!args->cast) {
        if (type == MYSQL_TYPE_NULL) {
          val = Qnil;
        } else {
          val = rb_str_new(row[i], fieldLengths[i]);
#ifdef HAVE_RUBY_ENCODING_H
          val = mysql2_set_field_string_encoding(val, fields[i], default_internal_enc, conn_enc);
#endif
        }
      } else {
        switch(type) {
        case MYSQL_TYPE_NULL:       /* NULL-type field */
          val = Qnil;
          break;
        case MYSQL_TYPE_BIT:        /* BIT field (MySQL 5.0.3 and up) */
          if (args->castBool && fields[i].length == 1) {
            val = *row[i] == 1 ? Qtrue : Qfalse;
          }else{
            val = rb_str_new(row[i], fieldLengths[i]);
          }
          break;
        case MYSQL_TYPE_TINY:       /* TINYINT field */
          if (args->castBool && fields[i].length == 1) {
            val = *row[i] != '0' ? Qtrue : Qfalse;
            break;
          }
        case MYSQL_TYPE_SHORT:      /* SMALLINT field */
        case MYSQL_TYPE_LONG:       /* INTEGER field */
        case MYSQL_TYPE_INT24:      /* MEDIUMINT field */
        case MYSQL_TYPE_LONGLONG:   /* BIGINT field */
        case MYSQL_TYPE_YEAR:       /* YEAR field */
          val = rb_cstr2inum(row[i], 10);
          break;
        case MYSQL_TYPE_DECIMAL:    /* DECIMAL or NUMERIC field */
        case MYSQL_TYPE_NEWDECIMAL: /* Precision math DECIMAL or NUMERIC field (MySQL 5.0.3 and up) */
          if (fields[i].decimals == 0) {
            val = rb_cstr2inum(row[i], 10);
          } else if (strtod(row[i], NULL) == 0.000000){
            val = rb_funcall(cBigDecimal, intern_new, 1, opt_decimal_zero);
          }else{
            val = rb_funcall(cBigDecimal, intern_new, 1, rb_str_new(row[i], fieldLengths[i]));
          }
          break;
        case MYSQL_TYPE_FLOAT:      /* FLOAT field */
        case MYSQL_TYPE_DOUBLE: {     /* DOUBLE or REAL field */
          double column_to_double;
          column_to_double = strtod(row[i], NULL);
          if (column_to_double == 0.000000){
            val = opt_float_zero;
          }else{
            val = rb_float_new(column_to_double);
          }
          break;
        }
        case MYSQL_TYPE_TIME: {     /* TIME field */
          int tokens;
          unsigned int hour=0, min=0, sec=0, msec=0;
          char msec_char[7] = {'0','0','0','0','0','0','\0'};

          tokens = sscanf(row[i], "%2u:%2u:%2u.%6s", &hour, &min, &sec, msec_char);
          if (tokens < 3) {
            val = Qnil;
            break;
          }
          msec = msec_char_to_uint(msec_char, sizeof(msec_char));
          val = rb_funcall(rb_cTime, args->db_timezone, 7, opt_time_year, opt_time_month, opt_time_month, UINT2NUM(hour), UINT2NUM(min), UINT2NUM(sec), UINT2NUM(msec));
          if (!NIL_P(args->app_timezone)) {
            if (args->app_timezone == intern_local) {
              val = rb_funcall(val, intern_localtime, 0);
            } else { /* utc */
              val = rb_funcall(val, intern_utc, 0);
            }
          }
          break;
        }
        case MYSQL_TYPE_TIMESTAMP:  /* TIMESTAMP field */
        case MYSQL_TYPE_DATETIME: { /* DATETIME field */
          int tokens;
          unsigned int year=0, month=0, day=0, hour=0, min=0, sec=0, msec=0;
          char msec_char[7] = {'0','0','0','0','0','0','\0'};
          uint64_t seconds;

          tokens = sscanf(row[i], "%4u-%2u-%2u %2u:%2u:%2u.%6s", &year, &month, &day, &hour, &min, &sec, msec_char);
          if (tokens < 6) { /* msec might be empty */
            val = Qnil;
            break;
          }
          seconds = (year*31557600ULL) + (month*2592000ULL) + (day*86400ULL) + (hour*3600ULL) + (min*60ULL) + sec;

          if (seconds == 0) {
            val = Qnil;
          } else {
            if (month < 1 || day < 1) {
              rb_raise(cMysql2Error, "Invalid date in field '%.*s': %s", fields[i].name_length, fields[i].name, row[i]);
              val = Qnil;
            } else {
              if (seconds < MYSQL2_MIN_TIME || seconds > MYSQL2_MAX_TIME) { /* use DateTime for larger date range, does not support microseconds */
                VALUE offset = INT2NUM(0);
                if (args->db_timezone == intern_local) {
                  offset = rb_funcall(cMysql2Client, intern_local_offset, 0);
                }
                val = rb_funcall(cDateTime, intern_civil, 7, UINT2NUM(year), UINT2NUM(month), UINT2NUM(day), UINT2NUM(hour), UINT2NUM(min), UINT2NUM(sec), offset);
                if (!NIL_P(args->app_timezone)) {
                  if (args->app_timezone == intern_local) {
                    offset = rb_funcall(cMysql2Client, intern_local_offset, 0);
                    val = rb_funcall(val, intern_new_offset, 1, offset);
                  } else { /* utc */
                    val = rb_funcall(val, intern_new_offset, 1, opt_utc_offset);
                  }
                }
              } else {
                msec = msec_char_to_uint(msec_char, sizeof(msec_char));
                val = rb_funcall(rb_cTime, args->db_timezone, 7, UINT2NUM(year), UINT2NUM(month), UINT2NUM(day), UINT2NUM(hour), UINT2NUM(min), UINT2NUM(sec), UINT2NUM(msec));
                if (!NIL_P(args->app_timezone)) {
                  if (args->app_timezone == intern_local) {
                    val = rb_funcall(val, intern_localtime, 0);
                  } else { /* utc */
                    val = rb_funcall(val, intern_utc, 0);
                  }
                }
              }
            }
          }
          break;
        }
        case MYSQL_TYPE_DATE:       /* DATE field */
        case MYSQL_TYPE_NEWDATE: {  /* Newer const used > 5.0 */
          int tokens;
          unsigned int year=0, month=0, day=0;
          tokens = sscanf(row[i], "%4u-%2u-%2u", &year, &month, &day);
          if (tokens < 3) {
            val = Qnil;
            break;
          }
          if (year+month+day == 0) {
            val = Qnil;
          } else {
            if (month < 1 || day < 1) {
              rb_raise(cMysql2Error, "Invalid date in field '%.*s': %s", fields[i].name_length, fields[i].name, row[i]);
              val = Qnil;
            } else {
              val = rb_funcall(cDate, intern_new, 3, UINT2NUM(year), UINT2NUM(month), UINT2NUM(day));
            }
          }
          break;
        }
        case MYSQL_TYPE_TINY_BLOB:
        case MYSQL_TYPE_MEDIUM_BLOB:
        case MYSQL_TYPE_LONG_BLOB:
        case MYSQL_TYPE_BLOB:
        case MYSQL_TYPE_VAR_STRING:
        case MYSQL_TYPE_VARCHAR:
        case MYSQL_TYPE_STRING:     /* CHAR or BINARY field */
        case MYSQL_TYPE_SET:        /* SET field */
        case MYSQL_TYPE_ENUM:       /* ENUM field */
        case MYSQL_TYPE_GEOMETRY:   /* Spatial fielda */
        default:
          val = rb_str_new(row[i], fieldLengths[i]);
#ifdef HAVE_RUBY_ENCODING_H
          val = mysql2_set_field_string_encoding(val, fields[i], default_internal_enc, conn_enc);
#endif
          break;
        }
      }
      if (args->asArray) {
        rb_ary_push(rowVal, val);
      } else {
        rb_hash_aset(rowVal, field, val);
      }
    } else {
      if (args->asArray) {
        rb_ary_push(rowVal, Qnil);
      } else {
        rb_hash_aset(rowVal, field, Qnil);
      }
    }
  }
  return rowVal;
}

static VALUE rb_mysql_result_fetch_fields(VALUE self) {
  unsigned int i = 0;
  short int symbolizeKeys = 0;
  VALUE defaults;

  GET_RESULT(self);

  defaults = rb_iv_get(self, "@query_options");
  Check_Type(defaults, T_HASH);
  if (rb_hash_aref(defaults, sym_symbolize_keys) == Qtrue) {
    symbolizeKeys = 1;
  }

  if (wrapper->fields == Qnil) {
    wrapper->numberOfFields = mysql_num_fields(wrapper->result);
    wrapper->fields = rb_ary_new2(wrapper->numberOfFields);
  }

  if ((my_ulonglong)RARRAY_LEN(wrapper->fields) != wrapper->numberOfFields) {
    for (i=0; i<wrapper->numberOfFields; i++) {
      rb_mysql_result_fetch_field(self, i, symbolizeKeys);
    }
  }

  return wrapper->fields;
}

static VALUE rb_mysql_result_each_(VALUE self,
                                   VALUE(*fetch_row_func)(VALUE, MYSQL_FIELD *fields, const result_each_args *args),
                                   const result_each_args *args)
{
  unsigned long i;
  const char *errstr;
  MYSQL_FIELD *fields = NULL;

  GET_RESULT(self);

  if (wrapper->is_streaming) {
    /* When streaming, we will only yield rows, not return them. */
    if (wrapper->rows == Qnil) {
      wrapper->rows = rb_ary_new();
    }

    if (!wrapper->streamingComplete) {
      VALUE row;

      fields = mysql_fetch_fields(wrapper->result);

      do {
        row = fetch_row_func(self, fields, args);
        if (row != Qnil) {
          wrapper->numberOfRows++;
          if (args->block_given != Qnil) {
            rb_yield(row);
          }
        }
      } while(row != Qnil);

      rb_mysql_result_free_result(wrapper);
      wrapper->streamingComplete = 1;

      // Check for errors, the connection might have gone out from under us
      // mysql_error returns an empty string if there is no error
      errstr = mysql_error(wrapper->client_wrapper->client);
      if (errstr[0]) {
        rb_raise(cMysql2Error, "%s", errstr);
      }
    } else {
      rb_raise(cMysql2Error, "You have already fetched all the rows for this query and streaming is true. (to reiterate you must requery).");
    }
  } else {
    if (args->cacheRows && wrapper->lastRowProcessed == wrapper->numberOfRows) {
      /* we've already read the entire dataset from the C result into our */
      /* internal array. Lets hand that over to the user since it's ready to go */
      for (i = 0; i < wrapper->numberOfRows; i++) {
        rb_yield(rb_ary_entry(wrapper->rows, i));
      }
    } else {
      unsigned long rowsProcessed = 0;
      rowsProcessed = RARRAY_LEN(wrapper->rows);
      fields = mysql_fetch_fields(wrapper->result);

      for (i = 0; i < wrapper->numberOfRows; i++) {
        VALUE row;
        if (args->cacheRows && i < rowsProcessed) {
          row = rb_ary_entry(wrapper->rows, i);
        } else {
          row = fetch_row_func(self, fields, args);
          if (args->cacheRows) {
            rb_ary_store(wrapper->rows, i, row);
          }
          wrapper->lastRowProcessed++;
        }

        if (row == Qnil) {
          /* we don't need the mysql C dataset around anymore, peace it */
          if (args->cacheRows) {
            rb_mysql_result_free_result(wrapper);
          }
          return Qnil;
        }

        if (args->block_given != Qnil) {
          rb_yield(row);
        }
      }
      if (wrapper->lastRowProcessed == wrapper->numberOfRows && args->cacheRows) {
        /* we don't need the mysql C dataset around anymore, peace it */
        rb_mysql_result_free_result(wrapper);
      }
    }
  }

  // FIXME return Enumerator instead?
  // return rb_ary_each(wrapper->rows);
  return wrapper->rows;
}

static VALUE rb_mysql_result_each(int argc, VALUE * argv, VALUE self) {
  result_each_args args;
  VALUE defaults, opts, block, (*fetch_row_func)(VALUE, MYSQL_FIELD *fields, const result_each_args *args);
  ID db_timezone, app_timezone, dbTz, appTz;
  int symbolizeKeys, asArray, castBool, cacheRows, cast;

  GET_RESULT(self);

  if (wrapper->stmt_wrapper && wrapper->stmt_wrapper->closed) {
    rb_raise(cMysql2Error, "Statement handle already closed");
  }

  defaults = rb_iv_get(self, "@query_options");
  Check_Type(defaults, T_HASH);
  if (rb_scan_args(argc, argv, "01&", &opts, &block) == 1) {
    opts = rb_funcall(defaults, intern_merge, 1, opts);
  } else {
    opts = defaults;
  }

  symbolizeKeys = RTEST(rb_hash_aref(opts, sym_symbolize_keys));
  asArray       = rb_hash_aref(opts, sym_as) == sym_array;
  castBool      = RTEST(rb_hash_aref(opts, sym_cast_booleans));
  cacheRows     = RTEST(rb_hash_aref(opts, sym_cache_rows));
  cast          = RTEST(rb_hash_aref(opts, sym_cast));

  if (wrapper->is_streaming && cacheRows) {
    rb_warn(":cache_rows is ignored if :stream is true");
  }

  if (wrapper->stmt_wrapper && !cacheRows && !wrapper->is_streaming) {
    rb_warn(":cache_rows is forced for prepared statements (if not streaming)");
    cacheRows = 1;
  }

  if (wrapper->stmt_wrapper && !cast) {
    rb_warn(":cast is forced for prepared statements");
  }

  dbTz = rb_hash_aref(opts, sym_database_timezone);
  if (dbTz == sym_local) {
    db_timezone = intern_local;
  } else if (dbTz == sym_utc) {
    db_timezone = intern_utc;
  } else {
    if (!NIL_P(dbTz)) {
      rb_warn(":database_timezone option must be :utc or :local - defaulting to :local");
    }
    db_timezone = intern_local;
  }

  appTz = rb_hash_aref(opts, sym_application_timezone);
  if (appTz == sym_local) {
    app_timezone = intern_local;
  } else if (appTz == sym_utc) {
    app_timezone = intern_utc;
  } else {
    app_timezone = Qnil;
  }

  if (wrapper->rows == Qnil && !wrapper->is_streaming) {
    wrapper->numberOfRows = wrapper->stmt_wrapper ? mysql_stmt_num_rows(wrapper->stmt_wrapper->stmt) : mysql_num_rows(wrapper->result);
    wrapper->rows = rb_ary_new2(wrapper->numberOfRows);
  } else if (wrapper->rows && !cacheRows) {
    if (wrapper->resultFreed) {
      rb_raise(cMysql2Error, "Result set has already been freed");
    }
    mysql_data_seek(wrapper->result, 0);
    wrapper->lastRowProcessed = 0;
    wrapper->rows = rb_ary_new2(wrapper->numberOfRows);
  }

  // Backward compat
  args.symbolizeKeys = symbolizeKeys;
  args.asArray = asArray;
  args.castBool = castBool;
  args.cacheRows = cacheRows;
  args.cast = cast;
  args.db_timezone = db_timezone;
  args.app_timezone = app_timezone;
  args.block_given = block;

  if (wrapper->stmt_wrapper) {
    fetch_row_func = rb_mysql_result_fetch_row_stmt;
  } else {
    fetch_row_func = rb_mysql_result_fetch_row;
  }

  return rb_mysql_result_each_(self, fetch_row_func, &args);
}

static VALUE rb_mysql_result_count(VALUE self) {
  GET_RESULT(self);

  if (wrapper->is_streaming) {
    /* This is an unsigned long per result.h */
    return ULONG2NUM(wrapper->numberOfRows);
  }

  if (wrapper->resultFreed) {
    /* Ruby arrays have platform signed long length */
    return LONG2NUM(RARRAY_LEN(wrapper->rows));
  } else {
    /* MySQL returns an unsigned 64-bit long here */
    if (wrapper->stmt_wrapper) {
      return ULL2NUM(mysql_stmt_num_rows(wrapper->stmt_wrapper->stmt));
    } else {
      return ULL2NUM(mysql_num_rows(wrapper->result));
    }
  }
}

/* Mysql2::Result */
VALUE rb_mysql_result_to_obj(VALUE client, VALUE encoding, VALUE options, MYSQL_RES *r, VALUE statement) {
  VALUE obj;
  mysql2_result_wrapper * wrapper;

  obj = Data_Make_Struct(cMysql2Result, mysql2_result_wrapper, rb_mysql_result_mark, rb_mysql_result_free, wrapper);
  wrapper->numberOfFields = 0;
  wrapper->numberOfRows = 0;
  wrapper->lastRowProcessed = 0;
  wrapper->resultFreed = 0;
  wrapper->result = r;
  wrapper->fields = Qnil;
  wrapper->rows = Qnil;
  wrapper->encoding = encoding;
  wrapper->streamingComplete = 0;
  wrapper->client = client;
  wrapper->client_wrapper = DATA_PTR(client);
  wrapper->client_wrapper->refcount++;
  wrapper->result_buffers = NULL;
  wrapper->is_null = NULL;
  wrapper->error = NULL;
  wrapper->length = NULL;

  /* Keep a handle to the Statement to ensure it doesn't get garbage collected first */
  wrapper->statement = statement;
  if (statement != Qnil) {
    wrapper->stmt_wrapper = DATA_PTR(statement);
    wrapper->stmt_wrapper->refcount++;
  } else {
    wrapper->stmt_wrapper = NULL;
  }

  rb_obj_call_init(obj, 0, NULL);
  rb_iv_set(obj, "@query_options", options);

  /* Options that cannot be changed in results.each(...) { |row| }
   * should be processed here. */
  wrapper->is_streaming = (rb_hash_aref(options, sym_stream) == Qtrue ? 1 : 0);

  return obj;
}

void init_mysql2_result() {
  cBigDecimal = rb_const_get(rb_cObject, rb_intern("BigDecimal"));
  cDate = rb_const_get(rb_cObject, rb_intern("Date"));
  cDateTime = rb_const_get(rb_cObject, rb_intern("DateTime"));

  cMysql2Result = rb_define_class_under(mMysql2, "Result", rb_cObject);
  rb_define_method(cMysql2Result, "each", rb_mysql_result_each, -1);
  rb_define_method(cMysql2Result, "fields", rb_mysql_result_fetch_fields, 0);
  rb_define_method(cMysql2Result, "free", rb_mysql_result_free_, 0);
  rb_define_method(cMysql2Result, "count", rb_mysql_result_count, 0);
  rb_define_alias(cMysql2Result, "size", "count");

  intern_new          = rb_intern("new");
  intern_utc          = rb_intern("utc");
  intern_local        = rb_intern("local");
  intern_merge        = rb_intern("merge");
  intern_localtime    = rb_intern("localtime");
  intern_local_offset = rb_intern("local_offset");
  intern_civil        = rb_intern("civil");
  intern_new_offset   = rb_intern("new_offset");

  sym_symbolize_keys  = ID2SYM(rb_intern("symbolize_keys"));
  sym_as              = ID2SYM(rb_intern("as"));
  sym_array           = ID2SYM(rb_intern("array"));
  sym_local           = ID2SYM(rb_intern("local"));
  sym_utc             = ID2SYM(rb_intern("utc"));
  sym_cast_booleans   = ID2SYM(rb_intern("cast_booleans"));
  sym_database_timezone     = ID2SYM(rb_intern("database_timezone"));
  sym_application_timezone  = ID2SYM(rb_intern("application_timezone"));
  sym_cache_rows     = ID2SYM(rb_intern("cache_rows"));
  sym_cast           = ID2SYM(rb_intern("cast"));
  sym_stream         = ID2SYM(rb_intern("stream"));
  sym_name           = ID2SYM(rb_intern("name"));

  opt_decimal_zero = rb_str_new2("0.0");
  rb_global_variable(&opt_decimal_zero); /*never GC */
  opt_float_zero = rb_float_new((double)0);
  rb_global_variable(&opt_float_zero);
  opt_time_year = INT2NUM(2000);
  opt_time_month = INT2NUM(1);
  opt_utc_offset = INT2NUM(0);

#ifdef HAVE_RUBY_ENCODING_H
  binaryEncoding = rb_enc_find("binary");
#endif
}
