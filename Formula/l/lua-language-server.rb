class LuaLanguageServer < Formula
  desc "Language Server for the Lua language"
  homepage "https://github.com/LuaLS/lua-language-server"
  # pull from git tag to get submodules
  url "https://github.com/LuaLS/lua-language-server.git",
      tag:      "3.14.0",
      revision: "485835e2a89004e1ffc5feb4484dc798a12af69e"
  license "MIT"
  head "https://github.com/LuaLS/lua-language-server.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "b7c68a5ee138aaca045a530fd84ace07c002a7d5e3784d9d030daff453f56712"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:  "e7bc745beda26db94b3d6c820b5121a75e22182e1deb21e13418ac8c5c1f8165"
    sha256 cellar: :any_skip_relocation, arm64_ventura: "728b16fc2c6413e2b3a0c49d2b10fee23b022f3a7f123ce4f61bd8fa56b7c571"
    sha256 cellar: :any_skip_relocation, sonoma:        "3c3d8b351eca8e767dd518a4ca3c6585e80d4ef63baf6c1fd4e966c101cd931a"
    sha256 cellar: :any_skip_relocation, ventura:       "25544aca7b2fdb9bab29344389f8a84a543f9cf852b4c59821c5fa4c81923448"
    sha256 cellar: :any_skip_relocation, arm64_linux:   "e1664445423588699b7519f6c7d525431efa6e529be98c8c4c39fd42a3e00091"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "0310a6fb0cd180060b4016680a2d8f60a7584bfbcab46e3fb24531175735f150"
  end

  depends_on "ninja" => :build

  def install
    ENV.cxx11

    # disable all tests by build script (fail in build environment)
    inreplace buildpath.glob("**/3rd/bee.lua/test/test.lua"),
      "os.exit(lt.run(), true)",
      "os.exit(true, true)"

    chdir "3rd/luamake" do
      system "compile/install.sh"
    end
    system "3rd/luamake/luamake", "rebuild"

    (libexec/"bin").install "bin/lua-language-server", "bin/main.lua"
    libexec.install "main.lua", "debugger.lua", "locale", "meta", "script"

    # Make sure `lua-language-server` does not need to write into the Cellar.
    (bin/"lua-language-server").write <<~BASH
      #!/bin/bash
      exec -a lua-language-server #{libexec}/bin/lua-language-server \
        --logpath="${XDG_CACHE_HOME:-${HOME}/.cache}/lua-language-server/log" \
        --metapath="${XDG_CACHE_HOME:-${HOME}/.cache}/lua-language-server/meta" \
        "$@"
    BASH
  end

  test do
    pid = spawn bin/"lua-language-server", "--logpath=."
    sleep 5
    assert_path_exists testpath/"service.log"
    refute_predicate testpath/"service.log", :empty?
  ensure
    Process.kill "TERM", pid
  end
end
