# ELB Example

The example launches a web server, installs nginx, creates an ELB for instance. It also creates security groups for the ELB and EC2 instance. 

This example assumes you have created a Key Pair. Visit
https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#KeyPairs:sort=keyName
to create a key if you do not have one. 

Run this example using:

    terraform apply
   Note: Remember to change the key_name in .tfvars file

Else If you don't want to hardcode your key_name in a file, run:

    terraform apply -var 'key_name=YOUR_KEY_NAME'

Wait a couple of minutes for the EC2 userdata to install nginx, and then type the ELB DNS Name from outputs in your browser and see the nginx welcome page
