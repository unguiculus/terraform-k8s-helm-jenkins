pipelineJob('demo-pipeline') {
    definition {
        cps {
            script '''
                pipeline {
                    agent {
                        kubernetes {
                            yaml """
                                apiVersion: v1
                                kind: Pod
                                spec:
                                  containers:
                                    - name: jnlp
                                      tty: true
                            """
                        }
                    }
                    stages {
                        stage('test') {
                            steps {
                                echo 'test'
                            }
                        }
                    }
                }
            '''.stripIndent()
            sandbox()
        }
    }
}
