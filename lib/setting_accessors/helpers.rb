# frozen_string_literal: true

module SettingAccessors
  module Helpers
    def ensure_nested_hash!(hash, *keys)
      h = hash
      keys.each do |key|
        h[key] ||= {}
        h = h[key]
      end
    end

    def lookup_nested_hash(hash, *keys)
      fail NestedHashKeyNotFoundError if hash.nil?

      h = hash
      keys.each do |key|
        fail NestedHashKeyNotFoundError unless h.key?(key)

        h = h[key]
      end
      h
    end
  end
end
