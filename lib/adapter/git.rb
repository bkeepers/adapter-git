require 'adapter'
require 'yaml'
require 'grit'

module Adapter
  module Git
    def branch
      options[:branch] || 'master'
    end

    def head(head_branch = nil)
      client.get_head(head_branch || branch)
    end

    def key?(key, options = nil)
      key_head = head(options ? options[:branch] : nil)
      !(key_head && key_head.commit.tree / key_for(key)).nil?
    end

    def read(key, options = nil)
      read_head = head(options ? options[:branch] : nil)
      if read_head && blob = read_head.commit.tree / key_for(key)
        decode(blob.data)
      end
    end

    def write(key, value, options = nil)
      commit("Updated #{key}", options) do |index|
        index.add(key_for(key), encode(value))
      end
    end

    def delete(key, options = nil)
      read(key).tap do
        commit("Delete #{key}", options) {|index| index.delete(key_for(key)) }
      end
    end

    def clear(options = nil)
      commit("Cleared", options) do |index|
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

    def commit(message, options)
      options ||= {}

      index = client.index

      commit_branch = options[:branch] || branch
      if commit_head = head(commit_branch)
        commit = commit_head.commit
        index.current_tree = commit.tree
      end

      yield index

      message = options[:message] || message
      commit_options = make_commit_options(commit, commit_branch, options)
      index.commit(message, commit_options) unless index.tree.empty?
    end

    def make_commit_options(commit, head, options)
      commit_options = { :parents => Array(commit), :head => head }
      [:actor, :committer, :author, :committed_date, :authored_date].each do |k|
        commit_options[k] = options[k] if options.has_key?(k)
      end
      commit_options
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