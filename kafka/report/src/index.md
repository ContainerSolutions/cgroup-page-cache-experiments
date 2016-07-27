Report on kafka performance analysis on mesos
=============================================

# Method

## Meta
The machine setup is described in Nix, to allow 100% repreducability
for a) the virtual infrastructure and b) the software installed on the machines.

* declaratively described 
  * test infrastructure (gce machines)
  * software to be installed
  * removal of test data
* all experiments have been performed multiple times to detect anomalies.

## Software versions

We have tested with:
* kafka <TODO version>
* mesos <TODO version>
* mesos kafka framework <TODO version>

### Types of topics created

We only use topics with partitions=1 and replication=<nr kafka nodes>,
to simulate a worst case scenario; all messages must be replicated to all hosts,
and all messages must be written to the same log file.

### Experiments performed

1. Run 'baseline' for determining base max performance of the cluster.
   Expected: nothing; determine max capacity of the cluster.
2. Run 'direct' on 50% of max capacity. => baseline
   Expected: slowdown when stress is applied
3. Run 'direct+cgroup' on 50% of max capacity, add stress in limited cgroup
   Expected: smaller slowdown
4. Run 'mesos-no-cgroup' on 50% of max capacity
   Expected: same perf. as baseline (exp 1)
5. Run 'mesos-no-cgroup' on 50% of max capacity, add stress jobs as marathon jobs
   Expected: Slowdown comparable with 2.
6. Run 'mesos-with-cgroup' on 50% of max capacity, add stress jobs as marathon jobs
   Expected: small slowdown, comparable with 3.

### (Why) Determining the base performance
In *Experiment 1* and, we determine the maximum possible load of the cluster.
We picked the semi-arbitrary number of 50% load, to simulate underutilization of the 
available hardware. If the hardware were fully utilized, running mesos would not help
with improving resource utilization.

Without baseline numbers, we cannot compare how much of a slowdown actually happens 
if we stress-test the system.

### (Why) Automated testing
The tests are run completely automatic, to prevent human error and impact of 
small differences in starting time of stress.
This results in the possibility to run each experiment multiple times, and
check for variance in the results.

## Virtual machines
The slave machines have been created with instance type `n1-standard-4`, all
other machines were of instance type `n1-standard-1`. 
All instances were started in region `europe-west1-b`.

The n1-standard-1 machines have 1 virtual CPU and 3.75 GB of memory, the
n1-standard-4 machines have 4 virtual CPU's and 15 GB of memory

#Results

## Experiment 1: Determining baseline
We created a cluster consisting of one master node, that runs zookeeper and later 
on also acts as a mesos master, three slave nodes, that run kafka brokers
and two client nodes, that will access the kafka cluster concurrently.

The [report for the baseline](./static/baseline_report/index.html), 
and especially the the ['Major page faults' graph](./static/baseline_report/host-pages-maj-faults.png) shows that
the system is getting overloaded after 850 seconds, which corresponds to having two
clients producing 700 messages per second, where each message is 10KB.

Therefore, the baseline for an underutilized setup is 350 messages per second per client.

# Experiment 2: Direct benchmark
The first benchmark we run is with kafka directly installed on the slaves, without mesos.
We generate additional pressure on the system using the `stress` tool. 
We instructed it to allocate 98% of the available memory, 
spread out over four threads that continously allocate, dirty, 
and deallocate memory to stress the memory subsystem.
At the same time, each thread also attempts to write 10GB of data to disk, to stress the IO subsystem.

The raw results can be found in [the second report](./static/direct_report/index.html).

# Experiment 3: Direct + 'limited' stress
running at the moment.
