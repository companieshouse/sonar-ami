#!/bin/bash

# Health Check for Sonarqube

# Configure descriptors for logging
exec 1> >(logger -s -t $(basename $0)) 2>&1

# Set extra error handling
set -e

# Functions
# Fail health check and update auto scaling group
fail_health () {
    echo "health check failed"
    aws --region $REGION autoscaling set-instance-health --instance-id $INSTANCE_ID --health-status Unhealthy
    exit 1
}

# Succeed health check and update autoscaling group
succeed_health () {
    echo "health check successful"
    aws --region $REGION autoscaling set-instance-health --instance-id $INSTANCE_ID --health-status Healthy
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

# Required variables
REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r ".region")
INSTANCE_ID=$(ec2-metadata -i | cut -d " " -f 2)

# Ensure that we get the instance and region set
if [ -z "$INSTANCE_ID" ] || [ -z "$REGION" ]; then
    echo "Failed to get instance id and/or region"
    echo "Exiting"
    exit 1
fi

# Check if instance is in auto scaling group
IS_IN_ASG=$(aws --region $REGION autoscaling describe-auto-scaling-instances --instance-ids $INSTANCE_ID | jq ".AutoScalingInstances")
if [[ "$IS_IN_ASG" == "[]" ]] || [ -z "$IS_IN_ASG" ]; then
    echo "Failed to find instance ($INSTANCE_ID) in auto scaling group"
    echo "Exiting"
    exit 1
fi

# Ensure the instance has been up for at least 360 seconds
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

# Check that the sonar service is active
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