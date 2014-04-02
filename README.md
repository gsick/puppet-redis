[![Build Status](https://travis-ci.org/gsick/puppet-redis.svg?branch=0.0.4)](https://travis-ci.org/gsick/puppet-redis)
[![Coverage Status](https://coveralls.io/repos/gsick/puppet-redis/badge.png?branch=0.0.4)](https://coveralls.io/r/gsick/puppet-redis?branch=0.0.4)
(95% with rspec-puppet)

puppet-redis
============

Redis/Redis sentinel multiple instances installation and configuration module.<br />
[Redis](http://redis.io)<br />

## Table of Contents

* [Status](#status)
* [Dependencies](#dependencies)
* [Usage](#usage)
    * [Default configuration](#default-configuration)
        * [Redis](#redis)
        * [Redis sentinel](#redis-sentinel)
    * [Advanced configuration](#advanced-configuration)
        * [Parameters](#parameters)
        * [Available redis properties](#available-redis-properties)
        * [No template](#no-template)
        * [Add/Uncomment properties](#adduncomment-properties)
        * [Comment properties](#comment-properties)
        * [Multiple Redis instances](#multiple-redis-instances)
    * [Service](#service)
* [Examples](#examples)
    * [Redis LRU cache](#redis-lru-cache)
    * [Redis sentinel](#redis-sentinel-1)
    * [Redis + Redis sentinel + LRU cache](#redis--redis-sentinel--lru-cache)
* [Installation](#installation)
    * [puppet](#puppet)
    * [librarian-puppet](#librarian-puppet)
* [Tests](#tests)
    * [Unit tests](#unit-tests)
    * [Smoke tests](#smoke-tests)
* [Authors](#authors)
* [Contributing](#contributing)
* [Licence](#licence)

## Status

0.0.4 released.

## Dependencies

This module requires Puppet >= 3.4.0 due to [each](http://docs.puppetlabs.com/references/latest/function.html#each) function, need `parser = future` in `puppet.conf`.<br />

## Usage

In your puppet file

```puppet
node default {
  include redis
}
```

### Default configuration

#### Redis

In your hieradata file

```yaml
---
redis::version: 2.8.7
```

It will create `/etc/redis/6379.conf` [see file](http://pastebin.com/xZaKysam).<br />
The default template configuration comes from redis.conf provided by the original package.<br />
Only these default values are uncommented/added/changed:

```text
daemonize yes
pidfile /var/run/redis_6379.pid
port 6379
logfile /var/log/redis_6379.log
dir /var/lib/redis/6379
```

Read [Available redis properties](#available-redis-properties) for some properties hiera syntax

#### Redis sentinel

In your hieradata file

```yaml
---
redis::version: 2.8.7
redis::servers:
    redis_26389:
        sentinel: true
        conf:
          sentinel monitor: mymaster 127.0.0.1 6379 2
          sentinel down-after-milliseconds: mymaster 30000
          sentinel parallel-syncs: mymaster 1
          sentinel failover-timeout: mymaster 180000
```

It will create `/etc/redis/26389.conf` [see file](http://pastebin.com/4Cje5NsJ).<br />
The default template configuration comes from sentinel.conf provided by the original package.<br />
Only these default values are uncommented/added/changed:

```text
daemonize yes
pidfile /var/run/redis_26389.pid
port 26389
logfile /var/log/redis_26389.log
dir /var/lib/redis/26389
sentinel monitor mymaster 127.0.0.1 6379 2
```

Read [Available redis properties](#available-redis-properties) for sentinel properties hiera syntax

### Advanced configuration

#### Parameters

* `redis::version`: version of Redis (required)
* `redis::servers`: hash of servers instances, default `{ redis_6379 => {} }`
    * `sentinel`: boolean, redis sentinel, default `false`
    * `default_template`: boolean, use default redis template, default `true`
    * `conf`: hash of redis properties, default `{ daemonize => 'yes' }`
* `redis::conf_dir`: configuration directory, default `/etc/redis`
* `redis::data_dir`: data directory, default `/var/lib/redis`
* `redis::sysctl`: boolean, apply sysctl overcommit conf, default `true`
* `redis::tmp`: tmp directory used by install, default `/tmp`

#### Available redis properties

All properties can be added.<br />
But due to the regex used, there are some restrictions:<br />

Don't forget double-quotes `""` for `"yes"` and `"no"` otherwise puppet will understand true or false.

Some properties only work with `default_template = true`:
* `rename-command`
* `appendfsync`

The key of some others must have two parts:
* `client-output-buffer-limit`
    * `client-output-buffer-limit normal: 64mb 0 0`
    * `client-output-buffer-limit slave: 128mb 64mb 60`
    * `client-output-buffer-limit pubsub: 64mb 8mb 60`

* `save`
    * `save 900: 1`
    * `save 300: 10`
    * `save 60: 10000`

* `sentinel`
    * `sentinel monitor: mymaster 127.0.0.1 6379 2`
    * `sentinel auth-pass: mymaster MySUPER--secret-0123passw0rd`
    * `sentinel down-after-milliseconds: mymaster 30000`
    * `sentinel parallel-syncs: mymaster 2`
    * `sentinel failover-timeout: mymaster 190000`
    * `sentinel notification-script: mymaster /var/redis/notify.sh`
    * `sentinel client-reconfig-script: mymaster /var/redis/reconfig.sh`

#### No template

```yaml
---
redis::version: 2.8.7
redis::servers:
    my_redis_1:
      default_template: false
      conf:
        port: 9999
        property_key: property_value
        ...
```

It will create `/etc/redis/9999.conf` with these default values:

```text
port 9999
logfile /var/log/redis_9999.log
dir /var/lib/redis/9999
pidfile /var/run/redis_9999.pid
daemonize yes
property_key property_value
...
```

#### Add/Uncomment properties

```yaml
---
redis::version: 2.8.7
redis::servers:
    redis_7979:
        conf:
          port: 7979
          bind: 127.0.0.1
          loglevel: debug
          appendonly: "no"
          ...
```

#### Comment properties

```yaml
---
redis::version: 2.8.7
redis::servers:
    my_redis_1:
      default_template: false
      conf:
        port: 9999
        "#slave-read-only": "yes"
        "#min-slaves-to-write": 3
        "#property_key": property_value
        ...
```

will give:

```text
...
# slave-read-only yes
# min-slaves-to-write 3
# property_key property_value
...
```

#### Multiple Redis instances

```yaml
---
redis::version: 2.8.7
redis::servers:
    my_redis_1:
      conf:
        port: 9999
        property_key: property_value
        ...
    my_redis_3:
      conf:
        port: 8888
        property_key: property_value
        ...
    my_redis_2:
      sentinel: true
      conf:
        port: 29999
        property_key: property_value
        ...
```

### Service

```bash
$ service redis_${port} start/stop/restart
```

## Examples

### Redis LRU cache

```yaml
---
redis::version: 2.8.7
redis::servers:
    redis_LRU_cache:
        conf:
          bind: 127.0.0.1
          "#save 900": 1
          "#save 300": 10
          "#save 60": 10000
          maxmemory: 100mb
          maxmemory-policy: volatile-lru
          maxmemory-samples: 5
```

### Redis sentinel

```yaml
---
redis::version: 2.8.7
redis::servers:
    redis_sentinel:
        sentinel: true
        conf:
          sentinel monitor: thor 192.168.0.12 6379 2
          sentinel down-after-milliseconds: thor 30000
          sentinel parallel-syncs: thor 1
          sentinel failover-timeout: thor 180000
```

### Redis + Redis sentinel + LRU cache

```yaml
---
redis::version: 2.8.7
redis::servers:
    redis_master:
        conf:
          port: 6379
    redis_sentinel:
        sentinel: true
        conf:
          sentinel monitor: thor 127.0.0.1 6379 2
          sentinel down-after-milliseconds: thor 30000
          sentinel parallel-syncs: thor 1
          sentinel failover-timeout: thor 180000
    redis_LRU_cache:
        conf:
          port: 7979
          bind: 127.0.0.1
          "#save 900": 1
          "#save 300": 10
          "#save 60": 10000
          maxmemory: 100mb
          maxmemory-policy: volatile-lru
          maxmemory-samples: 5
```

## Installation

### puppet

```bash
$ puppet module install gsick-redis
```

### librarian-puppet

Add in your Puppetfile

```text
mod 'gsick/redis'
```

and run

```bash
$ librarian-puppet update
```

## Tests

### Unit tests

`fix_future_test.sh` will be remove after the next release of puppet-lint and rspec-puppet.

```bash
$ ./fix_future_test.sh
$ bundle install
$ rake test
```

### Smoke tests

```bash
$ puppet apply tests/init.pp --noop
```

## Authors

Gamaliel Sick

## Contributing

  * Fork it
  * Create your feature branch `git checkout -b my-new-feature`
  * Commit your changes `git commit -am 'Add some feature'`
  * Push to the branch `git push origin my-new-feature`
  * Create new Pull Request

## Licence

```
The MIT License (MIT)

Copyright (c) 2014 gsick

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```
