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

    def key?(key, options = nil)
      !(head && head.commit.tree / key_for(key)).nil?
    end

    def read(key, options = nil)
      if head && blob = head.commit.tree / key_for(key)
        decode(blob.data)
      end
    end

    def write(key, value, options = nil)
      commit("Updated #{key}") do |index|
        index.add(key_for(key), encode(value))
      end
    end

    def delete(key, options = nil)
      read(key).tap do
        commit("Delete #{key}") {|index| index.delete(key_for(key)) }
      end
    end

    def clear(options = nil)
      commit("Cleared") do |index|
        tree = index.current_tree
        tree = tree / self.options[:path] if self.options[:path] && tree
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
      File.join(*[options[:path], serialize_key(key)].compact)
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

    def serialize_key(key)
      if key.is_a?(String)
        key
      elsif key.is_a?(Symbol)
        key.to_s
      else
        Marshal.dump(key)
      end
    end

  end
end

Adapter.define(:git, Adapter::Git)