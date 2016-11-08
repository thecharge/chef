#
# Author:: Prabhu Das (<prabhu.das@clogeny.com>)
# Copyright:: Copyright 2013-2016, Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "spec_helper"
require "functional/resource/base"
require "chef/mixin/shell_out"

# run this test only for following platforms.
exclude_test = !(%w{rhel fedora}.include?(ohai[:platform_family]) && File.exist?("/usr/bin/dnf"))
describe Chef::Resource::RpmPackage, :requires_root, :external => exclude_test do
  include Chef::Mixin::ShellOut

  before(:all) do
    File.open("/etc/yum.repos.d/chef-dnf-localtesting.repo", "w+") do |f|
      f.write <<-EOF
[chef-dnf-localtesting]
name=Chef DNF spec testing repo
baseurl=file://#{CHEF_SPEC_ASSETS}/yumrepo
enable=1
gpgcheck=0
      EOF
    end
  end

  before(:each) do
    shell_out!("rpm -qa | grep chef-rpmspectest-foo | xargs -r rpm -e")
  end

  after(:all) do
    shell_out!("rpm -qa | grep chef-rpmspectest-foo | xargs -r rpm -e")
    FileUtils.rm "/etc/yum.repos.d/chef-dnf-localtesting.repo"
  end

  let(:dnf_package) do
    Chef::Resource::DnfPackage.new("chef-rpmspectest-foo", run_context)
  end

  describe ":install" do
    5.times do |i|
      it "works #{i}" do
        dnf_package.run_action(:install)
        expect(shell_out("rpm -q chef-rpmspectest-foo").stdout.chomp).to eql("chef-rpmspectest-foo-1.10.0-1.x86_64")
      end
    end
  end

  describe ":upgrade" do
  end
end
