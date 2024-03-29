pipeline {
    agent any

    environment {                
        SEC_GR = 'nodejs_for_lab'
        EC2_TAG = 'unique_tag_for_lab'
        AMI = 'ami-0cc0a36f626a4fdf5'
        DNS = "0"
    }

    stages {
        stage ('Clone') {
            steps {                
                git 'https://github.com/olegrybtsov/dp_hw1.git'
            }
        }
        
        stage ('Build'){
            steps{
                dir ('nodejs'){
                    sh 'sudo npm install'       
                }
            }
        }
        
        stage ('Test'){
            steps{                
                dir ('nodejs'){
                    sh 'sudo ./node_modules/.bin/mocha --exit ./tests/test.js'    
                }
            }
        }  
        
        stage ('EC2 Instance') {
            steps {
                script {
                    
                    EC2_ID = getInstId(EC2_TAG)
                    
                    if (EC2_ID == false) {
                        echo 'Run new EC2 instance'
                        checkSecGroup(SEC_GR)
                        sh "aws ec2 run-instances --image-id ${AMI} --count 1 --instance-type t2.micro --key-name ${KEY_PAIR} --security-groups ${SEC_GR} --tag-specifications \"ResourceType=instance,Tags=[{Key=unique_id,Value=${EC2_TAG}}]\""
                        EC2_ID = getInstId(EC2_TAG)
                    } else {
                        echo "Start ${EC2_ID}"
                        sh "aws ec2 start-instances --instance-ids ${EC2_ID}"
                    }
                    
                    STATE = getState(EC2_ID)
                    
                    while (STATE != 'running') {
                        echo STATE                        
                        STATE = getState(EC2_ID)
                        sleep 3
                    }
                    
                    DNS = sh (
                        script: "aws ec2 describe-instances --filters \"Name=tag:unique_id, Values=${EC2_TAG}\" --query \"Reservations[].Instances[].PublicDnsName\"",
                        returnStdout: true
                    ).trim().split("\"")[1]  
                    
                    sleep 20
                }
            }
        }
        
        stage ('Deploy') {
            steps{
                withCredentials([sshUserPrivateKey(credentialsId: USER_KEY, keyFileVariable: 'KEY', usernameVariable: 'USER')]) {
                    sh "ssh -oStrictHostKeyChecking=no -i $KEY $USER@$DNS rm nodejs -r -f"
                    sh "scp -r -i $KEY nodejs $USER@$DNS:~/"
                    sh "ssh -i $KEY $USER@$DNS < script.sh"
                }
            }
        }
        
        stage ('Notify') {
            steps{
                mail body: "http://$DNS:3000", subject: 'Jenkins Build URL', to: "$MAIL_TO"
            }
        }
    }    
}

//------------------------------------------------------------------------------------------------

def getInstId(tag) {
    EC2 = sh (
        script: "aws ec2 describe-instances --filters Name=tag:unique_id,Values=${tag} --query Reservations[].Instances[].InstanceId",
        returnStdout: true
    ).trim()
    
    if (EC2 == '[]') {
        return false
    } else {
        return EC2.split("\"")[1]
    }
}

def checkSecGroup(name){
    
    GROUP = sh (
        script: "aws ec2 describe-security-groups --filter Name=group-name,Values=${name} --query SecurityGroups[].GroupName",
        returnStdout: true
        ).trim()
        
    if (GROUP == '[]') {
        sh "aws ec2 create-security-group --group-name ${name} --description \"Node JS\""
        sh "aws ec2 authorize-security-group-ingress --group-name ${name} --ip-permissions \'[{\"IpProtocol\": \"tcp\", \"FromPort\": 3000, \"ToPort\": 3000, \"IpRanges\": [{\"CidrIp\": \"0.0.0.0/0\", \"Description\": \"3000 port for nodejs app\"}]}]\'"
        sh "aws ec2 authorize-security-group-ingress --group-name ${name} --ip-permissions \'[{\"IpProtocol\": \"tcp\", \"FromPort\": 22, \"ToPort\": 22, \"IpRanges\": [{\"CidrIp\": \"0.0.0.0/0\", \"Description\": \"3000 port for nodejs app\"}]}]\'"
    } else {
        echo 'Security group already exists'
    }
}

def getState(id){
    STATE = sh (
        script: "aws ec2 describe-instances --instance-ids $id --query Reservations[].Instances[].State[].Name",
        returnStdout: true
    ).trim()
        
    return STATE.split("\"")[1]
}
