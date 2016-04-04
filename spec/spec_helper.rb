require 'awspec'
require 'aws-sdk'

def vpc_id_by_name(vpc_name)
  client = Aws::EC2::Client.new
  describe_vpcs_response = client.describe_vpcs filters: [
                                                  {
                                                    name: 'tag:Name',
                                                    values: [vpc_name],
                                                  }
                                                ]

  if describe_vpcs_response.vpcs.length != 1
    raise "unique vpc not found: #{vpc_name} has #{describe_vpcs_response.vpcs.length} hits"
  else
    describe_vpcs_response.vpcs.first.vpc_id
  end
end

def subnet_id_by_name(subnet_name)
  client = Aws::EC2::Client.new
  describe_subnets_response = client.describe_subnets filters: [
                                                  {
                                                    name: 'tag:Name',
                                                    values: [subnet_name],
                                                  }
                                                ]

  if describe_subnets_response.subnets.length != 1
    raise "unique subnet not found: #{subnet_name} has #{describe_subnets_response.subnets.length} hits"
  else
    describe_subnets_response.subnets.first.subnet_id
  end
end

def igw_id_by_name(igw_name)
  client = Aws::EC2::Client.new
  describe_internet_gateways_response = client.describe_internet_gateways filters: [
                                                        {
                                                          name: 'tag:Name',
                                                          values: [igw_name],
                                                        }
                                                      ]

  if describe_internet_gateways_response.internet_gateways.length != 1
    raise "unique igw not found: #{igw_name} has #{describe_internet_gateways_response.internet_gateways.length} hits"
  else
    describe_internet_gateways_response.internet_gateways.first.internet_gateway_id
  end
end

def route_table_id_by_name(route_table_name)
  client = Aws::EC2::Client.new
  describe_route_tables_response = client.describe_route_tables filters: [
                                                                            {
                                                                              name: 'tag:Name',
                                                                              values: [route_table_name],
                                                                            }
                                                                          ]

  if describe_route_tables_response.route_tables.length != 1
    raise "unique route table not found: #{route_table_name} has #{describe_route_tables_response.route_tables.length} hits"
  else
    describe_route_tables_response.route_tables.first.route_table_id
  end
end


module Awspec::Type
  class Vpc < Base
    def has_dns_hostnames_enabled?
      client = Aws::EC2::Client.new
      resource = Aws::EC2::Resource.new(client: client)

      vpc = resource.vpc(@resource_via_client.vpc_id)

      describe_attributes_result = vpc.describe_attribute attribute: 'enableDnsHostnames'
      describe_attributes_result.enable_dns_hostnames
    end
  end
end