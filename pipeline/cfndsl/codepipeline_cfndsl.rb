CloudFormation {

  git_hub_user ||= nil
  git_hub_token ||= nil
  job_repo ||= nil
  job_repo_branch ||= 'master'
  jenkins_url ||= nil

  version = '2'
  pipeline_name = 'vpc'
  bucket_name_stem = 'vpc-pipeline-artefact-store'

  S3_Bucket('rArtifactStore') {
    BucketName bucket_name_stem

    VersioningConfiguration({
                              'Status' => 'Enabled'
                            })
  }

  IAM_Role('CodePipelineTrustRole') {
    AssumeRolePolicyDocument JSON.load <<-END
      {
        "Statement":[
          {
            "Sid":"1",
            "Effect":"Allow",
            "Principal":{
              "Service":[
                "codepipeline.amazonaws.com"
              ]
            },
            "Action":"sts:AssumeRole"
          }
        ]
      }
    END

    Path '/'

    Policies JSON.load <<-END
      [
        {
          "PolicyName":"CodePipelinePolicy",
          "PolicyDocument":{
            "Version":"2012-10-17",
            "Statement":[
              {
                "Action":[
                  "s3:GetObject",
                  "s3:GetObjectVersion",
                  "s3:GetBucketVersioning",
                  "s3:PutObject"
                ],
                "Resource": [
                  "arn:aws:s3:::#{bucket_name_stem}*"
                 ],
                "Effect":"Allow"
              },
              {
                "Action":[
                  "iam:PassRole"
                ],
                "Resource":"*",
                "Effect":"Allow"
              }
            ]
          }
        }
      ]
    END
  }

  run_static_analysis_action_name = 'run-static-analysis'
  converge_dev_vpc_action_name = 'converge-dev-vpc'
  run_infrastructure_tests_action_name = 'run-infra-tests'
  converge_prod_vpc_action_name = 'converge-prod-vpc'
  # any smoke test for a production vpc convergence?

  vpc_artefact_name = 'vpcWorkspace'

  jenkins_action_provider_name = 'JenkinsVpcProvider'
  Resource('rBuildActionType') {
    Type 'AWS::CodePipeline::CustomActionType'

    Property 'Category', 'Build'
    Property 'Provider', jenkins_action_provider_name
    Property 'Version', version
    Property 'ConfigurationProperties', [
      {
        'Name' => 'ProjectName',
        'Description' => 'The name of the build project must be provided when this action is added to the pipeline.',
        'Key' => true,
        'Queryable' => true,
        'Required' => true,
        'Secret' => false,
        'Type' => 'String'
      }
    ]

    Property 'InputArtifactDetails', {
      'MaximumCount' => '5',
      'MinimumCount' => '1'
    }

    Property 'OutputArtifactDetails', {
      'MaximumCount' => '5',
      'MinimumCount' => '0'
    }

    Property 'Settings', {
      'EntityUrlTemplate' => FnJoin('', [jenkins_url, 'job/{Config:ProjectName}']),
      'ExecutionUrlTemplate' => FnJoin('', [jenkins_url, 'job/{Config:ProjectName}/{ExternalExecutionId}'])
    }
  }


  Resource('rPipeline') {
    Type 'AWS::CodePipeline::Pipeline'

    Property 'Name', pipeline_name

    Property 'RestartExecutionOnUpdate', false

    Property 'Stages', [
      {
         'Name' => 'source',
         'Actions' => [
           {
             'Name' => 'source',
             'ActionTypeId' => {
                 'Category' => 'Source',
                 'Owner' => 'ThirdParty',
                 'Version' => '1',
                 'Provider' => 'GitHub'
             },
             'OutputArtifacts' => [
               {
                 'Name' => vpc_artefact_name
               }
             ],
             'Configuration' => {
                 'Owner' => git_hub_user,
                 'Repo' => job_repo,
                 'Branch' => job_repo_branch,
                 'OAuthToken' => git_hub_token
             }
           }
         ]
      },
      {
         'Name' => 'commit',
         'Actions' => [
           {
             'Name' => run_static_analysis_action_name,
             'ActionTypeId' => {
               'Category' => 'Build',
               'Owner' => 'Custom',
               'Version' => version,
               'Provider' => jenkins_action_provider_name
             },
             'RunOrder' => 1,
             'InputArtifacts' => [
               {
                 'Name' => vpc_artefact_name
               }
             ],
             'OutputArtifacts' => [
               {
                 'Name' => 'static-analysis-ws'
               }
             ],
             'Configuration' => {
               'ProjectName' => run_static_analysis_action_name
             }
           }
         ]
      },
      {
        'Name' => 'acceptance',
        'Actions' => [
          {
            'Name' => converge_dev_vpc_action_name,
            'ActionTypeId' => {
              'Category' => 'Build',
              'Owner' => 'Custom',
              'Version' => version,
              'Provider' => jenkins_action_provider_name
            },
            'RunOrder' => 1,
            'InputArtifacts' => [
              {
                'Name' => 'static-analysis-ws'
              }
            ],
            'OutputArtifacts' => [
              {
                'Name' => 'converge-dev-vpc-ws'
              }
            ],
            'Configuration' => {
              'ProjectName' => converge_dev_vpc_action_name
            }
          },
          {
            'Name' => run_infrastructure_tests_action_name,
            'ActionTypeId' => {
              'Category' => 'Build',
              'Owner' => 'Custom',
              'Version' => version,
              'Provider' => jenkins_action_provider_name
            },
            'RunOrder' => 2,
            'InputArtifacts' => [
              {
                'Name' => 'converge-dev-vpc-ws'
              }
            ],
            'OutputArtifacts' => [
              {
                'Name' => 'run-infra-tests-ws'
              }
            ],
            'Configuration' => {
              'ProjectName' => run_infrastructure_tests_action_name
            }
          }
        ]
      },
      {
        'Name' => 'production',
        'Actions' => [
          {
            'Name' => converge_prod_vpc_action_name,
            'ActionTypeId' => {
              'Category' => 'Build',
              'Owner' => 'Custom',
              'Version' => version,
              'Provider' => jenkins_action_provider_name
            },
            'RunOrder' => 1,
            'InputArtifacts' => [
              {
                'Name' => 'run-infra-tests-ws'
              }
            ],
            'Configuration' => {
              'ProjectName' => converge_prod_vpc_action_name
            }
          }
        ]
      }
    ]

    Property 'ArtifactStore', {
                                'Location' => Ref('rArtifactStore'),
                                'Type' => 'S3'
                              }

    Property 'RoleArn', FnGetAtt('CodePipelineTrustRole', 'Arn')
  }

  Output(:codePipelineName,
         Ref('rPipeline'))
}