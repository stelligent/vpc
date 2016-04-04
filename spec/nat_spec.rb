require 'spec_helper'

vpc_id_under_test = vpc_id_by_name('dev-vpc')
vpc_under_test = vpc(vpc_id_under_test)

describe security_group('dev-vpc.nat.sg') do
  it { should exist }

  its(:inbound) { should be_opened(443).protocol('tcp').for(vpc_under_test.cidr_block) }
  its(:inbound) { should be_opened(80).protocol('tcp').for(vpc_under_test.cidr_block) }
  its(:inbound) { should be_opened(22).protocol('tcp').for(vpc_under_test.cidr_block) }
  its(:inbound_rule_count) { should eq 3 }

  its(:outbound) { should be_opened(443).protocol('tcp').for('0.0.0.0/0') }
  its(:outbound) { should be_opened(80).protocol('tcp').for('0.0.0.0/0') }
  its(:outbound) { should be_opened(22).protocol('tcp').for('0.0.0.0/0') }
  its(:outbound_rule_count) { should eq 3 }
end

describe ec2(instance_id_by_name('dev-vpc.nat.instance')) do
  it { should exist }

  it { should have_security_group('dev-vpc.nat.sg') }

  it { should belong_to_vpc('dev-vpc') }

  its(:source_dest_check) { should eq false }

  its(:iam_instance_profile) { should eq nil }

  its(:public_ip_address) { should_not eq nil }

#   its(:user_data) {
#     should eq <<END
# #!/bin/bash
# yum update -y && yum install -y yum-cron && chkconfig yum-cron on
# END
#   }

  #for us-east-1.... this is a bit awkward perhaps?
  its(:image_id) { should eq 'ami-184dc970' }
end

describe route_table('dev-vpc.internal') do
  it { should have_route('0.0.0.0/0').target(instance: instance_id_by_name('dev-vpc.nat.instance')) }
end