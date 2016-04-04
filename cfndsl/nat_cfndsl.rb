CloudFormation {
  Description 'Converge a NAT instance'

  nat_instance_type ||= 't2.micro'
  vpc_name ||= 'dev-vpc'
  vpc_cidr ||= '10.0.0.0/16'
  key_pair_name ||= 'dev-vpc-nat'

  vpc_id ||= 'vpc-3eeef95a'
  public_subnet_id ||= 'subnet-a2038388'
  private_route_table_id ||= 'rtb-130b8d74'

  Mapping('NatRegionMap', {
                          'us-east-1' => {'AMI' => 'ami-184dc970' },
                          'us-west-1' => { 'AMI' => 'ami-a98396ec'},
                          'us-west-2' => { 'AMI' => 'ami-290f4119'},
                          'eu-west-1' => { 'AMI' => 'ami-14913f63'},
                          'eu-central-1' => { 'AMI' => 'ami-ae380eb3'},
                          'sa-east-1' => { 'AMI' => 'ami-8122969c'},
                          'ap-southeast-1' => { 'AMI' => 'ami-6aa38238'},
                          'ap-southeast-2' => { 'AMI' => 'ami-893f53b3'},
                          'ap-northeast-1' => { 'AMI' => 'ami-27d6e626'}
                        })

  EC2_SecurityGroup('NatSecurityGroup') {
    GroupDescription "#{vpc_name} NAT Security Group"
    VpcId vpc_id

    Tags [
      {
        Key: 'Name',
        Value: "#{vpc_name}.nat.sg"
      }
    ]
  }

  %w(22 80 443).each do |ingress_port|
    EC2_SecurityGroupIngress("NatSecurityGroupIngress#{ingress_port}") {
      GroupId Ref('NatSecurityGroup')
      IpProtocol 'tcp'
      FromPort ingress_port.to_s
      ToPort ingress_port.to_s
      CidrIp vpc_cidr
    }
  end

  %w(22 80 443).each do |egress_port|
    EC2_SecurityGroupEgress("NatSecurityGroupEgress#{egress_port}") {
      GroupId Ref('NatSecurityGroup')
      IpProtocol 'tcp'
      FromPort egress_port.to_s
      ToPort egress_port.to_s
      CidrIp '0.0.0.0/0'
    }
  end

  nat_userdata = [
    "#!/bin/bash\n",
    'yum update -y && yum install -y yum-cron && chkconfig yum-cron on'
  ]

  EC2_Instance('NAT') {
    InstanceType nat_instance_type
    KeyName key_pair_name
    SourceDestCheck false
    ImageId FnFindInMap('NatRegionMap',
                        Ref('AWS::Region'),
                        'AMI')

    NetworkInterfaces [
      {
        'GroupSet' => [ Ref('NatSecurityGroup') ],
        'AssociatePublicIpAddress' => true,
        'DeviceIndex' => '0',
        'DeleteOnTermination' => true,
        'SubnetId' => public_subnet_id
      }
    ]

    Tags [
      {
        Key: 'Name',
        Value: "#{vpc_name}.nat.instance"
      }
    ]

    UserData FnBase64(FnJoin('', nat_userdata))
  }


  EC2_Route('privateRouteToNAT') {
    DependsOn %w(NAT)
    RouteTableId private_route_table_id
    DestinationCidrBlock '0.0.0.0/0'
    InstanceId Ref('NAT')
  }

  Output(:natIP,
         FnGetAtt('NAT', 'PublicIp'))
}