#!/bin/bash -ex

gem install bundler --conservative \
                    --version 1.11.2 \
                    --no-ri \
                    --no-rdoc
                    
bundle install

export AWS_REGION=us-west-2

rspec spec/vpc_spec.rb