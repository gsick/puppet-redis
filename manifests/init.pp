# = Class: redis
#
# This class installs and configure Redis.
#
# == Parameters:
#
# $version:: The version of Redis to download.
#
# $conf_dir::  Configuration directory.
#
# $data_dir::  Data directory.
#
# $servers::  hash of servers instances.
#
# $sysctl::  Apply sysctl overcommit conf.
#
# $tmp::  Temp directory.
#
# == Requires:
#
# Nothing
#
# == Sample Usage:
#
#   class {'redis':
#     version => '2.8.12',
#   }
#
# == Authors
#
# Gamaliel Sick
#
# == Copyright
#
# Copyright 2014 Gamaliel Sick, unless otherwise noted.
#
class redis(
  $version,
  $user             = 'redis',
  $group            = 'redis',
  $user_uid         = undef,
  $group_gid        = undef,
  $servers          = { redis_6379 => {} },
  $conf_dir         = '/etc/redis',
  $data_dir         = '/var/lib/redis',
  $sysctl           = true,
  $limits           = true,
  $tmp              = '/tmp',
) {

  validate_string($version)
  validate_string($user)
  validate_string($group)
  validate_hash($servers)
  validate_absolute_path($conf_dir)
  validate_absolute_path($data_dir)
  validate_bool($sysctl)
  validate_bool($limits)
  validate_absolute_path($tmp)

  ensure_packages(['gcc', 'wget'])

  if($group_gid) {
    group { 'redis group':
      ensure => 'present',
      name   => $group,
      gid    => $group_gid,
    }
  } else {
    group { 'redis group':
      ensure => 'present',
      name   => $group,
    }
  }

  if($user_uid) {
    user { 'redis user':
      ensure  => 'present',
      name    => $user,
      uid     => $user_uid,
      groups  => $group,
      comment => 'redis db user',
      shell   => '/sbin/nologin',
      system  => true,
      require => Group['redis group'],
    }
  } else {
    user { 'redis user':
      ensure  => 'present',
      name    => $user,
      groups  => $group,
      comment => 'redis db user',
      shell   => '/sbin/nologin',
      system  => true,
      require => Group['redis group'],
    }
  }

  file { 'conf dir':
    ensure => directory,
    path   => $conf_dir,
  }

  file { 'data dir':
    ensure  => directory,
    path    => $data_dir,
    owner   => $user,
    group   => $group,
    require => User['redis user'],
  }

  exec { 'download redis':
    cwd     => $tmp,
    path    => '/bin:/usr/bin',
    command => "wget http://download.redis.io/releases/redis-${version}.tar.gz",
    creates => "${tmp}/redis-${version}.tar.gz",
    notify  => Exec['untar redis'],
    require => Package['wget'],
  }

  exec { 'untar redis':
    cwd     => $tmp,
    path    => '/bin:/usr/bin',
    command => "tar -zxvf redis-${version}.tar.gz",
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

  $defaults = {
    'user'  => $user,
    'group' => $group,
  }

  create_resources('redis::instance', $servers, $defaults)

  if ($limits) {
    file { 'limits file':
      ensure  => file,
      name    => '/etc/security/limits.d/redis.conf',
      owner   => root,
      group   => root,
      mode    => '0644',
      content => template("${module_name}/limits_redis.conf.erb"),
    }
  }

  if ($sysctl) {
    # for the next reboot
    file_line { 'sysctl vm.overcommit_memory':
      path  => '/etc/sysctl.conf',
      line  => 'vm.overcommit_memory = 1',
      match => '^((vm.overcommit_memory = )[0-1]{1})$',
    }
    ->
    file_line { 'sysctl net.core.somaxconn':
      path  => '/etc/sysctl.conf',
      line  => 'net.core.somaxconn = 1024',
      match => '^((net.core.somaxconn = )[0-9]+)$',
    }

    # apply now
    exec { 'apply sysctl vm.overcommit_memory':
      cwd     => '/',
      path    => '/sbin:/bin:/usr/bin',
      command => 'sysctl vm.overcommit_memory=1',
    }
    ->
    exec { 'apply sysctl net.core.somaxconn=1024':
      cwd     => '/',
      path    => '/sbin:/bin:/usr/bin',
      command => 'sysctl -w net.core.somaxconn=1024',
    }
    ->
    exec { 'disabled transparent hugepage':
      cwd     => '/',
      path    => '/sbin:/bin:/usr/bin',
      command => 'echo never > /sys/kernel/mm/transparent_hugepage/enabled',
    }
  }
}
