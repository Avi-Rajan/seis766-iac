# Terraform AWS Infrastructure

## Architecture

This Terraform project creates the following AWS infrastructure:

One public and one private subnets in one availability zone
- One public and one private subnets in another availability zone
- Launch one EC2 instance in each public subnets
- A RDS instance with MySQL engine with all private subnets as its subnet
group.
- Web servers' security group opens port 80 from anywhere
- RDS instance's security group opens port 3306 to only web servers' security
group
- The name of the EC2 instances are from input variables "instance1_name"
and "instance2_name"
- The outputs should have the public IP addresses of EC2 instances and the
endpoint of the RDS databaseD
