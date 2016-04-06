require 'awspec'
require 'aws-sdk'
require 'id_util'

def region
  'us-west-2'
end


include IdUtil

def instance_id_by_name(instance_name)
  client = Aws::EC2::Client.new
  describe_instances_response = client.describe_instances filters: [
                                                                  {
                                                                    name: 'tag:Name',
                                                                    values: [instance_name],
                                                                  }
                                                                ]

  if describe_instances_response.reservations.length != 1
    raise "unique reservation for instance id not found: #{instance_name} has #{describe_instances_response.reservations.length} hits"
  else
    if describe_instances_response.reservations.first.instances.length != 1
      raise "unique instance for instance id not found: #{instance_name} has #{describe_instances_response.reservations.first.instances.length} hits"
    else
      describe_instances_response.reservations.first.instances.first.instance_id
    end
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