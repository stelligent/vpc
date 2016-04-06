#!/bin/bash -ex

if [[ ! -f jenkins_url ]];
then
  echo jenkins_url file must be fed by converge_pipeline
  exit 1
fi

jenkins_url=$(cat jenkins_url)

cat <<END > input.yml
$(cat pipeline/tiers/pipeline.yml)
jenkins_url: ${jenkins_url}
END

bundle install

cfndsl_converge --path-to-stack pipeline/cfndsl/codepipeline_cfndsl.rb \
                --path-to-yaml input.yml \
                --stack-name vpc-deployment-pipeline

