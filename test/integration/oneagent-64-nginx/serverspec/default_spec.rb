require 'serverspec'

# Required by serverspec
set :backend, :exec

ENV['HOME'] = '/tmp/kitchen/data'
require ENV['HOME'] + '/test/dynatrace/defaults.rb'
require ENV['HOME'] + '/test/dynatrace/oneagent.rb'
require ENV['HOME'] + '/test/dynatrace/util.rb'

# Test installer: NGINX, 64-bit, into /tmp)
opts = {
  DT_API_TOKEN:           Dynatrace::Defaults::DT_API_TOKEN,
  DT_API_URL:             Dynatrace::Defaults::DT_API_URL,
  DT_ONEAGENT_FOR:        'nginx',
  DT_ONEAGENT_BITNESS:    '64',
  DT_ONEAGENT_PREFIX_DIR: '/tmp'
}

describe command(Dynatrace::Util::parse_cmd('~/dynatrace-oneagent-paas.sh', opts)) do
  its(:exit_status) { should eq 0 }
end

describe command(Dynatrace::OneAgent::get_monitored_process_cmd('nginx')) do
  its(:exit_status) { should eq 0 }
end

# Cannot use file() resource here, since only command() accepts a wildcard pattern
describe command('cat ' + Dynatrace::OneAgent::NGINX::get_monitored_process_log) do
  its(:stdout) { should contain "Starting Nginx agent" }
  its(:stdout) { should contain "Nginx successfully instrumented" }
end