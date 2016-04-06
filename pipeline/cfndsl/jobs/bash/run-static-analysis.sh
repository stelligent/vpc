#!/bin/bash -ex

bundle install

cfndsl cfndsl/vpc_cfndsl.rb > vpc.json

cfn_nag --input-json-path ${vpc.json}