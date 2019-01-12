#include <libgen.h>
#include <sys/param.h>

const char *
observer_basename(const char *path)
{
  return basename((char *)path);
}

static char dirname_buffer[MAXPATHLEN];

const char *
observer_dirname(const char *path)
{
  return dirname_r(path, dirname_buffer);
}
