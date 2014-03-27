require 'spec_helper'

describe 'redis::instance' do

  let(:title) { 'redis::instance' }

  context "with default param" do
    let(:params) { {:servername => 'redis_6379',
                    :version    => '2.8.7',
                    :conf_dir   => '/etc/redis',
                    :data_dir   => '/var/lib/redis',
                    :tmp        => '/tmp'} }

    it do
      should contain_exec('copy default conf file redis_6379').with({
        'cwd'     => '/tmp/redis-2.8.7',
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
        'mode'    => '644',
        'require' => ['Exec[install redis]', 'File[conf dir]'],
      })
    end

    it do
      should contain_file('init file redis_6379').with({
        'ensure'  => 'file',
        'path'    => '/etc/init.d/redis_6379',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '755',
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

  end

  context "with default_template param" do
    let(:params) { {:servername => 'redis_6379',
                    :version    => '2.8.7',
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
at_exit { RSpec::Puppet::Coverage.report! }
