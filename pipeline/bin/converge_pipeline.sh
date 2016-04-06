#!/bin/bash -ex

bundle install

jenkins_factory --jenkins-settings-yml-path pipeline/tiers/jenkins.yml \
                --url-output-path jenkins_url

pipeline/bin/converge_cpl.sh

