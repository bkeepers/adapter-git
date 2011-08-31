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
        tree = index.current_tree
        tree = tree / options[:path] if options[:path] && tree
        if tree
          tree.contents.each do |entry|
            index.delete(key_for(entry.name))
          end
        end
      end
    end

    def encode(value)
      value.to_yaml
    end

    def decode(value)
      YAML.load(value)
    end

    def key_for(key)
      File.join(*[options[:path], super].compact)
    end

  private

    def commit(message)
      index = client.index

      if head
        commit = head.commit
        index.current_tree = commit.tree
      end

      yield index

      index.commit(message, :parents => Array(commit), :head => branch) unless index.tree.empty?
    end

  end
end

Adapter.define(:git, Adapter::Git)