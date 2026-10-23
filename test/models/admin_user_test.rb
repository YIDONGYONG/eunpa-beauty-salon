require "test_helper"

class AdminUserTest < ActiveSupport::TestCase
  test "stores a password digest, never the plain password" do
    user = AdminUser.create!(email: "Owner@Example.com ", password: "long-enough-pw")
    assert_equal "owner@example.com", user.email
    assert_not_equal "long-enough-pw", user.password_digest
    assert user.authenticate("long-enough-pw")
    assert_not user.authenticate("wrong")
  end

  test "rejects short passwords" do
    assert_not AdminUser.new(email: "a@b.co", password: "short").valid?
  end
end
