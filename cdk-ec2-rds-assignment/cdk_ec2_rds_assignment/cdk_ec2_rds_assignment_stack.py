from aws_cdk import (
    Stack,
    aws_ec2 as ec2,
    aws_rds as rds
)
from constructs import Construct


class CdkEc2RdsAssignmentStack(Stack):

    def __init__(self, scope: Construct, construct_id: str, **kwargs):
        super().__init__(scope, construct_id, **kwargs)

        vpc = ec2.Vpc(
            self,
            "AssignmentVpc",
            max_azs=2,
            subnet_configuration=[
                ec2.SubnetConfiguration(
                    name="PublicSubnet",
                    subnet_type=ec2.SubnetType.PUBLIC
                ),
                ec2.SubnetConfiguration(
                    name="PrivateSubnet",
                    subnet_type=ec2.SubnetType.PRIVATE_WITH_EGRESS
                )
            ]
        )

        web_sg = ec2.SecurityGroup(self, "WebSG", vpc=vpc)

        web_sg.add_ingress_rule(
            ec2.Peer.any_ipv4(),
            ec2.Port.tcp(80)
        )

        db_sg = ec2.SecurityGroup(self, "DbSG", vpc=vpc)

        db_sg.add_ingress_rule(
            web_sg,
            ec2.Port.tcp(3306)
        )

        ec2.Instance(
            self,
            "WebServer",
            vpc=vpc,
            instance_type=ec2.InstanceType("t2.micro"),
            machine_image=ec2.AmazonLinuxImage(),
            security_group=web_sg,
            vpc_subnets=ec2.SubnetSelection(
                subnet_type=ec2.SubnetType.PUBLIC
            )
        )

        rds.DatabaseInstance(
            self,
            "MyDatabase",
            engine=rds.DatabaseInstanceEngine.mysql(
                version=rds.MysqlEngineVersion.VER_8_0
            ),
            vpc=vpc,
            instance_type=ec2.InstanceType("t3.micro"),
            allocated_storage=20,
            security_groups=[db_sg],
            vpc_subnets=ec2.SubnetSelection(
                subnet_type=ec2.SubnetType.PRIVATE_WITH_EGRESS
            )
        )