pipeline {
  agent {
    node {
      label 'cron-sh-01'
    }
  }
  stages {
    stage('Verification') {
      steps {
        parallel(
          "Code check ": {
            sh 'echo "code"'
            
          },
          "Unit check": {
            sh 'echo "unit"'
            
          }
        )
      }
    }
    stage('Build') {
      steps {
        sh 'echo build'
      }
    }
    stage('UAT test') {
      steps {
        sh 'echo uat'
      }
    }
    stage('Deploy') {
      steps {
        sh 'echo deploy'
      }
    }
  }
}
