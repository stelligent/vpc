#!/bin/bash -ex

gem install bundler --conservative \
                    --version 1.11.2 \
                    --no-ri \
                    --no-rdoc
                    
bundle install

rspec spec/vpc_spec.rb