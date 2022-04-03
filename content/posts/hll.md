---
title: "Compute distinct values in massive datasets with HyperLogLog"
date: 2022-04-03T19:19:20+02:00
draft: false
---

HyperLogLog is an approximation algorithm for cardinality (number of unique elements in a set) of a multiset (set that can contain the same element more than once).
If you can tolerate to sacrifice some accuracy you can use it to greatly reduce the memory usage of computing the exact cardinality. According to [Wikipedia](https://en.wikipedia.org/wiki/HyperLogLog) the typical error of accuracy is **2%** using **1.5KB** of memory for cardinality > **1 billion**. This can come in handy if you are working on a very large dataset. Imagine that you want to approximate the number of distinct IP-addresses that have visited your site and the traffic is massive. I wrote some code to simulate this and present the accuracy and memory trade off. To my help I have redis which comes with an implementation of HyperLogLog.

## Fake it until you make it

faker is a nice python library that can help you generate fake data. With the internet provider we can generate loads of public ip addresses.

```python
from faker import Faker
from faker.providers import internet

def _generate_fake_ips(n):
    """
    Generate a list n of public ips, uniqueness is not guaranteed 
    """
    fake = Faker()
    fake.add_provider(internet)

    unique_ips = []
    for _ in range(n):
        unique_ips.append(fake.ipv4_public())
    return unique_ips
```

## Store it in redis

With redis running as a docker container `docker run --rm -d -p 6379:6379 redis` we can store it in a HyperLogLog data structure with **PFADD** and to a regular set with **SADD**.

```python
import redis


r = redis.Redis(host='localhost', port=6379, db=0)


HYPERLOGLOG_KEY="krausen.github.io:unique_visits_hyperloglog"
SET_KEY="krausen.github.io:unique_visits_set"


for ip in fake_ips:
   r.pfadd(HYPERLOGLOG_KEY, ip)  # Add ip address to hyperloglog
for ip in fake_ips:
   r.sadd(SET_KEY, ip)  # Add ip to a regular set
```

Similarly we can print cardinality and memory usage with

```python
hyperloglog_count = r.pfcount(HYPERLOGLOG_KEY)  # Get cardinality from hyperloglog
set_count = r.scard(SET_KEY) # Get cardinality from set
hyperloglog_mem_usage = r.memory_usage(HYPERLOGLOG_KEY) / 1024 # Get memory usage from hyperloglog
set_mem_usage = r.memory_usage(SET_KEY) / 1024  # Get memory usage from set
```

## Results

With **10 million** values and a cardinality of **~9.9 million**

|  | Accuracy | Memory Usage|
| --- | ----------- |--|
| HyperLogLog | 99.89% | 14KB |
| Set | 100% | 617725KB|

In this particular case, storing the distinct IP-addresses in a set requires **x44123** memory as the HyperLogLog which gives a good approximation, well within the **2%** error.  

## Want more?

For detailed code, check out the repository [here](https://github.com/krausen/hyperloglog)