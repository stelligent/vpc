jobName = 'converge-prod-vpc'
awsRegion = 'us-west-2'
customActionTypeVersion = 2

job(jobName) {
  triggers {
    scm('* * * * *')
  }

  steps {
    shell(readFileFromWorkspace("pipeline/jobs/bash/${jobName}.sh"))
  }

  configure { project ->
    project.remove(project / scm) // remove the existing 'scm' element

    project / scm(class: 'com.amazonaws.codepipeline.jenkinsplugin.AWSCodePipelineSCM', plugin: 'codepipeline@0.8') {
      clearWorkspace true
      actionTypeCategory 'Build'
      actionTypeProvider 'buildActionProvider'
      projectName jobName
      actionTypeVersion customActionTypeVersion
      region awsRegion

      //this rubbish is apparently necessary, even with instance profiles
      awsAccessKey ''
      awsSecretKey ''
      proxyHost ''
      proxyPort '0'
      awsClientFactory ''
    }
  }

  wrappers {
    rvm('2.2.1@converge')
  }
}