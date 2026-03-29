module Admin
  class AppVersionsController < BaseController
    before_action :require_admin_role!
    before_action :set_app_version, only: [ :edit, :update, :destroy, :toggle_status ]

    def index
      @ios_versions = AppVersion.ios.by_version
      @android_versions = AppVersion.android.by_version
    end

    def new
      @app_version = AppVersion.new(platform: params[:platform] || "ios", released_at: Time.current)
    end

    def create
      @app_version = AppVersion.new(app_version_params)

      if @app_version.save
        redirect_to admin_app_versions_path, notice: "App version #{@app_version.version_number} (#{@app_version.platform.upcase}) created successfully"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @app_version.update(app_version_params)
        redirect_to admin_app_versions_path, notice: "App version updated successfully"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @app_version.destroy
      redirect_to admin_app_versions_path, notice: "App version deleted"
    end

    def toggle_status
      @app_version.update!(active: !@app_version.active?)
      redirect_to admin_app_versions_path, notice: "#{@app_version.version_number} #{@app_version.active? ? 'activated' : 'deactivated'}"
    end

    private

    def set_app_version
      @app_version = AppVersion.find(params[:id])
    end

    def app_version_params
      params.require(:app_version).permit(
        :platform, :version_number, :force_update, :active,
        :release_notes, :store_url, :released_at
      )
    end
  end
end
