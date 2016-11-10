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

  let(:package_name) { "chef-rpmspectest-foo" }
  let(:dnf_package) { Chef::Resource::DnfPackage.new(package_name, run_context) }

  5.times do |i|
    describe ":install" do
      context "vanilla use case" do
        let(:package_name) { "chef-rpmspectest-foo" }
        it "installs if the package is not installed #{i}" do
          dnf_package.run_action(:flush_cache)
          dnf_package.run_action(:install)
          expect(dnf_package.updated_by_last_action?).to be true
          expect(shell_out("rpm -q chef-rpmspectest-foo").stdout.chomp).to eql("chef-rpmspectest-foo-1.10.0-1.x86_64")
        end

        it "does not install if the package is installed #{i}" do
          shell_out!("rpm -ivh #{CHEF_SPEC_ASSETS}/yumrepo/chef-rpmspectest-foo-1.10.0-1.x86_64.rpm")
          dnf_package.run_action(:flush_cache)
          dnf_package.run_action(:install)
          expect(dnf_package.updated_by_last_action?).to be false
          expect(shell_out("rpm -q chef-rpmspectest-foo").stdout.chomp).to eql("chef-rpmspectest-foo-1.10.0-1.x86_64")
        end

        it "does not install if the prior verison package is installed #{i}" do
          shell_out!("rpm -ivh #{CHEF_SPEC_ASSETS}/yumrepo/chef-rpmspectest-foo-1.2.0-1.x86_64.rpm")
          dnf_package.run_action(:flush_cache)
          dnf_package.run_action(:install)
          expect(dnf_package.updated_by_last_action?).to be false
          expect(shell_out("rpm -q chef-rpmspectest-foo").stdout.chomp).to eql("chef-rpmspectest-foo-1.2.0-1.x86_64")
        end

        it "does not install if the i686 package is installed #{i}" do
          pending "FIXME: do nothing, or install the x86_64 version?"
          shell_out!("rpm -ivh #{CHEF_SPEC_ASSETS}/yumrepo/chef-rpmspectest-foo-1.10.0-1.i686.rpm")
          dnf_package.run_action(:flush_cache)
          dnf_package.run_action(:install)
          expect(dnf_package.updated_by_last_action?).to be false
          expect(shell_out("rpm -q chef-rpmspectest-foo").stdout.chomp).to eql("chef-rpmspectest-foo-1.10.0-1.i686")
        end

        it "does not install if the prior version i686 package is installed #{i}" do
          pending "FIXME: do nothing, or install the x86_64 version?"
          shell_out!("rpm -ivh #{CHEF_SPEC_ASSETS}/yumrepo/chef-rpmspectest-foo-1.2.0-1.i686.rpm")
          dnf_package.run_action(:flush_cache)
          dnf_package.run_action(:install)
          expect(dnf_package.updated_by_last_action?).to be false
          expect(shell_out("rpm -q chef-rpmspectest-foo").stdout.chomp).to eql("chef-rpmspectest-foo-1.2.0-1.i686")
        end
      end
    end

    describe ":upgrade" do
    end

    describe ":remove" do
      context "vanilla use case" do
        let(:package_name) { "chef-rpmspectest-foo" }
        it "does nothing if the package is not installed #{i}" do
          dnf_package.run_action(:flush_cache)
          dnf_package.run_action(:remove)
          expect(dnf_package.updated_by_last_action?).to be false
          expect(shell_out("rpm -q chef-rpmspectest-foo").stdout.chomp).to eql("package chef-rpmspectest-foo is not installed")
        end

        it "removes the package if the package is installed #{i}" do
          shell_out!("rpm -ivh #{CHEF_SPEC_ASSETS}/yumrepo/chef-rpmspectest-foo-1.10.0-1.x86_64.rpm")
          dnf_package.run_action(:flush_cache)
          dnf_package.run_action(:remove)
          expect(dnf_package.updated_by_last_action?).to be true
          expect(shell_out("rpm -q chef-rpmspectest-foo").stdout.chomp).to eql("package chef-rpmspectest-foo is not installed")
        end

        it "removes the package if the prior verison package is installed #{i}" do
          shell_out!("rpm -ivh #{CHEF_SPEC_ASSETS}/yumrepo/chef-rpmspectest-foo-1.2.0-1.x86_64.rpm")
          dnf_package.run_action(:flush_cache)
          dnf_package.run_action(:remove)
          expect(dnf_package.updated_by_last_action?).to be true
          expect(shell_out("rpm -q chef-rpmspectest-foo").stdout.chomp).to eql("package chef-rpmspectest-foo is not installed")
        end

        it "removes the package if the i686 package is installed #{i}" do
          pending "FIXME: should this be fixed or is the current behavior correct?"
          shell_out!("rpm -ivh #{CHEF_SPEC_ASSETS}/yumrepo/chef-rpmspectest-foo-1.10.0-1.i686.rpm")
          dnf_package.run_action(:flush_cache)
          dnf_package.run_action(:remove)
          expect(dnf_package.updated_by_last_action?).to be true
          expect(shell_out("rpm -q chef-rpmspectest-foo").stdout.chomp).to eql("package chef-rpmspectest-foo is not installed")
        end

        it "removes the package if the prior version i686 package is installed #{i}" do
          pending "FIXME: should this be fixed or is the current behavior correct?"
          shell_out!("rpm -ivh #{CHEF_SPEC_ASSETS}/yumrepo/chef-rpmspectest-foo-1.2.0-1.i686.rpm")
          dnf_package.run_action(:flush_cache)
          dnf_package.run_action(:remove)
          expect(dnf_package.updated_by_last_action?).to be true
          expect(shell_out("rpm -q chef-rpmspectest-foo").stdout.chomp).to eql("package chef-rpmspectest-foo is not installed")
        end
      end

      context "with 64-bit arch" do
        let(:package_name) { "chef-rpmspectest-foo.x86_64" }
        it "does nothing if the package is not installed #{i}" do
          dnf_package.run_action(:flush_cache)
          dnf_package.run_action(:remove)
          expect(dnf_package.updated_by_last_action?).to be false
          expect(shell_out("rpm -q chef-rpmspectest-foo").stdout.chomp).to eql("package chef-rpmspectest-foo is not installed")
        end

        it "removes the package if the package is installed #{i}" do
          shell_out!("rpm -ivh #{CHEF_SPEC_ASSETS}/yumrepo/chef-rpmspectest-foo-1.10.0-1.x86_64.rpm")
          dnf_package.run_action(:flush_cache)
          dnf_package.run_action(:remove)
          expect(dnf_package.updated_by_last_action?).to be true
          expect(shell_out("rpm -q chef-rpmspectest-foo").stdout.chomp).to eql("package chef-rpmspectest-foo is not installed")
        end

        it "removes the package if the prior verison package is installed #{i}" do
          shell_out!("rpm -ivh #{CHEF_SPEC_ASSETS}/yumrepo/chef-rpmspectest-foo-1.2.0-1.x86_64.rpm")
          dnf_package.run_action(:flush_cache)
          dnf_package.run_action(:remove)
          expect(dnf_package.updated_by_last_action?).to be true
          expect(shell_out("rpm -q chef-rpmspectest-foo").stdout.chomp).to eql("package chef-rpmspectest-foo is not installed")
        end

        it "does nothing if the i686 package is installed #{i}" do
          shell_out!("rpm -ivh #{CHEF_SPEC_ASSETS}/yumrepo/chef-rpmspectest-foo-1.10.0-1.i686.rpm")
          dnf_package.run_action(:flush_cache)
          dnf_package.run_action(:remove)
          expect(dnf_package.updated_by_last_action?).to be false
          expect(shell_out("rpm -q chef-rpmspectest-foo").stdout.chomp).to eql("chef-rpmspectest-foo-1.10.0-1.i686")
        end

        it "does nothing if the prior version i686 package is installed #{i}" do
          shell_out!("rpm -ivh #{CHEF_SPEC_ASSETS}/yumrepo/chef-rpmspectest-foo-1.2.0-1.i686.rpm")
          dnf_package.run_action(:flush_cache)
          dnf_package.run_action(:remove)
          expect(dnf_package.updated_by_last_action?).to be false
          expect(shell_out("rpm -q chef-rpmspectest-foo").stdout.chomp).to eql("chef-rpmspectest-foo-1.2.0-1.i686")
        end
      end
    end
  end
end
