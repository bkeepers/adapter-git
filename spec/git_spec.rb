require 'spec_helper'
require 'grit'

describe "Git adapter" do
  let(:repo_dir) { File.expand_path('../test-repo', __FILE__) }
  let(:adapter)  { Adapter[:git].new(client, :branch => 'adapter-git') }
  let(:client)   { Grit::Repo.init(repo_dir) }

  before do
    FileUtils.rm_rf(repo_dir)

    # Some adapter specs don't pass if there is not at least one commit in the
    # repo since the git adapter short-circuits the key marshalling if there
    # are no commits.
    adapter.write('specs', 'running')
  end

  it_should_behave_like 'an adapter'

  it 'should create a branch when it does not exist' do
    adapter.options[:branch] = 'foobar'
    adapter.write('foo', 'bar')
    client.get_head('foobar').should_not be_nil
  end

  it 'overrides configured branch with :branch option' do
    adapter.options[:branch] = 'foobar'
    adapter.write('foo', 'bar', :branch => 'bazqux')
    client.get_head('bazqux').should_not be_nil
  end

  it 'should not raise error on clear when branch does not exist' do
    client.git.fs_delete("refs/heads/#{adapter.branch}")
    lambda { adapter.clear }.should_not raise_error
  end

  it 'should successfully delete a key' do
    adapter.write('foo', 'bar')
    adapter.delete('foo')
    adapter.read('foo').should be_nil
  end

  it 'should not generate a commit message if there are no changes' do
    adapter.clear
    head = adapter.head.commit
    adapter.clear
    adapter.head.commit.id.should == head.id
  end

  context 'with the path option' do
    before do
      adapter.options[:path] = 'db/things'
    end

    it_should_behave_like 'an adapter'

    it 'should store keys in the directory' do
      adapter.write('foo', 'bar')
      (adapter.head.commit.tree / 'foo').should be_nil
      (adapter.head.commit.tree / 'db/things/foo').should_not be_nil
    end

    it 'should not clear other keys' do
      other_adapter = Adapter[:git].new(client, :branch => 'adapter-git')
      other_adapter.write('foo', 'bar')

      adapter.write('foo', 'baz')
      adapter.clear

      other_adapter.read('foo').should == 'bar'
      adapter.read('foo').should be_nil
    end

    it 'should not raise error on clear when branch does not exist' do
      client.git.fs_delete("refs/heads/#{adapter.branch}")
      lambda { adapter.clear }.should_not raise_error
    end

    it 'uses a default commit message if none specified' do
      adapter.write('foo', 'bar')
      adapter.head.commit.message.should == 'Updated foo'
    end

    it 'accepts a :message option for commit message' do
      adapter.write('foo', 'bar', :message => 'Reticulating splines')
      adapter.head.commit.message.should == 'Reticulating splines'
    end

    it 'accepts a commit :author option' do
      author = Grit::Actor.new('Foo Bar', 'baz@qux.qx')
      adapter.write('foo', 'bar', :author => author)
      adapter.head.commit.author.name.should == author.name
      adapter.head.commit.author.email.should == author.email
    end

    it 'accepts a option for :committed_date' do
      commit_time = Time.now - 600
      adapter.write('foo', 'bar', :committed_date => commit_time)
      adapter.head.commit.committed_date.to_i.should == commit_time.to_i
    end

  end
end
