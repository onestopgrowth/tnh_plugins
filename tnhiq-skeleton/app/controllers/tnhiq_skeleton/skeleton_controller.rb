# frozen_string_literal: true

module ::TnhiqSkeleton
  class SkeletonController < ::ApplicationController
    requires_plugin "tnhiq-skeleton"

    skip_before_action :check_xhr, only: [:index]

    def index
      record = ::TnhiqSkeleton::Record.create!(message: "skeleton ping at #{Time.current.iso8601}")

      render json: {
        ok: true,
        plugin: "tnhiq-skeleton",
        version: "0.1.0",
        records_count: ::TnhiqSkeleton::Record.count,
        latest: { id: record.id, message: record.message, created_at: record.created_at },
      }
    end

    def admin_index
      records =
        ::TnhiqSkeleton::Record
          .order(created_at: :desc)
          .limit(20)
          .pluck(:id, :message, :created_at)

      render json: {
        ok: true,
        plugin: "tnhiq-skeleton",
        records: records.map { |id, msg, ts| { id: id, message: msg, created_at: ts } },
      }
    end
  end
end
