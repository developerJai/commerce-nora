class DeepLinksController < ApplicationController
  skip_before_action :verify_authenticity_token

  # Apple App Site Association — iOS Universal Links
  # Served at /.well-known/apple-app-site-association
  def apple
    render json: {
      applinks: {
        apps: [],
        details: [
          {
            appID: "#{StoreSetting.instance.ios_team_id}.#{StoreSetting.instance.ios_bundle_id}",
            paths: [
              "/products/*",
              "/categories/*",
              "/orders/*",
              "/cart",
              "/search",
              "/support/*",
              "/"
            ]
          }
        ]
      }
    }
  end

  # Android Asset Links — Android App Links
  # Served at /.well-known/assetlinks.json
  def android
    render json: [
      {
        relation: [ "delegate_permission/common.handle_all_urls" ],
        target: {
          namespace: "android_app",
          package_name: StoreSetting.instance.android_package_name,
          sha256_cert_fingerprints: [
            StoreSetting.instance.android_sha256_fingerprint
          ].compact
        }
      }
    ]
  end
end
