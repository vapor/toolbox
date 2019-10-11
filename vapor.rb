class Vapor < Formula
  desc "Vapor Toolbox"
  homepage "https://vapor.codes"
  head "https://github.com/vapor/toolbox.git"
  depends_on :xcode => "11"
  depends_on "openssl"

  stable do
    version "18.0.0-beta.16"
    url "https://github.com/vapor/toolbox/archive/18.0.0-beta.16.tar.gz"
    sha256 "dba6177eb366e3b15fa39568c2ebbcd55f4a42269ec16da1d916820840a1bffb"
  end

  def install
    system "swift", "build", "--disable-sandbox"
    system "mv", ".build/debug/Executable", "vapor"
    bin.install "vapor"
  end
end
