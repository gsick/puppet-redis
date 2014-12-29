# = Class: redis::instance
#
# This class installs and configure Redis.
#
# == Parameters:
#
# $servername:: The name of the server, just for have unique puppet task.
#
# $conf::  Hash of properties.
#
# $sentinel::  boolean, true if sentinel.
#
# $default_template::  boolean, true override redis default conf file.
#
# == Requires:
#
# Nothing
#
# == Sample Usage:
#
#   create_resources('redis::instance', $servers)
#
# == Authors
#
# Gamaliel Sick
#
# == Copyright
#
# Copyright 2014 Gamaliel Sick, unless otherwise noted.
#
# default values come from install_server.sh
define redis::instance(
  $servername       = $name,
  $conf             = {},
  $user             = 'redis',
  $group            = 'redis',
  $sentinel         = false,
  $default_template = true,

# Add these var for unit test
  $version          = $redis::version,
  $conf_dir         = $redis::conf_dir,
  $data_dir         = $redis::data_dir,
  $tmp              = $redis::tmp,
) {

  # It's more programmatically, but I don't want a fuck*** template
  # and it is already provided by redis
  # More chance to have auto-compatibility with future version
  # and it's just fun sometimes

  # check parameters
  validate_string($servername)
  validate_hash($conf)
  validate_bool($sentinel)
  validate_bool($default_template)

  # default value if not set
  if (is_integer($conf[port])) {
    $port = $conf[port]
  } else {
    $port = $sentinel ? { default => 6379, true => 26389 }
  }

  if (empty($conf) or empty($conf[pidfile])) {
    $pidfile = "/var/run/redis_${port}.pid"
  } else {
    $pidfile = $conf[pidfile]
  }

  if (empty($conf) or empty($conf[logfile])) {
    file { "log dir ${servername}":
      ensure  => directory,
      path    => '/var/log/redis',
      owner   => $user,
      group   => $group,
      require => User['redis user'],
    }
    $logfile = "/var/log/redis/redis_${port}.log"
  } else {
    $logfile = $conf[logfile]
  }

  if (empty($conf) or empty($conf[dir])) {
    $dir = "${data_dir}/${port}"
  } else {
    $dir = $conf[dir]
  }

  file { "data dir ${servername}":
    ensure  => directory,
    path    => $dir,
    require => File['data dir'],
  }

  $conf_tmp = merge({daemonize => 'yes'}, $conf, {port => $port, pidfile => $pidfile, logfile => $logfile, dir => $dir})

  if($default_template) {

    # select the good template
    if ($sentinel) {
      $default_conf_file = 'sentinel.conf'
    } else {
      $default_conf_file = 'redis.conf'
    }

    # copy redis.conf or sentinel.conf
    exec { "copy default conf file ${servername}":
      cwd     => "${tmp}/redis-${version}",
      command => "cp ${default_conf_file} ${conf_dir}/${port}.conf",
      path    => '/bin:/usr/bin',
      creates => "${conf_dir}/${port}.conf",
      require => [Exec['install redis'], File['conf dir']],
      notify  => File["conf file ${servername}"],
    }
  }

  # create an empty file if $default_template == false
  file { "conf file ${servername}":
    ensure  => file,
    path    => "${conf_dir}/${port}.conf",
    owner   => root,
    group   => root,
    mode    => '0644',
    require => [Exec['install redis'], File['conf dir']],
  }

  file { "init file ${servername}":
    ensure  => file,
    name    => "/etc/init.d/redis_${port}",
    owner   => root,
    group   => root,
    mode    => '0755',
    content => template("${module_name}/redis_port.erb"),
    notify  => Service["redis ${servername}"],
  }

  # override properties
  $conf_tmp.each |$key, $value| {

    # TODO, clean this mess
    # maybe replace by slice function but need puppet 3.5
    $key_arr = split($key, '#')
    $size = size($key_arr)
    if($size == 2) {
      $final_key = $key_arr[1]
      $line = "# ${final_key} ${value}"
    } else {
      $final_key = $key_arr[0]
      $line = "${final_key} ${value}"
    }

    # magic regex
    $regex = "^(#\\s)?(${final_key}\\s)\
(((?!and)(?!192.168.1.100\\s10.0.0.1)\
(?!is\\sset)\
[A-Za-z0-9\\._\\-\"/\\s]+)\
|(<master-password>)|(<masterip>\\s<masterport>)\
|(<bytes>))$"

    file_line { "conf_${servername}_${final_key}":
      path    => "${conf_dir}/${port}.conf",
      line    => $line,
      match   => $regex,
      require => File["conf file ${servername}"],
      notify  => Service["redis ${servername}"],
    }
  }

  if($default_template) {
    # for fun
    file_line { "header file conf ${servername}":
      path    => "${conf_dir}/${port}.conf",
      line    => '# File generated by puppet',
      match   => '^((# Redis configuration file example)|(# Example sentinel.conf)|(# File generated by puppet))$',
      require => File["conf file ${servername}"],
      notify  => Service["redis ${servername}"],
    }
  }

  service { "redis ${servername}":
    ensure     => running,
    name       => "redis_${port}",
    enable     => true,
    hasrestart => true,
    hasstatus  => false,
    status     => "/bin/service redis_${port} status | grep --quiet \"Redis is running\"",
    require    => [Exec['install redis'], File["data dir ${servername}"]],
  }
}
