# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

title 'Forseti Terraform GCP Test Suite for Shared VPC setup'

project_id              = attribute("project_id")
network_project         = attribute("network_project")
forseti_server_vm_name  = attribute("forseti-server-vm-name")
forseti_server_vm_ip    = attribute("forseti-server-vm-ip")
forseti_client_vm_name  = attribute("forseti-client-vm-name")
region                  = attribute("region")
network                 = attribute("network")

control 'forseti-service-project' do
  impact 1.0
  title 'test forseti project'
  describe google_compute_project_info(project: project_id) do
    its('xpn_project_status') { should eq 'UNSPECIFIED_XPN_PROJECT_STATUS' }
    its('name') { should eq project_id }
  end
end

control 'forseti-shared-project' do
  impact 1.0
  title 'test shared project'
  describe google_compute_project_info(project: network_project) do
    its('xpn_project_status') { should eq 'HOST' }
    its('name') { should eq network_project }
  end
end

control 'forseti-server' do
  impact 1.0
  title 'test forseti server'
  describe google_compute_instance(project: project_id,  zone: "#{region}-c", name: forseti_server_vm_name) do
    it { should exist }
    its('has_disks_encrypted_with_csek?') { should be false }
    its('status') { should eq 'RUNNING' }
    its('disk_count'){should eq 1}
  end
end

control 'forseti-client' do
  impact 1.0
  title 'test forset client'
  describe google_compute_instance(project: project_id,  zone: "#{region}-c", name: forseti_client_vm_name) do
    it { should exist }
    its('has_disks_encrypted_with_csek?') { should be false }
    its('status') { should eq 'RUNNING' }
    its('disk_count'){should eq 1}
  end
end

control 'forseti-shared-firewall' do
  google_compute_firewalls(project: network_project).where(firewall_name: /forseti-/).firewall_names.each do |firewall_name|
    describe google_compute_firewall(project: network_project, name: firewall_name) do
      its('direction') { should eq "INGRESS" }
      its('network') { should eq "https://www.googleapis.com/compute/v1/projects/#{network_project}/global/networks/#{network}" }
    end
  end
end
