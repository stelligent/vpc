require 'spec_helper'

vpc_id_under_test = vpc_id_by_name('dev-vpc')

describe vpc('dev-vpc') do
  it { should exist }
  its(:cidr_block) {
    should eq '10.0.0.0/16'
  }
  it { should have_dns_hostnames_enabled }
end

public_subnet1_under_test = subnet("dev-vpc.internet-facing.1.#{region}")
describe public_subnet1_under_test do
  it { should exist }

  its(:cidr_block) {
    should eq '10.0.0.0/24'
  }

  its(:vpc_id) {
    should eq vpc_id_under_test
  }
end

public_subnet1_az = public_subnet1_under_test.availability_zone

public_subnet2_under_test = subnet("dev-vpc.internet-facing.2.#{region}")
describe public_subnet2_under_test do
  it { should exist }

  its(:cidr_block) {
    should eq '10.0.10.0/24'
  }

  its(:vpc_id) {
    should eq vpc_id_under_test
  }
end

public_subnet2_az = public_subnet2_under_test.availability_zone

describe 'public subnet az distribution' do
  it 'should be split' do
    expect(public_subnet1_az).to_not eq public_subnet2_az
  end
end

###

private_subnet1_under_test = subnet("dev-vpc.internal.1.#{region}")
describe private_subnet1_under_test do
  it { should exist }
  its(:cidr_block) {
    should eq '10.0.20.0/24'
  }

  its(:vpc_id) {
    should eq vpc_id_under_test
  }
end

private_subnet1_az = private_subnet1_under_test.resource.id

private_subnet2_under_test = subnet("dev-vpc.internal.2.#{region}")
describe private_subnet2_under_test do
  it { should exist }

  its(:cidr_block) {
    should eq '10.0.30.0/24'
  }

  its(:vpc_id) {
    should eq vpc_id_under_test
  }
end

private_subnet2_az = private_subnet2_under_test.availability_zone

describe 'private subnet az distribution' do
  it 'should be split' do
    expect(private_subnet1_az).to_not eq private_subnet2_az
  end
end

describe 'igw' do
  it 'should exist' do
    expect {
      igw_id_by_name('dev-vpc.igw')
    }.to_not raise_error
  end
end

describe route_table('dev-vpc.internet-facing') do
  it { should exist }

  it { should have_route('0.0.0.0/0').target(gateway: 'dev-vpc.igw') }

  it { should have_subnet("dev-vpc.internet-facing.1.#{region}") }
  it { should have_subnet("dev-vpc.internet-facing.2.#{region}") }

end

describe route_table(route_table_id_by_name('dev-vpc.internal')) do
  it { should exist }

  it { should have_subnet("dev-vpc.internal.1.#{region}") }
  it { should have_subnet("dev-vpc.internal.2.#{region}") }

end