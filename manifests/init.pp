
class redis(
  $version          = hiera('redis::version'),
  $servers          = hiera('redis::servers', { srv1 => {} }),
  $conf_dir         = hiera('redis::conf_dir', '/etc/redis'),
  $tmp              = hiera('redis::tmp', '/tmp'),
) {

  singleton_packages('gcc', 'wget')

  file { 'conf dir':
    name   => "${conf_dir}",
    ensure => directory,
  }

  exec { 'download redis':
    cwd     => "${tmp}",
    command => "/usr/bin/wget http://download.redis.io/releases/redis-${version}.tar.gz",
    creates => "${tmp}/redis-${version}.tar.gz",
    notify  => Exec['untar redis'],
    require => Package['wget'],
  }

  exec { 'untar redis':
    cwd     => "${tmp}",
    command => "/bin/tar -zxvf redis-${version}.tar.gz",
    creates => "${tmp}/redis-${version}/Makefile",
    notify  => Exec['install redis'],
  }

  exec { 'install redis':
    cwd     => "${tmp}/redis-${version}",
    command => 'make && make install',
    path    => '/bin:/usr/bin',
    creates => '/usr/local/bin/redis-server',
    require => Package['gcc'],
  }

  # It's more programmatically, but I don't want a fuck*** template...
  # More chance to have auto-compatibility with future version
  # and it's just fun sometimes

  if (!empty($servers)) {
    validate_hash($servers)

create_resources('redis::instance', $servers)

    $servers.each |$key, $value| {

      $conf = $value[conf]
      validate_hash($conf)

      if ($value[sentinel]) {
        $default_conf_file = 'sentinel.conf'
        $sentinel = true
      } else {
        $default_conf_file = 'redis.conf'
        $sentinel = false
      }

      # default value if not set
      if (empty($conf) or $conf[port] == '') {
        $port = 6379
      } else {
        $port = $conf[port]
      }

      if (empty($conf) or $conf[pidfile] == '') {
        $pidfile = "/var/run/redis_${port}.pid"
      } else {
        $pidfile = $conf[pidfile]
      }

      if (empty($conf) or $conf[logfile] == '') {
        $logfile = "/var/log/redis_${port}.log"
      } else {
        $logfile = $conf[logfile]
      }

      if (empty($conf) or $conf[dir] == '') {
        $dir = "/var/lib/redis/${port}"
      } else {
        $dir = $conf[dir]
      }

      file { "data dir ${key}":
        name   => "${dir}",
        ensure => directory,
      }

      file { "init file ${key}":
        name    => "/etc/init.d/redis_${port}",
        owner   => root,
        group   => root,
        mode    => 755,
        content => template("${module_name}/redis_port.erb"),
        notify  => Service["redis ${key}"],
      }

      # copy redis.conf or sentinel.conf
      exec { "copy default conf file ${key}":
        cwd     => "${tmp}/redis-${version}",
        command => "cp ${default_conf_file} ${conf_dir}/${port}.conf",
        path    => '/bin:/usr/bin',
        creates => "${conf_dir}/${port}.conf",
        require => [Exec['install redis'], File['conf dir']],
      }

      $conf_tmp = merge($conf, {port => $port, pidfile => $pidfile, logfile => $logfile, dir => $dir})

      # override properties
      if (!empty($conf_tmp)) {
        $conf_tmp.each |$keyc, $valuec| {
          file_line { "conf_${key}_${keyc}":
            path    => "${conf_dir}/${port}.conf",
            line    => "${keyc} ${valuec}",
            match   => "^(#\s)?(${keyc}\s)((?!and)[A-Za-z0-9\\._\\-\"/\s]+)$",
            require => Exec["copy default conf file ${key}"],
            notify  => Service["redis ${key}"],
          }
        }
      }

      service { "redis ${key}":
        name => "redis_${port}",
        enable => true,
        ensure => running,
        hasrestart => true,
        hasstatus => false,
        status => "/bin/service redis_${port} status | grep --quiet \"Redis is running\"",
        require => [Exec['install redis'], File["data dir ${key}"]],
      }
    }
  }
}