require 'spec_helper'
require 'grit'

describe "Git adapter" do
  let(:adapter) { Adapter[:git].new(client) }
  let(:client)  { Grit::Repo.init(File.expand_path('../test-repo', __FILE__)) }

  before do
    adapter.clear
  end

  it_should_behave_like 'an adapter'
end