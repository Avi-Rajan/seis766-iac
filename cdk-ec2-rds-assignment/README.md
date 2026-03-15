Requirements:

- A network stack contains:
- One public and one private subnets in one availability zone
- One public and one private subnets in another availability zone
- A server stack:
- Launch one web server in each public subnets
- A RDS instance with MySQL engine with all private subnets as its subnet
group.
- Web servers' security group opens port 80 from anywhere
- RDS instance's security group opens port 3306 to only web servers'
security group

Architecture

VPC
  AZ1
    Public Subnet → EC2 Web Server
    Private Subnet → RDS

  AZ2
    Public Subnet → EC2 Web Server
    Private Subnet → RDS

Security
  HTTP (80) open to internet
  MySQL (3306) only from web servers
