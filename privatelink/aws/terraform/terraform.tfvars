region = "us-east-1"
vpc_id = "vpc-0123456789abcdef0"
privatelink_service_name = "com.amazonaws.vpce.us-east-1.vpce-svc-0123456789abcdef0"
bootstrap = "lkc-abcde-vwxyz.us-east-1.aws.glb.confluent.cloud:9092"
subnets_to_privatelink = {
  "us-east-2a" = "subnet-0123456789abcdef0",
  "us-east-2b" = "subnet-0123456789abcdef1",
  "us-east-2c" = "subnet-0123456789abcdef2",
}
