#!/bin/bash

# Configure descriptors for logging
# printf "$(date): example 1" >&3 (To Console)
# printf "$(date): example 2" (To Log)
# exec 3>&1 4>&2
# trap 'exec 2>&4 1>&3' 0 1 2 3
# exec 1>health_check.log 2>&1

# Functions
# Fail health check and update auto scaling group
fail_health () {
    printf "$(date): health check failed\n"
    aws --region eu-west-2 autoscaling set-instance-health --instance-id $INSTANCE_ID --health-status Unhealthy
    exit 1
}

# Succeed health check and update autoscaling group
succeed_health () {
    printf "$(date): health check successful\n"
    aws --region eu-west-2 autoscaling set-instance-health --instance-id $INSTANCE_ID --health-status Healthy
    exit 0
}

# Main
# Check if the required packages are installed
REQUIRED_PACKAGES=("aws" "ec2-metadata" "jq")
for PKG in "${REQUIRED_PACKAGES[@]}"; do 
    if ! which $PKG > /dev/null; then
        printf "$(date): $PKG not found\n"
        printf "$(date): $PKG must be avaliable for the health check to work\n"
        exit 1
    fi
done

# Set the instance id
INSTANCE_ID=$(ec2-metadata -i | cut -d " " -f 2)

# Check if instance is in auto scaling group
IS_IN_ASG=$(aws --region eu-west-2 autoscaling describe-auto-scaling-instances --instance-ids $INSTANCE_ID | jq ".AutoScalingInstances")
if [[ $IS_IN_ASG == "[]" ]]; then
    printf "$(date): Instance: $INSTANCE_ID is not in an auto scaling group\n"
    printf "$(date): Exiting\n"
    exit 1
fi

# Check if cloud-init has configure the properties file
PROPERTIES_FILE="/opt/sonarqube/sonarqube/conf/sonar.properties"
if grep -Fq "#sonar.jdbc.url=jdbc:postgresql" $PROPERTIES_FILE 2>&1; then
    printf "$(date): database has not been configured\n"
    fail_health
fi

PROPERTIES_FILE="/opt/sonarqube/sonarqube/conf/sonar.properties"
if ! systemctl is-active --quiet sonar; then
    printf "$(date): service sonar is not active\n"
    fail_health
fi    

# Check that the web service is show Sonarqube
if curl -s "127.0.0.1:9000" | grep -Fq "window.serverStatus = 'UP'" 2>&1; then
    printf "$(date): sonarqube web front end found\n"
    succeed_health
fi
