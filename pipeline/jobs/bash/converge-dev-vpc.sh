#!/bin/bash -ex

gem install bundler --conservative \
                    --version 1.11.2 \
                    --no-ri \
                    --no-rdoc

bundle install

export AWS_REGION=us-west-2

cfndsl_converge --path-to-stack cfndsl/vpc_cfndsl.rb \
                --path-to-yaml tiers/dev.yml \
                --stack-name dev-vpc-base \
                --fail-on-changes-to-immutable-resource true

