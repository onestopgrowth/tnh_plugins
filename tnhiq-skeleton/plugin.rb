# frozen_string_literal: true

# name: tnhiq-skeleton
# about: Skeleton plugin proving the TNHIQ Discourse dev environment works
# version: 0.1.0
# authors: TNHIQ
# url: https://github.com/onestopgrowth/tnh-community-backend

enabled_site_setting :tnhiq_skeleton_enabled

after_initialize do
  require_relative "app/models/tnhiq_skeleton/record"
  require_relative "app/controllers/tnhiq_skeleton/skeleton_controller"

  Discourse::Application.routes.append do
    get "/skeleton-test" => "tnhiq_skeleton/skeleton#index"

    scope "/admin/plugins/tnhiq-skeleton", constraints: AdminConstraint.new do
      get "" => "tnhiq_skeleton/skeleton#admin_index"
    end
  end
end
