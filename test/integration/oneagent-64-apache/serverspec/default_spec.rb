require 'serverspec'

# Required by serverspec
set :backend, :exec

ENV['HOME'] = '/tmp/kitchen/data'
require ENV['HOME'] + '/test/dynatrace/defaults.rb'
require ENV['HOME'] + '/test/dynatrace/oneagent.rb'
require ENV['HOME'] + '/test/dynatrace/util.rb'

# Test installer: Apache, 64-bit, into /tmp)
opts = {
  DT_API_TOKEN:           Dynatrace::Defaults::DT_API_TOKEN,
  DT_API_URL:             Dynatrace::Defaults::DT_API_URL,
  DT_ONEAGENT_FOR:        'apache',
  DT_ONEAGENT_BITNESS:    '64',
  DT_ONEAGENT_PREFIX_DIR: '/tmp'
}

describe command(Dynatrace::Util::parse_cmd('~/dynatrace-oneagent-paas.sh', opts)) do
  its(:exit_status) { should eq 0 }
end

# Need to kill httpd first since, otherwise, ports will be blocked when starting it again with Dynatrace OneAgent
describe command('killall httpd; ' + Dynatrace::Util::cmd(Dynatrace::OneAgent::get_monitored_process_cmd('/usr/local/apache2/bin/httpd -DFOREGROUND'), 'killall httpd')) do
  its(:exit_status) { should eq 143 }
end

# Cannot use file() resource here, since only command() accepts a wildcard pattern
describe command('cat ' + Dynatrace::OneAgent::Apache::get_monitored_process_log) do
  its(:stdout) { should match /Loading agent/ }
  its(:stdout) { should match /Agent name.*Apache/ }
  its(:stdout) { should match /Instrumenting module hooks finished successfully./ }
end