#ifndef MYSQL2_STATEMENT_H
#define MYSQL2_STATEMENT_H

extern VALUE cMysql2Statement;

typedef struct {
  VALUE client;
  MYSQL_STMT *stmt;
  int refcount;
  int closed;
} mysql_stmt_wrapper;

void init_mysql2_statement(void);
void decr_mysql2_stmt(mysql_stmt_wrapper *stmt_wrapper);

VALUE rb_mysql_stmt_new(VALUE rb_client, VALUE sql);
void rb_raise_mysql2_stmt_error(mysql_stmt_wrapper *stmt_wrapper) RB_MYSQL_NORETURN;

#endif
