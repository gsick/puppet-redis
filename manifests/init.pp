
class redis(
  $version                = hiera('redis::version'),
  $conf        = hiera('redis::conf', {}),
  $conf_dir                   = hiera('redis::conf_dir', '/etc/redis'),
  $overwrite_default_conf        = hiera('redis::overwrite_default_conf', true),
  
  
  $port                  = hiera('redis::port', 6379),
  
  $tmp                    = hiera('redis::tmp', '/tmp'),
  
  
  
  $group                  = hiera('redis::group', 'redis'),
  $user                   = hiera('redis::user', 'redis'),
  $home                   = hiera('redis::home', '/opt/redis'),
  $log                    = hiera('jetty::log', '/var/log/jetty'),
) {

  singleton_packages('gcc', 'wget')

  exec { 'download redis':
    cwd => "${tmp}",
    command => "/usr/bin/wget http://download.redis.io/releases/redis-${version}.tar.gz",
    creates => "${tmp}/redis-${version}.tar.gz",
    notify => Exec['untar redis'],
    require => Package['wget'],
  }

  exec { 'untar redis':
    cwd => "${tmp}",
    command => "/bin/tar -zxvf redis-${version}.tar.gz",
    creates => "${tmp}/redis-${version}/Makefile",
    notify => Exec['install redis'],
  }

  exec { 'install redis':
    cwd => "${tmp}/redis-${version}",
    command => 'make && make install',
    path => '/bin:/usr/bin',
    creates => '/usr/local/bin/redis-server',
    require => Package['gcc'],
  }

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
  
  $conf[pidfile] = $pidfile

  if $overwrite_default_conf {
    exec { 'copy default conf file':
      cwd => "${tmp}/redis-${version}",
      command => "cp redis.conf ${conf_dir}/${port}.conf",
      path => '/bin:/usr/bin',
      creates => "${conf_dir}/${port}.conf",
      require => Exec['install redis'],
    }
  } else {
    file { 'create conf file':
      name => "${port}.conf",
      path => "${conf_dir}",
      ensure => present,
      require => Exec['install redis'],
    }
  }

  if (!empty($conf)) {
    $conf.each |$key, $value| {
      file_line { "conf_${key}":
        path => "${conf_dir}/${port}.conf",
        line => "${key} ${value}",
        match => "^(${key}\s).*$",
        require => [File['create conf file'], Exec['copy default conf file']],
      }
    }
  }

}