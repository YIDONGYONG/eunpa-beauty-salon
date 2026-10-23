ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)

    setup { I18n.locale = I18n.default_locale }

    def create_category(name = "커트", **attrs)
      MenuCategory.create!(name_ko: name, **attrs)
    end

    def create_item(category, name = "여성 커트", price = 15_000, **attrs)
      category.menu_items.create!(name_ko: name, price: price, **attrs)
    end
  end
end

class ActionDispatch::IntegrationTest
  ADMIN_PASSWORD = "test-password-123".freeze

  def create_admin
    AdminUser.create!(email: "owner@example.com", password: ADMIN_PASSWORD)
  end

  def sign_in_admin
    create_admin
    post admin_session_path, params: { email: "owner@example.com", password: ADMIN_PASSWORD }
  end
end
