/*
 * backwards compatibility for pre-1.9.3 C API
 *
 * Ruby 1.9.3 provides this API which allows the use of ppoll() on Linux
 * to minimize select() and malloc() overhead on high-numbered FDs.
 */
#ifdef HAVE_RB_WAIT_FOR_SINGLE_FD
#  include <ruby/io.h>
#else
#  define RB_WAITFD_IN  0x001
#  define RB_WAITFD_PRI 0x002
#  define RB_WAITFD_OUT 0x004

static int my_wait_for_single_fd(int fd, int events, struct timeval *tvp)
{
  fd_set fdset;
  fd_set *rfds = NULL;
  fd_set *wfds = NULL;
  fd_set *efds = NULL;

  FD_ZERO(&fdset);
  FD_SET(fd, &fdset);

  if (events & RB_WAITFD_IN)
    rfds = &fdset;
  if (events & RB_WAITFD_OUT)
    wfds = &fdset;
  if (events & RB_WAITFD_PRI)
    efds = &fdset;

  return rb_thread_select(fd + 1, rfds, wfds, efds, tvp);
}

#define rb_wait_for_single_fd(fd,events,tvp) \
        my_wait_for_single_fd((fd),(events),(tvp))
#endif
