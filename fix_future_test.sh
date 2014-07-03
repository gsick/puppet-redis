#!/bin/sh
set -ev

cd ..
git clone https://github.com/rodjek/puppet-lint.git
cd puppet-lint
gem build puppet-lint.gemspec
gem install puppet-lint-*.gem

cd ../puppet-redis
