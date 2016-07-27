# Settings for the benchmark. These were updated to obtain a baseline.
rec {
  producer_test_record_size_in_bytes = 100 * 1024;
  producer_test_throughput_msgs_per_s = 350;

#  limited_kafka_mem_limit_in_mb = 8704; # 8.5 GB of mem.
  limited_stress_slice_size_limit_in_mb = 7680;
}
