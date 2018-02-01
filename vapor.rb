class Vapor < Formula
  homepage "https://vapor.codes"
 version "3.1.3"
  url "https://github.com/vapor/toolbox/releases/download/#{version}/macOS-sierra.tar.gz"
 sha256 "448f93e2b8574eb673b0494750329666bcf8a710e95ec61bea3c42714eca583c"

  depends_on "ctls" => :run

  def install
    bin.install "vapor"
  end
end
