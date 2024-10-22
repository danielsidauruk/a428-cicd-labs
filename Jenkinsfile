node {
    // Use Docker with a specific image and port mapping
    docker.image('node:16-buster-slim').inside('-p 3000:3000') {
        
        stage('Build') {
            // Run npm install to build the application
            sh 'npm install'
        }
        
        stage('Test') {
            // Execute the test script
            sh './jenkins/scripts/test.sh'
        }

        stage('Deploy') {
            sh './jenkins/scripts/deliver.sh' 
            input message: 'Sudah selesai menggunakan React App? (Klik "Proceed" untuk mengakhiri)' 
            sh './jenkins/scripts/kill.sh' 
        }
    }
}
