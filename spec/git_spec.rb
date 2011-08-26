require 'spec_helper'
require 'grit'

describe "Git adapter" do
  let(:repo_dir) { File.expand_path('../test-repo', __FILE__) }
  let(:adapter)  { Adapter[:git].new(client) }
  let(:client)   { Grit::Repo.init(repo_dir) }

  before do
    FileUtils.rm_rf(repo_dir)

    # Some adapter specs don't pass if there is not at least one commit in the
    # repo since the git adapter short-circuits the key marshalling if there
    # are no commits.
    adapter.set('specs', 'running')
  end

  it_should_behave_like 'an adapter'

  it 'should create a branch when it does not exist' do
    adapter.options[:branch] = 'foobar'
    adapter.set('foo', 'bar')
    client.get_head('foobar').should_not be_nil
  end
end