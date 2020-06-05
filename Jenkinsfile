 def env_var = 'dev'
def branch
def path_to_pom ='hello.service.application.parent/pom.xml'
def email
def tag_number
 
def approvers() {
   return ["anit.sharma@techolution.com", "ADEW1@xl.co.id", "khairulz@xl.co.id"]
}
//testing 1
pipeline {
      options { disableConcurrentBuilds()
                gitLabConnection('gitrepo')
                skipDefaultCheckout(true)
                }
      // use only anthos jenkins node
      agent { node { label 'GKE_ANTHOS'
               } }
      //   Defining Stages
       stages {
        
          stage('Code Checkout') {
 
              steps {
                  script {
                       sh "printenv | sort"
                      
                      if (env.gitlabActionType == 'NOTE' && env.gitlabTriggerPhrase == 'approved' && check_approver(env.gitlabUserEmail) ) {
                          if(env.gitlabTargetBranch == 'master')
                          {
                          echo 'Merge Request detected !! checking out Source Branch'
                          env_var = 'staging'
                          branch = "${gitlabSourceBranch}"
                          checkout_code(branch)
                          }
                      }
                      else if (env.BRANCH_NAME == 'sit')
                          {
                          echo 'No Merge Request detected !! checking out Current Branch'
                          env_var = 'sit'
                          branch = "${BRANCH_NAME}"
                          checkout_code(branch)
                          }
                       else if (env.GIT_BRANCH == 'origin/master')
                          {
                          echo 'No Merge Request detected !! checking out Current Branch'
                          env_var = 'staging'
                          branch = "master"
                          checkout_code(branch)
                          }
                       else if (env.gitlabActionType == 'TAG_PUSH')
                         {
                       //  echo 'No Merge Request detected !! checking out Current Branch'
                         env_var = 'production'
                         branch = "master"
                         checkout_code(branch)
                         }
                       else
                         {
                         branch = "${BRANCH_NAME}"
                         checkout_code(branch)
                         }

 
                  }
                
              }
              }
          stage('Unit Testing') {
 
              steps {
                  script {
                      sh "ls -a"
                      sh "pwd"
                    //  unitTest(path_to_pom)
                  }
              }
          }
 
          stage('Merge Code') {
                  when {
                      expression { env_var == 'staging' }
                   }
              steps {
               script {
                   echo " Merge Request Detected!!  Merging"
                  
                   checkout ([
                               $class: 'GitSCM',
                               branches: [[name: "origin/${env.gitlabSourceBranch}"]],
                               extensions: [
                                               [$class: 'CleanCheckout'],
                                               [
                                                   $class: 'PreBuildMerge',
                                                   options: [
                                                               fastForwardMode: 'NO_FF',
                                                               mergeRemote: "origin",
                                                               mergeTarget: env.gitlabTargetBranch
                                                           ]
                                               ]
                                           ],
                               userRemoteConfigs: [[credentialsId: 'gitrepo-access', url: 'git@gitrepo.intra.excelcom.co.id:anthos/application-code/hello.service.git']]
                                  ])
             
                     sh "git push origin HEAD:master"
                    
                    
                  }
              }
          }
          stage('Build ') {
              
           when {
                     expression { env_var == 'staging' ||  env.BRANCH_NAME == 'sit' || env_var == 'production'}
               }
              
              steps{
              script{
                 echo "${BUILD_NUMBER}"
                 tag_number ="${BUILD_NUMBER}"
 
                 echo "${BUILD_ID}"
                
                 trigger_build(env_var,tag_number)
              }
              }
          }
          stage('VeraCode Testing') {
                  when {
                      expression { env_var == 'staging' }
                   }
              steps{
               
                 echo "Verracode testing In Progress"
              }
          }
 
          stage('Deploy') {
         
           when {
                     expression { env_var == 'staging' ||  env.BRANCH_NAME == 'sit' || env_var == 'production'}
               }
              
              steps{
                   script{
                 trigger_deploy(env_var,tag_number)
                 echo 'Deploy stage completed'
                }
              }
          }
        
           stage('Automation API Testing') {
 
                  when {
                      expression { env_var == 'staging' }
                   }
                  
              
              steps{
                script{
                try{
                 echo "Automation API testing In Progress"
                 
                // sh "invalid_command"
                 }
                 catch(e)
                 {
                
                 echo " Rolling back the deployment"
                 sh '''
                 sleep 50
                 gcloud container clusters get-credentials xl-gke-prod --region asia-southeast1 --project anthos-alpha-5929
                 export no_proxy='10.44.0.192/28'
                 kubectl rollout undo deployments hello-application -n sit
                 '''
                  echo " catch block reached- - Reverting MR"
                   sh '''
                   ansible-playbook --connection local  /opt/anthos/ansible/xl-revert-mr.yml\
                   --extra-vars "git_repo_uri='${gitlabTargetRepoSshUrl}' git_repo_path='/tmp/repo/anthos/hello-application' gitlab_personal_token=1P1zsWm6uQ9afzyYA3Kr gitlab_project_id='${gitlabMergeRequestTargetProjectId}' merge_request_iid='${gitlabMergeRequestIid}'" \
                   --tags "revert_mr" -vv
                   '''
                   echo "Code Rollback in GItlab Finished Successfully"
                   error ("this build is intentionally being marked as failed")
                 }
                 }
             
              }
            
          }
         
   
        
          stage('Accunetix Testing') {
                  when {
                      expression { env_var == 'staging' }
                   }
              steps{
               
                 echo "Accunetix testing In Progress"
              }
          }
      // End of stages
      }
// End of the pipeline
}
def checkout_code (branch) {
 
sh "echo ${branch}"
 
checkout changelog: true, poll: true, scm: [
    $class: 'GitSCM',
    branches: [[name: "origin/${branch}"]],
    doGenerateSubmoduleConfigurations: false,
    submoduleCfg: [],
    userRemoteConfigs: [[credentialsId: 'gitrepo-access', url: 'git@gitrepo.intra.excelcom.co.id:anthos/application-code/hello.service.git']]
   ]
}
def unitTest(path_to_pom) {
sh "mvn clean test -P{env.env_ansible} -f ${path_to_pom}"
}
def trigger_build(env_var,tag_number){
  if (env_var == 'sit')
  {
      build job: 'GKE Anthos/Sample Application - SIT/Sample Application Build - SIT', parameters: [string(name: 'projectname', value: 'gkeanthossampleapp'), string(name: 'app_name', value: 'hello-application'), string(name: 'tag', value: 'all'), string(name: 'repo_name', value: 'git@gitrepo.intra.excelcom.co.id:anthos/application-code/hello.service.git '), string(name: 'branch_name', value: 'sit'), string(name: 'env', value: 'sit'), string(name: 'maven_test_skip', value: 'yes'), string(name: 'pom_path_relative', value: 'hello.service.application.parent/pom.xml'), string(name: 'build_time_repo_path', value: '/opt/repo/anthos'), string(name: 'gcp_project_id', value: 'anthos-alpha-5929'), string(name: 'build_number_var', value: tag_number)]
  }
  else if (env_var == 'staging')
  {   
    
      build job: 'GKE Anthos/Sample Application - Staging/Sample Application Build - Staging', parameters: [string(name: 'project_name', value: 'gkeanthossampleapp'), string(name: 'app_name', value: 'hello-application'), string(name: 'tag', value: 'all'), string(name: 'repo_name', value: 'git@gitrepo.intra.excelcom.co.id:anthos/application-code/hello.service.git'), string(name: 'branch_name', value: 'master'), string(name: 'env', value: 'staging'), string(name: 'maven_test_skip', value: 'yes'), string(name: 'pom_path_relative', value: 'hello.service.application.parent/pom.xml'), string(name: 'build_time_repo_path', value: '/opt/repo/anthos'), string(name: 'gcp_project_id', value: 'anthos-alpha-5929'), string(name: 'build_number_var', value: tag_number)]
  }
  else if (env_var == 'production')
  {   
    
      build job: 'GKE Anthos/Sample Application - Production/Sample Application Build - Production', parameters: [string(name: 'projectname', value: 'gkeanthossampleapp'), string(name: 'app_name', value: 'hello-application'), string(name: 'tag', value: 'build_app'), string(name: 'repo_name', value: 'git@gitrepo.intra.excelcom.co.id:anthos/application-code/hello.service.git '), string(name: 'branch_name', value: 'master'), string(name: 'env', value: 'production'), string(name: 'pom_path_relative', value: 'hello.service.application.parent/pom.xml'), string(name: 'build_time_repo_path', value: '/opt/repo/anthos'), string(name: 'gcp_project_id', value: 'anthos-alpha-5929'), string(name: 'build_number_var', value: tag_number)]
  }
}
 
