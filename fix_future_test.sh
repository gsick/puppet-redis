#!/bin/sh
set -ev

cd ..
git clone https://github.com/rodjek/rspec-puppet.git
cd rspec-puppet
bundle install
gem build rspec-puppet.gemspec
gem install rspec-puppet-*.gem

cd ..
git clone https://github.com/rodjek/puppet-lint.git
cd puppet-lint
bundle install
gem build puppet-lint.gemspec
gem install puppet-lint-*.gem

cd ../puppet-redis
