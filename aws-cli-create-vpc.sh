
## CREATE THE VPC ##
$ VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query 'Vpc.VpcId' --output text)

# ensure DNS support is on
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames

# create tag for VPC
aws ec2 create-tags --resource $VPC_ID --tags Key=Name,Value=CLI_DEMO_VPC

## CREATE SUBNETS ## 
PUBLIC_SUBNET1_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 --availability-zone us-west-2a --query 'Subnet.SubnetId' --output text)
PUBLIC_SUBNET2_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.3.0/24 --availability-zone us-west-2b --query 'Subnet.SubnetId' --output text)
PRIVATE_SUBNET1_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.2.0/24 --availability-zone us-west-2a --query 'Subnet.SubnetId' --output text)
PRIVATE_SUBNET2_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.4.0/24 --availability-zone us-west-2b --query 'Subnet.SubnetId' --output text)

#create tags for subnet
aws ec2 create-tags --resource $PUBLIC_SUBNET1_ID --tags Key=Name,Value=PUBLIC_SUBNET1_ID
aws ec2 create-tags --resource $PUBLIC_SUBNET2_ID --tags Key=Name,Value=PUBLIC_SUBNET2_ID
aws ec2 create-tags --resource $PRIVATE_SUBNET1_ID --tags Key=Name,Value=PRIVATE_SUBNET1_ID
aws ec2 create-tags --resource $PRIVATE_SUBNET2_ID --tags Key=Name,Value=PRIVATE_SUBNET2_ID

## CREATE THE ROUTE TABLES ##
PUBLIC_ROUTE_TABLE_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text)
PRIVATE_ROUTE_TABLE_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text)

# create tags for route tables
aws ec2 create-tags --resource $PUBLIC_ROUTE_TABLE_ID --tags Key=Name,Value=PUBLIC_ROUTE_TABLE
aws ec2 create-tags --resource $PRIVATE_ROUTE_TABLE_ID --tags Key=Name,Value=PRIVATE_ROUTE_TABLE

## ASSOCIATE SUBNETS TO ROUTE TABLES ##
aws ec2 associate-route-table --route-table-id $PUBLIC_ROUTE_TABLE_ID --subnet-id $PUBLIC_SUBNET1_ID
aws ec2 associate-route-table --route-table-id $PUBLIC_ROUTE_TABLE_ID --subnet-id $PUBLIC_SUBNET2_ID
aws ec2 associate-route-table --route-table-id $PRIVATE_ROUTE_TABLE_ID --subnet-id $PRIVATE_SUBNET1_ID
aws ec2 associate-route-table --route-table-id $PRIVATE_ROUTE_TABLE_ID --subnet-id $PRIVATE_SUBNET2_ID

## CREATE THE IGW ##
GATEWAY_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)

## ATTACH INTERNET GATEWAY ##
aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $GATEWAY_ID

## ADD A ROUTE FOR THE INTERNET FR PUBLIC SUBNETS##
aws ec2 create-route --route-table-id $PUBLIC_ROUTE_TABLE_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $GATEWAY_ID

## ALLOCATE AN EIP FOR NAT GATEWAY ##
ALLOCATION_ID=$(aws ec2 allocate-address --domain vpc --output text --query 'AllocationId')
echo "Allocation ID: $ALLOCATION_ID"

## CREATE NAT GATEWAY ##
NAT_GATEWAY_ID=$(aws ec2 create-nat-gateway \
  --subnet-id $PUBLIC_SUBNET1_ID \
  --allocation-id $ALLOCATION_ID \
  --query 'NatGateway.NatGatewayId' \
  --output text)

## ADD A ROUTE FOR THE INTERNET VIA NAT GW FOR PRIVATE SUBNETS##
aws ec2 create-route --route-table-id $PRIVATE_ROUTE_TABLE_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $NAT_GATEWAY_ID