def trigger_deploy(env_var,tag_number){
  if (env_var == 'sit')
  {
      build job: 'GKE Anthos/Sample Application - SIT/Sample Application Deploy - SIT', parameters: [string(name: 'projectname', value: 'gkeanthossampleapp'), string(name: 'app_name', value: 'hello-application'), string(name: 'tag', value: 'deploy'), string(name: 'repo_name', value: 'xl-helm-private'), string(name: 'branch_name', value: 'sit'), string(name: 'env', value: 'sit'), string(name: 'bucket_path', value: 'https://xl-helm-packages.storage.googleapis.com'), string(name: 'build_number_var', value: tag_number), string(name: 'app_namespace', value: 'sit'), string(name: 'values_file_rel_path', value: '/opt/repo/anthos/hello-application/values.yaml'), string(name: 'image_tag', value: '')]
  }
  else if (env_var == 'staging')
  {
      build job: 'GKE Anthos/Sample Application - Staging/Sample Application Deploy - Staging', parameters: [string(name: 'project_name', value: 'gkeanthossampleapp'), string(name: 'app_name', value: 'hello-application'), string(name: 'tag', value: 'deploy'), string(name: 'repo_name', value: 'xl-helm-private'), string(name: 'branch_name', value: 'master'), string(name: 'env', value: 'staging'), string(name: 'bucket_path', value: 'https://xl-helm-packages.storage.googleapis.com'), string(name: 'build_number_var', value: tag_number), string(name: 'app_namespace', value: 'sit'), string(name: 'values_file_rel_path', value: '/home/xl/workspace/GKE Anthos/test-connection/values.yaml'), string(name: 'image_tag', value: '')]
  }
}
 
def check_approver(email)
{
   if(approvers().contains(email))
   {return true}
}