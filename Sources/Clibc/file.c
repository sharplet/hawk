#include <sys/stat.h>

int
observer_is_dir(const char *path)
{
  struct stat path_stat;

  if (stat(path, &path_stat) != 0) {
    return 0;
  }

  return S_ISDIR(path_stat.st_mode);
}
