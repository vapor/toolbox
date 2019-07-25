class Vapor < Formula
  desc "Vapor Toolbox"
  homepage "https://vapor.codes"
  head "https://github.com/vapor/toolbox.git", :branch => "3"
  depends_on :xcode => "10"
  depends_on "libressl"
  depends_on "pkg-config"
  depends_on "openssl"

  def install
    system "swift", "build", "--disable-sandbox"
    system "mv", ".build/debug/Executable", "vapor"
    bin.install "vapor"
    lib.install "pkgconfig"
  end
end
