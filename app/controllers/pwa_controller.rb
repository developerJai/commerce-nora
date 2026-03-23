class PwaController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:manifest, :service_worker]

  def manifest
    render template: "pwa/manifest", formats: [:json], layout: false
  end

  def service_worker
    render template: "pwa/service-worker", formats: [:js], layout: false, content_type: "text/javascript"
  end
end
