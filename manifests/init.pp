
class redis(
  $version                = hiera('redis::version'),
  $port                  = hiera('redis::port', 6379),
  
  $tmp                    = hiera('redis::tmp', '/tmp'),
  
  
  
  $group                  = hiera('redis::group', 'redis'),
  $user                   = hiera('redis::user', 'redis'),
  $home                   = hiera('redis::home', '/opt/redis'),
  $log                    = hiera('jetty::log', '/var/log/jetty'),
  
  $redis_properties        = hiera('redis::redis_properties', undef),
  $conf_dir                   = hiera('redis::conf_dir', '/etc/redis'),
  $overwrite_default_conf        = hiera('redis::overwrite_default_conf', true),
) {

  singleton_packages("wget")

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
    creates => "${tmp}/redis-${version}",
    notify => Exec['install redis'],
  }

  exec { 'install redis':
    cwd => "${tmp}/redis-${version}",
    command => "/usr/bin/make && /usr/bin/make install",
    path => '/bin:/usr/bin',
    #unless => "test $(${redis_bin_dir}/bin/redis-server --version | cut -d ' ' -f 1) = 'Redis'",
    require => Package['gcc'],
  }
  
}