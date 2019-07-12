#!/bin/bash -ex

main() {
    create_jenkins_cache_dirs
    install_ssm_agent
}

create_jenkins_cache_dirs() {
    # Go module cache
    mkdir -p /var/jenkins/go/pkg/mod

    # Gradle cache
    mkdir -p /var/jenkins/gradle

    # Workspaces
    mkdir -p /var/jenkins/workspace

    chown -R 1000:1000 /var/jenkins
}

install_ssm_agent() {
    yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm

    systemctl status amazon-ssm-agent
}

main
