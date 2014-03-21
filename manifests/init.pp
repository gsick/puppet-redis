
class redis(
  $version          = hiera('redis::version'),
  $conf             = hiera('redis::conf', {}),
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

  file { 'data dir':
    name   => "${dir}",
    ensure => directory,
  }

  file { "init file":
    name    => "/etc/init.d/redis_${port}",
    owner   => root,
    group   => root,
    mode    => 755,
    content => template("${module_name}/redis_init_script.tpl.erb"),
    notify  => Service['redis'],
  }

  exec { 'copy default conf file':
    cwd     => "${tmp}/redis-${version}",
    command => "cp redis.conf ${conf_dir}/${port}.conf",
    path    => '/bin:/usr/bin',
    creates => "${conf_dir}/${port}.conf",
    require => [Exec['install redis'], File['conf dir']],
    }

  $conf_tmp = merge($conf, {port => $port, pidfile => $pidfile, logfile => $logfile, dir => $dir})

  if (!empty($conf_tmp)) {
    $conf_tmp.each |$key, $value| {
      file_line { "conf_${key}":
        path    => "${conf_dir}/${port}.conf",
        line    => "${key} ${value}",
        match   => "^(${key}\s).*$",
        require => Exec['copy default conf file'],
        notify  => Service['redis'],
      }
    }
  }

  service { 'redis':
    name => "redis_${port}",
    enable => true,
    ensure => running,
    hasrestart => true,
    hasstatus => false,
    require => [Exec['install redis'], File['data dir']],
  }

}