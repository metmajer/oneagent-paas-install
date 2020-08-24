require 'serverspec'

# Required by serverspec
set :backend, :exec

ENV['HOME'] = '/tmp/kitchen/data'
require ENV['HOME'] + '/test/dynatrace/defaults.rb'
require ENV['HOME'] + '/test/dynatrace/oneagent.rb'
require ENV['HOME'] + '/test/dynatrace/util.rb'

# Test installer with insufficient arguments
opts = {
  DT_CLUSTER_HOST:        Dynatrace::Defaults::DT_CLUSTER_HOST,
  DT_API_TOKEN:           Dynatrace::Defaults::DT_API_TOKEN,
  DT_ONEAGENT_FOR:        'nodejs',
  DT_ONEAGENT_BITNESS:    '64',
  DT_ONEAGENT_PREFIX_DIR: '/tmp',
  DT_ONEAGENT_APP:        '/does-not-exist.js'
}

describe command(Dynatrace::Util::parse_cmd('~/dynatrace-oneagent-paas.sh', opts)) do
  its(:stderr) { should contain "failed to install Dynatrace OneAgent: could not find /does-not-exist.js" }
  its(:exit_status) { should eq 1 }
end

# Test installer: NodeJS, 64-bit, into /tmp)
opts = {
  DT_CLUSTER_HOST:        Dynatrace::Defaults::DT_CLUSTER_HOST,
  DT_API_TOKEN:           Dynatrace::Defaults::DT_API_TOKEN,
  DT_ONEAGENT_FOR:        'nodejs',
  DT_ONEAGENT_BITNESS:    '64',
  DT_ONEAGENT_PREFIX_DIR: '/tmp',
  DT_ONEAGENT_APP:        '/app/index.js'
}

describe command(Dynatrace::Util::parse_cmd('~/dynatrace-oneagent-paas.sh', opts)) do
  its(:exit_status) { should eq 0 }
end

describe file("/app/index.js") do
  its(:content) { should match Regexp.new(Regexp.escape("try { require('/tmp/dynatrace/oneagent/agent/bin/any/onenodeloader.js') ({ server: '#{Dynatrace::Defaults::DT_CLUSTER_HOST}', apitoken: '#{Dynatrace::Defaults::DT_API_TOKEN}' }); } catch(err) { console.log(err.toString()); }")) }
end

describe file("/app/index.js.bak") do
  its(:content) { should_not match Regexp.new(Regexp.escape("try { require('/tmp/dynatrace/oneagent/agent/bin/any/onenodeloader.js') ({ server: '#{Dynatrace::Defaults::DT_CLUSTER_HOST}', apitoken: '#{Dynatrace::Defaults::DT_API_TOKEN}' }); } catch(err) { console.log(err.toString()); }")) }
end

describe command(Dynatrace::Util::cmd('node /app/index.js', 'killall node')) do
  its(:stderr) { should match /.*Agent version.*1\..*/ }
  its(:stderr) { should contain "connected to #{Dynatrace::Defaults::DT_CLUSTER_HOST}" }
end