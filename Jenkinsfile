def label = "worker-${UUID.randomUUID().toString()}"

// build parameters are automatically bound to environnements variables
properties([parameters(parametersBuildDocker())])

templateDocker {
  withCredentials([usernamePassword(credentialsId: "${params.DOCKER_CREDENTIALS}", usernameVariable: 'REGISTRY_USER', passwordVariable: 'REGISTRY_PASSWORD')]) {

    stage('init') {
      def myRepo = checkout scm
      sh "cat Jenkinsfile"
      sh "env"
      container('docker') {
        sh "docker login -u ${REGISTRY_USER} -p ${REGISTRY_PASSWORD} ${params.DOCKER_REGISTRY}"
      }
    }

    stage('all') {
      container('docker') {
        sh "bash ./build.sh"
      }
    }
  }
}
