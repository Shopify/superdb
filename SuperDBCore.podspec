Pod::Spec.new do |s|
  s.name         = "SuperDBCore"
  s.version      = "0.1"
  s.summary      = "Embeddable Core of the SuperDebugger."
  s.homepage     = "https://github.com/proger/superdb"

  s.license      = ""
  s.author       = {}

  s.source       = { :git => s.homepage + ".git", :branch => "pods" }

  s.platform     = :ios, '6.0'

  # A list of file patterns which select the source files that should be
  # added to the Pods project. If the pattern is a directory then the
  # path will automatically have '*.{h,m,mm,c,cpp}' appended.
  #
  # Alternatively, you can use the FileList class for even more control
  # over the selected files.
  # (See http://rake.rubyforge.org/classes/Rake/FileList.html.)
  #
  s.source_files = FileList[
                            'SuperDBCore/SuperDBCore/*'
                            ]

  s.requires_arc = false
end
