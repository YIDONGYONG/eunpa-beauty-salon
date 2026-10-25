module Admin
  class SiteSettingsController < BaseController
    def edit
      @setting = SiteSetting.instance
    end

    def update
      @setting = SiteSetting.instance
      if @setting.update(setting_params)
        redirect_to edit_admin_site_setting_path, notice: "사이트 설정을 저장했습니다."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy_map_image
      SiteSetting.instance.map_image.purge_later
      redirect_to edit_admin_site_setting_path, notice: "지도 이미지를 삭제했습니다."
    end

    def destroy_address_photo
      SiteSetting.instance.address_photo.purge_later
      redirect_to edit_admin_site_setting_path, notice: "주소 사진을 삭제했습니다."
    end

    private

    def setting_params
      langs = Translatable::LOCALES
      text_keys = %i[tagline region_name address hours closed_days business_info]
      params.require(:site_setting).permit(:phone, :latitude, :longitude, :address_photo, :map_image, :kakao_url, :hero_phrase_choice, :schema_hours,
                                           *text_keys.product(langs).map { |k, l| :"#{k}_#{l}" })
    end
  end
end
