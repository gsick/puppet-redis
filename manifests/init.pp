
class redis(
  $version          = hiera('redis::version'),
  $servers          = hiera('redis::servers', { redis_6379 => {} }),
  $conf_dir         = hiera('redis::conf_dir', '/etc/redis'),
  $data_dir         = hiera('redis::data_dir', '/var/lib/redis'),
  $tmp              = hiera('redis::tmp', '/tmp'),
) {

  singleton_packages('gcc', 'wget')

  file { 'conf dir':
    name   => "${conf_dir}",
    ensure => directory,
  }

  file { 'data dir':
    name   => "${data_dir}",
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

  validate_hash($servers)

  create_resources('redis::instance', $servers)
}