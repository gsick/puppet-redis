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
  $servers          = { redis_6379 => {} },
  $conf_dir         = '/etc/redis',
  $data_dir         = '/var/lib/redis',
  $sysctl           = true,
  $tmp              = '/tmp',
) {

  validate_string($version)
  validate_hash($servers)
  validate_absolute_path($conf_dir)
  validate_absolute_path($data_dir)
  validate_bool($sysctl)
  validate_absolute_path($tmp)

  ensure_packages(['gcc', 'wget'])

  file { 'conf dir':
    ensure => directory,
    path   => $conf_dir,
  }

  file { 'data dir':
    ensure => directory,
    path   => $data_dir,
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

  create_resources('redis::instance', $servers)

  if ($sysctl) {
    # for the next reboot
    file_line { 'sysctl':
      path  => '/etc/sysctl.conf',
      line  => 'vm.overcommit_memory = 1',
      match => '^((vm.overcommit_memory = )[0-1]{1})$',
    }

    # apply now
    exec { 'apply sysctl':
      cwd     => '/',
      path    => '/sbin:/bin:/usr/bin',
      command => 'sysctl vm.overcommit_memory=1',
    }
  }
}