Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # ---- 管理画面（/admin）: 韓国語UI固定 ----
  namespace :admin do
    root "dashboard#show"
    get "login", to: "sessions#new", as: :login
    resource :session, only: %i[create destroy]
    resource :password, only: %i[edit update]
    resource :site_setting, only: %i[edit update] do
      delete "hero_photo", action: :destroy_hero_photo, as: :hero_photo
    end
    resource :owner_profile, only: %i[edit update] do
      delete "photo", action: :destroy_photo, as: :photo
      delete "gallery_images/:attachment_id", action: :destroy_image, as: :gallery_image
    end

    resources :menu_categories, only: %i[create update destroy] do
      member do
        patch :toggle
        patch :move_up
        patch :move_down
      end
    end
    resources :menu_items, path: "menu", only: %i[index create update destroy] do
      member do
        patch :toggle
        patch :move_up
        patch :move_down
      end
    end
    resources :posts, except: :show do
      member { patch :toggle }
    end
  end

  # ---- SEO ----
  get "sitemap.xml", to: "sitemaps#show", defaults: { format: :xml }
  get "robots.txt", to: "robots#show", defaults: { format: :text }

  # ---- 公開サイト（/ko /en /vi /ja）----
  scope "/:locale", locale: /ko|en|vi|ja/ do
    root "home#show"
    get "about", to: "about#show", as: :about
    resources :posts, path: "blog", only: %i[index show]
    get "location", to: "location#show", as: :location
    get "privacy", to: "privacy#show", as: :privacy
  end

  # 「/」は Cookie／ブラウザの言語に合わせて /ko などへ移動
  root "locale_redirects#show", as: :locale_redirect
end
