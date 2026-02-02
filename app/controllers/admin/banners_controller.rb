module Admin
  class BannersController < BaseController
    include Pagy::Backend
    
    before_action :set_banner, only: [:show, :edit, :update, :destroy, :toggle_status]

    def index
      @pagy, @banners = pagy(Banner.ordered, items: 20)
    end

    def show
    end

    def new
      @banner = Banner.new
    end

    def create
      @banner = Banner.new(banner_params)

      if @banner.save
        redirect_to admin_banners_path, notice: "Banner created successfully"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @banner.update(banner_params)
        redirect_to admin_banners_path, notice: "Banner updated successfully"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @banner.destroy
      redirect_to admin_banners_path, notice: "Banner deleted successfully"
    end

    def toggle_status
      @banner.update(active: !@banner.active?)
      
      respond_to do |format|
        format.html { redirect_to admin_banners_path, notice: "Banner #{@banner.active? ? 'enabled' : 'disabled'}" }
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@banner) }
      end
    end

    private

    def set_banner
      @banner = Banner.find(params[:id])
    end

    def banner_params
      params.require(:banner).permit(:title, :subtitle, :image_url, :link_url, :position, :active, :starts_at, :ends_at, :image)
    end
  end
end
