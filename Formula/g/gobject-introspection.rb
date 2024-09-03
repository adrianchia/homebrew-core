class GobjectIntrospection < Formula
  include Language::Python::Shebang
  include Language::Python::Virtualenv

  desc "Generate introspection data for GObject libraries"
  homepage "https://gi.readthedocs.io/en/latest/"
  url "https://download.gnome.org/sources/gobject-introspection/1.80/gobject-introspection-1.80.1.tar.xz"
  sha256 "a1df7c424e15bda1ab639c00e9051b9adf5cea1a9e512f8a603b53cd199bc6d8"
  license all_of: ["GPL-2.0-or-later", "LGPL-2.0-or-later", "MIT"]
  revision 1

  bottle do
    sha256 arm64_sonoma:   "c1c697721fa887da0a7ecf1da74166307dda223b8cd922480d35ee7528455a79"
    sha256 arm64_ventura:  "0c84786d152faae9223090e6fdd185bf233c556a4ead8d14fc0854d276d7fa88"
    sha256 arm64_monterey: "af672a045ca17ed75abf4599981ca482df1dd2a28eb28962ac55ed129e906805"
    sha256 sonoma:         "46ed11128af5bdb834a7f216fa222854fd274cab9314105b2ff73359254df56d"
    sha256 ventura:        "03e5c450af9264cfe141056ccd91a5866eab01f3a15f22269092a0482a335eae"
    sha256 monterey:       "965341cb99b3ce445576e7e74ec23e974a3366b8e1b5a6ae708810e10e550e4f"
    sha256 x86_64_linux:   "57923660703711398295e51f51d1f4d976ce0220b2d116bba14c240ece504925"
  end

  depends_on "bison" => :build
  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "cairo"
  depends_on "glib"
  depends_on "pkg-config"
  # Ships a `_giscanner.cpython-312-darwin.so`, so needs a specific version.
  depends_on "python@3.12"

  uses_from_macos "flex" => :build
  uses_from_macos "libffi", since: :catalina

  resource "mako" do
    url "https://files.pythonhosted.org/packages/67/03/fb5ba97ff65ce64f6d35b582aacffc26b693a98053fa831ab43a437cbddb/Mako-1.3.5.tar.gz"
    sha256 "48dbc20568c1d276a2698b36d968fa76161bf127194907ea6fc594fa81f943bc"
  end

  resource "markdown" do
    url "https://files.pythonhosted.org/packages/54/28/3af612670f82f4c056911fbbbb42760255801b3068c48de792d354ff4472/markdown-3.7.tar.gz"
    sha256 "2ae2471477cfd02dbbf038d5d9bc226d40def84b4fe2986e49b59b6b472bbed2"
  end

  resource "markupsafe" do
    url "https://files.pythonhosted.org/packages/87/5b/aae44c6655f3801e81aa3eef09dbbf012431987ba564d7231722f68df02d/MarkupSafe-2.1.5.tar.gz"
    sha256 "d283d37a890ba4c1ae73ffadf8046435c76e7bc2247bbb63c00bd1a709c6544b"
  end

  resource "setuptools" do
    url "https://files.pythonhosted.org/packages/ac/11/0a953274017ca5c33a9831bc5e052e825d174a3551bd18924777794c8162/setuptools-74.1.0.tar.gz"
    sha256 "bea195a800f510ba3a2bc65645c88b7e016fe36709fefc58a880c4ae8a0138d7"
  end

  # Fix library search path on non-/usr/local installs (e.g. Apple Silicon)
  # See: https://github.com/Homebrew/homebrew-core/issues/75020
  #      https://gitlab.gnome.org/GNOME/gobject-introspection/-/merge_requests/273
  patch do
    url "https://gitlab.gnome.org/tschoonj/gobject-introspection/-/commit/a7be304478b25271166cd92d110f251a8742d16b.diff"
    sha256 "740c9fba499b1491689b0b1216f9e693e5cb35c9a8565df4314341122ce12f81"
  end

  # Backport removed distutils.msvccompiler
  patch do
    url "https://gitlab.gnome.org/GNOME/gobject-introspection/-/commit/a2139dba59eac283a7f543ed737f038deebddc19.diff"
    sha256 "62c1e9816effdb2f2d50bc577ea36b875cdd5e38f67ddb27eb0e0c380fa29700"
  end

  def install
    venv = virtualenv_create(libexec, "python3.12")
    venv.pip_install resources
    ENV.prepend_path "PATH", venv.root/"bin"

    ENV["GI_SCANNER_DISABLE_CACHE"] = "true"
    if OS.mac? && MacOS.version == :ventura && DevelopmentTools.clang_build_version == 1500
      ENV.append "LDFLAGS", "-Wl,-ld_classic"
    end

    inreplace "giscanner/transformer.py", "/usr/share", "#{HOMEBREW_PREFIX}/share"
    inreplace "meson.build",
      "config.set_quoted('GOBJECT_INTROSPECTION_LIBDIR', join_paths(get_option('prefix'), get_option('libdir')))",
      "config.set_quoted('GOBJECT_INTROSPECTION_LIBDIR', '#{HOMEBREW_PREFIX}/lib')"

    system "meson", "setup", "build", "-Dpython=#{venv.root}/bin/python",
                                      "-Dextra_library_paths=#{HOMEBREW_PREFIX}/lib",
                                      *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"

    rewrite_shebang python_shebang_rewrite_info(venv.root/"bin/python"), *bin.children
  end

  test do
    (testpath/"main.c").write <<~EOS
      #include <girepository.h>

      int main (int argc, char *argv[]) {
        GIRepository *repo = g_irepository_get_default();
        g_assert_nonnull(repo);
        return 0;
      }
    EOS

    pkg_config_flags = shell_output("pkg-config --cflags --libs gobject-introspection-1.0").strip.split
    system ENV.cc, "main.c", "-o", "test", *pkg_config_flags
    system "./test"
  end
end
