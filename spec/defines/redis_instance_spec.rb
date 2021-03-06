require 'spec_helper'

describe 'redis::instance' do

  let(:title) { 'redis_6379' }
  let(:parser) { 'future' }

  context "with default param" do
    let(:params) { {:servername => 'redis_6379',
                    :version    => '2.8.8',
                    :conf_dir   => '/etc/redis',
                    :data_dir   => '/var/lib/redis',
                    :tmp        => '/tmp'} }

    it do
      should contain_file('data dir redis_6379').with({
        'ensure'  => 'directory',
        'path'    => '/var/lib/redis/6379',
        'require' => 'File[data dir]',
      })
    end

    it do
      should contain_exec('copy default conf file redis_6379').with({
        'cwd'     => '/tmp/redis-2.8.8',
        'path'    => '/bin:/usr/bin',
        'command' => 'cp redis.conf /etc/redis/6379.conf',
        'creates' => '/etc/redis/6379.conf',
        'notify'  => 'File[conf file redis_6379]',
        'require' => ['Exec[install redis]', 'File[conf dir]'],
      })
    end

    it do
      should contain_file('conf file redis_6379').with({
        'ensure'  => 'file',
        'path'    => '/etc/redis/6379.conf',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0644',
        'require' => ['Exec[install redis]', 'File[conf dir]'],
      })
    end

    it do
      should contain_file('init file redis_6379').with({
        'ensure'  => 'file',
        'path'    => '/etc/init.d/redis_6379',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0755',
        'notify'  => 'Service[redis redis_6379]',
      })
    end

    it do
      should contain_file_line('header file conf redis_6379').with({
        'path'    => '/etc/redis/6379.conf',
        'line'    => '# File generated by puppet',
        'match'   => '^((# Redis configuration file example)|(# Example sentinel.conf)|(# File generated by puppet))$',
        'require' => 'File[conf file redis_6379]',
        'notify'  => 'Service[redis redis_6379]',
      })
    end

    it do
      should contain_service('redis redis_6379').with({
        'name'       => 'redis_6379',
        'enable'     => 'true',
        'ensure'     => 'running',
        'hasrestart' => 'true',
        'hasstatus'  => 'false',
        'status'     => '/bin/service redis_6379 status | grep --quiet "Redis is running"',
        'require'    => ['Exec[install redis]', 'File[data dir redis_6379]'],
      })
    end

    it do
      should contain_file_line('conf_redis_6379_daemonize').with({
        'path'    => '/etc/redis/6379.conf',
        'line'    => 'daemonize yes',
        'match'   => '^(#\\s)?(daemonize\\s)(((?!and)(?!192.168.1.100\\s10.0.0.1)(?!is\\sset)[A-Za-z0-9\\._\\-"/\\s]+)|(<master-password>)|(<masterip>\\s<masterport>)|(<bytes>))$',
        'require' => 'File[conf file redis_6379]',
        'notify'  => 'Service[redis redis_6379]',
      })
    end

    it do
      should contain_file_line('conf_redis_6379_port').with({
        'path'    => '/etc/redis/6379.conf',
        'line'    => 'port 6379',
        'match'   => '^(#\\s)?(port\\s)(((?!and)(?!192.168.1.100\\s10.0.0.1)(?!is\\sset)[A-Za-z0-9\\._\\-"/\\s]+)|(<master-password>)|(<masterip>\\s<masterport>)|(<bytes>))$',
        'require' => 'File[conf file redis_6379]',
        'notify'  => 'Service[redis redis_6379]',
      })
    end

    it do
      should contain_file_line('conf_redis_6379_pidfile').with({
        'path'    => '/etc/redis/6379.conf',
        'line'    => 'pidfile /var/run/redis_6379.pid',
        'match'   => '^(#\\s)?(pidfile\\s)(((?!and)(?!192.168.1.100\\s10.0.0.1)(?!is\\sset)[A-Za-z0-9\\._\\-"/\\s]+)|(<master-password>)|(<masterip>\\s<masterport>)|(<bytes>))$',
        'require' => 'File[conf file redis_6379]',
        'notify'  => 'Service[redis redis_6379]',
      })
    end

    it do
      should contain_file_line('conf_redis_6379_logfile').with({
        'path'    => '/etc/redis/6379.conf',
        'line'    => 'logfile /var/log/redis_6379.log',
        'match'   => '^(#\\s)?(logfile\\s)(((?!and)(?!192.168.1.100\\s10.0.0.1)(?!is\\sset)[A-Za-z0-9\\._\\-"/\\s]+)|(<master-password>)|(<masterip>\\s<masterport>)|(<bytes>))$',
        'require' => 'File[conf file redis_6379]',
        'notify'  => 'Service[redis redis_6379]',
      })
    end

    it do
      should contain_file_line('conf_redis_6379_dir').with({
        'path'    => '/etc/redis/6379.conf',
        'line'    => 'dir /var/lib/redis/6379',
        'match'   => '^(#\\s)?(dir\\s)(((?!and)(?!192.168.1.100\\s10.0.0.1)(?!is\\sset)[A-Za-z0-9\\._\\-"/\\s]+)|(<master-password>)|(<masterip>\\s<masterport>)|(<bytes>))$',
        'require' => 'File[conf file redis_6379]',
        'notify'  => 'Service[redis redis_6379]',
      })
    end

  end

  context "with default_template param" do
    let(:params) { {:servername => 'redis_6379',
                    :version    => '2.8.8',
                    :conf_dir   => '/etc/redis',
                    :data_dir   => '/var/lib/redis',
                    :tmp        => '/tmp'} }
    let(:params) { {:default_template => false} }

    it do
      should_not contain_exec('copy default conf file redis_6379')
    end

    it do
      should_not contain_file_line('header file conf redis_6379')
    end

  end

end
