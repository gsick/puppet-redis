puppet-redis
============

Redis installation and configuration module.<br />
[Redis](http://redis.io)<br />

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

It will create `/etc/redis/6379.conf` [see file](http://pastebin.com/xZaKysam).
The default template configuration comes from redis.conf provided by the original package.<br />
Only these default values are uncommented/added/changed:

```text
daemonize yes
pidfile /var/run/redis_6379.pid
port 6379
logfile /var/log/redis_6379.log
dir /var/lib/redis/6379
```

#### Redis sentinel

In your hieradata file

```yaml
---
redis::version: 2.8.7
redis::servers:
    redis_26389:
        sentinel: true
```

It will create `/etc/redis/26389.conf` [see file](http://pastebin.com/4Cje5NsJ).
The default template configuration comes from sentinel.conf provided by the original package.<br />
Only these default values are uncommented/added/changed:

```text
daemonize yes
pidfile /var/run/redis_26389.pid
port 26389
logfile /var/log/redis_26389.log
dir /var/lib/redis/26389
```

### Service

```bash
$ service redis_${port} start/stop/restart
```

### Advanced configuration

#### Create conf file from scratch (no template)

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

#### Available properties















## Authors

Gamaliel Sick

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
