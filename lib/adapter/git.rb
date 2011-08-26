require 'adapter'
require 'yaml'
require 'grit'

module Adapter
  module Git
    def branch
      options[:branch] || 'master'
    end

    def head
      client.get_head(branch)
    end

    def key?(key)
      !(head && head.commit.tree / key_for(key)).nil?
    end

    def read(key)
      if head && blob = head.commit.tree / key_for(key)
        decode(blob.data)
      end
    end

    def write(key, value)
      commit("Updated #{key}") do |index|
        index.add(key_for(key), encode(value))
      end
    end

    def delete(key)
      read(key).tap do
        commit("Delete #{key}") {|index| index.delete(key_for(key)) }
      end
    end

    def clear
      commit("Cleared") do |index|
        index.current_tree.contents.each do |entry|
          index.delete(entry.name)
        end
      end
    end

    def encode(value)
      value.to_yaml
    end

    def decode(value)
      YAML.load(value)
    end

  private

    def commit(message)
      index = client.index

      if head
        commit = head.commit
        index.current_tree = commit.tree
      end

      yield index

      sha = index.commit(message, Array(commit))

      client.update_ref(branch, sha) unless head
    end

  end
end

Adapter.define(:git, Adapter::Git)