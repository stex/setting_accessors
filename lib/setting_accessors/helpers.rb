# frozen_string_literal: true

module SettingAccessors
  module Helpers
    class Error < StandardError; end
    class NestedHashKeyNotFoundException < Error; end

    def ensure_nested_hash!(hash, *keys)
      h = hash
      keys.each do |key|
        h[key] ||= {}
        h = h[key]
      end
    end

    def lookup_nested_hash(hash, *keys)
      fail NestedHashKeyNotFoundException if hash.nil?

      h = hash
      keys.each do |key|
        fail NestedHashKeyNotFoundException unless h.key?(key)
        h = h[key]
      end
      h
    end
  end
end