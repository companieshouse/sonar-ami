#!/bin/bash

# Health Check for Sonarqube

# Configure descriptors for logging
exec 1> >(logger -s -t $(basename $0)) 2>&1

# Functions
# Fail health check and update auto scaling group
fail_health () {
    echo "health check failed"
    aws --region eu-west-2 autoscaling set-instance-health --instance-id $INSTANCE_ID --health-status Unhealthy
    exit 1
}

# Succeed health check and update autoscaling group
succeed_health () {
    echo "health check successful"
    aws --region eu-west-2 autoscaling set-instance-health --instance-id $INSTANCE_ID --health-status Healthy
    exit 0
}

# Main
# Check if the required packages are installed
REQUIRED_PACKAGES=("aws" "ec2-metadata" "jq")
for PKG in "${REQUIRED_PACKAGES[@]}"; do 
    if ! which $PKG > /dev/null; then
        echo "$PKG not found"
        echo "$PKG must be avaliable for the health check to work"
        exit 1
    fi
done

# Set the instance id
INSTANCE_ID=$(ec2-metadata -i | cut -d " " -f 2)

# Check if instance is in auto scaling group
IS_IN_ASG=$(aws --region eu-west-2 autoscaling describe-auto-scaling-instances --instance-ids $INSTANCE_ID | jq ".AutoScalingInstances")
if [[ $IS_IN_ASG == "[]" ]]; then
    echo "Instance: $INSTANCE_ID is not in an auto scaling group"
    echo "Exiting"
    exit 1
fi

if (( $(cat /proc/uptime | cut -d '.' -f 1) < 360 )); then
    echo "waiting for instance to be up for longer than 360 seconds"
    exit 0
fi

# Check if cloud-init has configure the properties file
PROPERTIES_FILE="/opt/sonarqube/sonarqube/conf/sonar.properties"
if grep -Fq "#sonar.jdbc.url=jdbc:postgresql" $PROPERTIES_FILE 2>&1; then
    echo "database has not been configured"
    fail_health
fi

if ! systemctl is-active --quiet sonar; then
    echo "service sonar is not active"
    fail_health
fi    

# Check that the web service is show Sonarqube
if curl -s "127.0.0.1:9000" | grep -Fq "window.serverStatus = 'UP'" 2>&1; then
    echo "sonarqube web front end found"
    succeed_health
else
    echo "Failed to check the sonarqube frontend"
    fail_health
fi
