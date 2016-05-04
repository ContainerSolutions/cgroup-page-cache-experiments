# clear all caches
sync; echo 3 > /proc/sys/vm/drop_caches; free -m; 

rm -f output-a.1.txt output-a.2.txt
sleep 1

# start test progs
./mmap_pagefault_test file1 output-a.1.txt & process_a1_pid=$$
./mmap_pagefault_test file2 output-a.2.txt & process_a2_pid=$$

echo "sleeping for 10 seconds"
sleep 10
kill $process_a1_pid
kill $process_a2_pid
echo "done"
