#include <assert.h>
#include <fcntl.h>
#include <linux/limits.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

void usage(char *progname) {
  printf("Usage: %s <input_file>\n", progname);
}

struct proc_stat {
  int pid;
  char comm[PATH_MAX];
  char state;
  int ppid;
  int pgrp;
  int session;
  int tty_nr;
  int tpgid;
  unsigned int flags;
  unsigned long minflt;
  unsigned long cminflt;
  unsigned long majflt;
  unsigned long cmajflt;
  unsigned long utime;
  unsigned long stime;
  long cutime;
  long cstime;
//  long priority;
//  long nice;
//  long num_threads;
//  long itrealvalue;
//  long starttime;
//  long vsize;
//  long rss;
//  long rsslim;
//  long startcode;
//  long endcode;
//  long startstack;
//  even more! see man 5 proc.
};

void parse_proc_stat(struct proc_stat *to) {
  FILE *f = fopen("/proc/self/stat","r");
  assert(f != NULL);

  fscanf(f, "%d ", &to->pid);
  fscanf(f, "%s ", (char *) &to->comm);
  fscanf(f, "%c ", &to->state);
  fscanf(f, "%d ", &to->ppid);
  fscanf(f, "%d ", &to->pgrp);
  fscanf(f, "%d ", &to->session);
  fscanf(f, "%d ", &to->tty_nr);
  fscanf(f, "%d ", &to->tpgid);
  fscanf(f, "%u ", &to->flags);
  fscanf(f, "%lu ", &to->minflt);
  fscanf(f, "%lu ", &to->cminflt);
  fscanf(f, "%lu ", &to->majflt);
  fscanf(f, "%lu ", &to->cmajflt);
  fscanf(f, "%lu ", &to->utime);
  fscanf(f, "%lu ", &to->stime);
  fscanf(f, "%ld ", &to->cutime);
  fscanf(f, "%ld ", &to->cstime);
}

int main(int argc, char *argv[]) {
  if (argc != 2) {
    fprintf(stderr, "Wrong number of arguments!\n");
    usage(argv[0]);
    exit(1);
  }

  // Validate the params
  char *file_name = argv[1];

  struct stat filestat;
  int result = stat(file_name, &filestat);

  if (result == -1) {
    perror("Input file could not be opened");
    exit(1);
  }

  assert(S_ISREG(filestat.st_mode)); // assert that it's a regular file
  assert(filestat.st_size % sizeof(uint64_t) == 0); // assert that the file is a multiple of a unsigned 64 bit number.

  struct proc_stat before_stats;
  parse_proc_stat(&before_stats);
  unsigned long prev_majflt = before_stats.majflt;


  unsigned int iteration = 0;
  while (1) {
    iteration += 1;

    // Get information about current process, before we open the file / memory map.
    int fd = open(file_name, O_RDONLY);
    assert(fd != -1);

    uint64_t *ptr = mmap(NULL, filestat.st_size, PROT_READ, MAP_SHARED, fd, 0);
    if (ptr == ((void*) -1)) {
      perror("Could not mmap file!");
    }

    const uint64_t nr_ints = filestat.st_size / sizeof(uint64_t); // safe, since asserted before.
    volatile uint64_t sum = 0;

    // read the whole file indirectly.
    for (int idx = 0; idx < nr_ints; idx++) {
      sum += ptr[idx];
    }

    struct proc_stat stats;
    parse_proc_stat(&stats);
    printf("%i\t%lu\n", iteration, stats.majflt - prev_majflt);
    prev_majflt = stats.majflt;

    assert(munmap(ptr, filestat.st_size) != -1);
    assert(close(fd) != -1);

    sleep(1);
  }

  return 0;
}
