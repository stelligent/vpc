CloudFormation {
  Description 'Setup a basic VPC to work in'

  vpc_name ||= 'defaultvpc'
  vpc_cidr ||= '10.0.0.0/16'

  EC2_VPC('vpc') {
    CidrBlock vpc_cidr
    EnableDnsHostnames true

    Tags [
     {
       Key: 'Name',
       Value: vpc_name
     }
    ]
  }

  EC2_Subnet('publicSubnet1') {
    VpcId Ref('vpc')
    CidrBlock '10.0.0.0/24'
    AvailabilityZone FnSelect(0, FnGetAZs(Ref('AWS::Region')))

    Tags [
      {
        Key: 'Name',
        Value: FnJoin('', [ vpc_name, '.internet-facing.1.', Ref('AWS::Region')])
      }
    ]
  }

  EC2_Subnet('publicSubnet2') {
    VpcId Ref('vpc')
    CidrBlock '10.0.10.0/24'
    AvailabilityZone FnSelect(1, FnGetAZs(Ref('AWS::Region')))

    Tags [
      {
        Key: 'Name',
        Value: FnJoin('', [ vpc_name, '.internet-facing.2.', Ref('AWS::Region')])
      }
    ]
  }


  EC2_Subnet('privateSubnet1') {
    VpcId Ref('vpc')
    CidrBlock '10.0.20.0/24'
    AvailabilityZone FnSelect(0, FnGetAZs(Ref('AWS::Region')))

    Tags [
      {
        Key: 'Name',
        Value: FnJoin('', [ vpc_name, '.internal.1.', Ref('AWS::Region')])
      }
    ]
  }

  EC2_Subnet('privateSubnet2') {
    VpcId Ref('vpc')
    CidrBlock '10.0.30.0/24'
    AvailabilityZone FnSelect(1, FnGetAZs(Ref('AWS::Region')))

    Tags [
      {
        Key: 'Name',
        Value: FnJoin('', [ vpc_name, '.internal.2.', Ref('AWS::Region')])
      }
    ]
  }

  EC2_InternetGateway('igw') {
    Tags [
      {
        Key: 'Name',
        Value: FnJoin('', [ vpc_name, '.igw'])
      }
    ]
  }

  EC2_VPCGatewayAttachment('attachGateway') {
    VpcId Ref('vpc')
    InternetGatewayId Ref('igw')
  }

  EC2_RouteTable('publicRouteTable') {
    VpcId Ref('vpc')

    Tags [
      {
        Key: 'Name',
        Value: FnJoin('', [ vpc_name, '.internet-facing'])
      },
      {
        Key: 'immutable',
        Value: 'true'
      }
    ]
  }

  EC2_RouteTable('privateRouteTable') {
    VpcId Ref('vpc')

    Tags [
      {
        Key: 'Name',
        Value: FnJoin('', [ vpc_name, '.internal'])
      }
    ]
  }

  EC2_Route('publicRoute') {
    DependsOn 'attachGateway'
    RouteTableId Ref('publicRouteTable')
    DestinationCidrBlock '0.0.0.0/0'
    GatewayId Ref('igw')
  }

  %w(publicSubnet1 publicSubnet2).each do |publicSubnet|
    EC2_SubnetRouteTableAssociation("#{publicSubnet}RouteTableAssociation") {
      SubnetId Ref(publicSubnet)
      RouteTableId Ref('publicRouteTable')
    }
  end

  %w(privateSubnet1 privateSubnet2).each do |privateSubnet|
    EC2_SubnetRouteTableAssociation("#{privateSubnet}RouteTableAssociation") {
      SubnetId Ref(privateSubnet)
      RouteTableId Ref('privateRouteTable')
    }
  end


  Output(:vpcId,
         Ref('vpc'))

  Output(:publicSubnetId1,
         Ref('publicSubnet1'))

  Output(:privateRouteTableId,
         Ref('privateRouteTable'))
}

