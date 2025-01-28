class Isort < Formula
  include Language::Python::Virtualenv

  desc "Sort Python imports automatically"
  homepage "https://pycqa.github.io/isort/"
  url "https://files.pythonhosted.org/packages/1c/28/b382d1656ac0ee4cef4bf579b13f9c6c813bff8a5cb5996669592c8c75fa/isort-6.0.0.tar.gz"
  sha256 "75d9d8a1438a9432a7d7b54f2d3b45cad9a4a0fdba43617d9873379704a8bdf1"
  license "MIT"
  head "https://github.com/PyCQA/isort.git", branch: "main"

  bottle do
    rebuild 3
    sha256 cellar: :any_skip_relocation, all: "40e77a6599b1898f4790a9d54cea3da7662a8012941c0156762e037f8e3ea390"
  end

  depends_on "python@3.13"

  def install
    virtualenv_install_with_resources
  end

  test do
    ENV["LC_ALL"] = "en_US.UTF-8"
    (testpath/"isort_test.py").write <<~PYTHON
      from third_party import lib
      import os
    PYTHON
    system bin/"isort", "isort_test.py"
    assert_equal "import os\n\nfrom third_party import lib\n", (testpath/"isort_test.py").read
  end
end
