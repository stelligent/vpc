#!/bin/bash -ex

gem install bundler --conservative \
                    --version 1.11.2 \
                    --no-ri \
                    --no-rdoc

bundle install

cfndsl cfndsl/vpc_cfndsl.rb > vpc.json

cfn_nag --input-json-path vpc.json