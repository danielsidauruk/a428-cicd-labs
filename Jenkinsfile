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

        stage('Manual Approval') {
            // Add manual input for approval before deploying
            input message: 'Proceed to the Deploy stage?', ok: 'Proceed'
        }

        stage('Deploy') {
            sh './jenkins/scripts/deliver.sh' 

            // Pause execution for 1 minute so the app can be tested
            echo 'Waiting 1 minute before shutting down the application...'
            sleep 60

            // Shut down the application after the pause
            sh './jenkins/scripts/kill.sh' 
        }
    }
}
