import aws_cdk as core
import aws_cdk.assertions as assertions

from cdk_ec2_rds_assignment.cdk_ec2_rds_assignment_stack import CdkEc2RdsAssignmentStack

# example tests. To run these tests, uncomment this file along with the example
# resource in cdk_ec2_rds_assignment/cdk_ec2_rds_assignment_stack.py
def test_sqs_queue_created():
    app = core.App()
    stack = CdkEc2RdsAssignmentStack(app, "cdk-ec2-rds-assignment")
    template = assertions.Template.from_stack(stack)

#     template.has_resource_properties("AWS::SQS::Queue", {
#         "VisibilityTimeout": 300
#     })
