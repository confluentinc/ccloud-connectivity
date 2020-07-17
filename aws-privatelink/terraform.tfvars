region = "us-east-1"
vpc_id = "vpc-0123456789abcdef0"
privatelink_service_name = "com.amazonaws.vpce.us-east-1.vpce-svc-0123456789abcdef0"
bootstrap = "lkc-abcde-vwxyz.us-east-1.aws.glb.confluent.cloud:9092"
subnets_to_privatelink = {
  "use1-az1" = "subnet-0123456789abcdef0",
  "use1-az2" = "subnet-0123456789abcdef1",
  "use1-az3" = "subnet-0123456789abcdef2",
}
