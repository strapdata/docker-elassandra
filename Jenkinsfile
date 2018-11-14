def label = "worker-${UUID.randomUUID().toString()}"

// build parameters are automatically bound to environnements variables
properties([
  parameters([
    string(defaultValue: '', description: 'The base image to inherit', name: 'BASE_IMAGE', trim: true),
    string(defaultValue: '', description: 'The name of the image prefixed by the folder (e.g strapdata/elassandra)', name: 'REPO_NAME', trim: true),
    string(defaultValue: 'container-nexus.azure.strapcloud.com', description: 'The registry to use to publish the images', name: 'DOCKER_REGISTRY', trim: true),
    string(defaultValue: '', description: 'The hash of the elassandra commit', name: 'ELASSANDRA_COMMIT', trim: true),
    string(defaultValue: '', description: 'URL of the debian package used to build the image', name: 'PACKAGE_LOCATION', trim: true),

    // give the name of a stored jenkins credentials that could then be fetched
    credentials(credentialType: 'com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl',
                defaultValue: 'nexus-jenkins-deployer', description: 'Credentials to login to the registry',
                name: 'DOCKER_CREDENTIALS', required: false),

    booleanParam(defaultValue: false, description: 'If true, run simple tests', name: 'DOCKER_RUN_TESTS'),
    booleanParam(defaultValue: false, description: 'True if the version is the latest of its major version branch.', name: 'DOCKER_MAJOR_LATEST'),
    booleanParam(defaultValue: false, description: 'True if the version if the latest of the latest major version', name: 'DOCKER_LATEST'),
    booleanParam(defaultValue: true, description: 'Whether to push the image or not ', name: 'DOCKER_PUBLISH')
])])

podTemplate(label: label, containers: [
  containerTemplate(name: 'docker', image: 'container-nexus.azure.strapcloud.com/builders/docker', command: 'cat', ttyEnabled: true, workingDir: "/home/jenkins"),
],
volumes: [
  hostPathVolume(mountPath: '/var/run/docker.sock', hostPath: '/var/run/docker.sock')
]) {
  node(label) {

    withCredentials([usernamePassword(credentialsId: "${params.DOCKER_CREDENTIALS}", usernameVariable: 'REGISTRY_USER', passwordVariable: 'REGISTRY_PASSWORD')]) {

      stage('init') {
        def myRepo = checkout scm
        sh "cat Jenkinsfile"
        sh "env"
        container('docker') {
          sh "docker login -u ${REGISTRY_USER} -p ${REGISTRY_PASSWORD} ${params.DOCKER_REGISTRY}"
        }
      }

      stage('build') {
        container('docker') {
          sh "pwd"
          sh "ls"
          sh "bash ./build.sh"
        }
      }
    }
  }
}
