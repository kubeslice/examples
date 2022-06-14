# Kubeslice - ec2 instance enviroment
A terraform project to setup an AWS ec2 instance with kind and kubeslice.

## Prerequisites  

There only two dependencies that need to be met to successfully run the create_ec2_instance script:

1. A working installation of terrafor (this script was tested against terraform v1.2.1)
2. You need to install and configure aws cli tool
3. Make sure the current aws region in use has a default vpc

## How to use

To create a new kubeslice environment on ec2, simply run the script "create_ec2_instance.sh". If everything goes well, the script will print out the instructions for connecting to the newly created ec2 instance.

## Cleanup

To destroy the ec2 instance, run the script "destroy_ec2_instance.sh"