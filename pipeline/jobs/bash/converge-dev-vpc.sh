#!/bin/bash -ex

bundle install

cfndsl_converge --path-to-stack cfndsl/vpc_cfndsl.rb \
                --path-to-yaml tiers/dev.yml \
                --stack-name dev-vpc-base

