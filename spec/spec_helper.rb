require 'rubygems'
require 'puppetlabs_spec_helper/module_spec_helper'
require 'coveralls'

Coveralls.wear!

RSpec.configure do |c|
  c.default_facts = {
    :osfamily        => 'RedHat',
    :operatingsystem => 'CentOS',
    :architecture    => 'x86_64',
  }
end
