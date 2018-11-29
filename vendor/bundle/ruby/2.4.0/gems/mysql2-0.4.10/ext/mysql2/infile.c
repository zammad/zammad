#include <mysql2_ext.h>

#include <errno.h>
#ifndef _MSC_VER
#include <unistd.h>
#endif
#include <fcntl.h>

#define ERROR_LEN 1024
typedef struct
{
  int fd;
  char *filename;
  char error[ERROR_LEN];
  mysql_client_wrapper *wrapper;
} mysql2_local_infile_data;

/* MySQL calls this function when a user begins a LOAD DATA LOCAL INFILE query.
 *
 * Allocate a data struct and pass it back through the data pointer.
 *
 * Returns:
 * 0 on success
 * 1 on error
 */
static int
mysql2_local_infile_init(void **ptr, const char *filename, void *userdata)
{
  mysql2_local_infile_data *data = malloc(sizeof(mysql2_local_infile_data));
  if (!data) return 1;

  *ptr = data;
  data->error[0] = 0;
  data->wrapper = userdata;

  data->filename = strdup(filename);
  if (!data->filename) {
    snprintf(data->error, ERROR_LEN, "%s: %s", strerror(errno), filename);
    return 1;
  }

  data->fd = open(filename, O_RDONLY);
  if (data->fd < 0) {
    snprintf(data->error, ERROR_LEN, "%s: %s", strerror(errno), filename);
    return 1;
  }

  return 0;
}

/* MySQL calls this function to read data from the local file.
 *
 * Returns:
 * > 0   number of bytes read
 * == 0  end of file
 * < 0   error
 */
static int
mysql2_local_infile_read(void *ptr, char *buf, unsigned int buf_len)
{
  int count;
  mysql2_local_infile_data *data = (mysql2_local_infile_data *)ptr;

  count = (int)read(data->fd, buf, buf_len);
  if (count < 0) {
    snprintf(data->error, ERROR_LEN, "%s: %s", strerror(errno), data->filename);
  }

  return count;
}

/* MySQL calls this function when we're done with the LOCAL INFILE query.
 *
 * ptr will be null if the init function failed.
 */
static void
mysql2_local_infile_end(void *ptr)
{
  mysql2_local_infile_data *data = (mysql2_local_infile_data *)ptr;
  if (data) {
    if (data->fd >= 0)
      close(data->fd);
    if (data->filename)
      free(data->filename);
    free(data);
  }
}

/* MySQL calls this function if any of the functions above returned an error.
 *
 * This function is called even if init failed, with whatever ptr value
 * init has set, regardless of the return value of the init function.
 *
 * Returns:
 * Error message number (see http://dev.mysql.com/doc/refman/5.0/en/error-messages-client.html)
 */
static int
mysql2_local_infile_error(void *ptr, char *error_msg, unsigned int error_msg_len)
{
  mysql2_local_infile_data *data = (mysql2_local_infile_data *) ptr;

  if (data) {
    snprintf(error_msg, error_msg_len, "%s", data->error);
    return CR_UNKNOWN_ERROR;
  }

  snprintf(error_msg, error_msg_len, "Out of memory");
  return CR_OUT_OF_MEMORY;
}

/* Tell MySQL Client to use our own local_infile functions.
 * This is both due to bugginess in the default handlers,
 * and to improve the Rubyness of the handlers here.
 */
void mysql2_set_local_infile(MYSQL *mysql, void *userdata)
{
  mysql_set_local_infile_handler(mysql,
                                 mysql2_local_infile_init,
                                 mysql2_local_infile_read,
                                 mysql2_local_infile_end,
                                 mysql2_local_infile_error, userdata);
}
