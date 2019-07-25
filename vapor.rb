class Vapor < Formula
  desc "Vapor Toolbox"
  homepage "https://vapor.codes"
  # head "https://github.com/vapor/toolbox.git", :branch => "3"
  url "https://github.com/vapor/toolbox/archive/3.1.11-test.tar.gz"
  sha256 "4da68421b8bbcdfba95945b1b75c35a06683c20a10c601fc8981ef182d741557"
  version "3.1.11"
  depends_on :xcode => "10"
  depends_on "libressl"
  depends_on "pkg-config"

  def install
    system "swift", "build", "--disable-sandbox"
    system "mv", ".build/debug/Executable", "vapor"
    bin.install "vapor"
    lib.install "pkgconfig"
  end
end
