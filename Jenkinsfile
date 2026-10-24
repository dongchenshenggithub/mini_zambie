pipeline {
    agent any

    stages {
        stage('拉取代码') {
            steps {
                checkout scm
            }
        }

        stage('清理缓存') {
            steps {
                sh 'rm -rf .godot'
            }
        }

        stage('导出 Linux 版本') {
            steps {
                sh '''
                    mkdir -p build/linux
                    godot --headless --path . --export-release "Linux" build/linux/ZombieRoguelike.x86_64
                '''
            }
        }
    }

    post {
        success {
            archiveArtifacts artifacts: 'build/linux/*', fingerprint: true
        }
    }
}