#
#  Be sure to run `pod spec lint Clip.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  spec.name           = "Clip"
  spec.version        = "0.0.1"
  spec.summary        = "The Clip iOS SDK."

  spec.homepage       = "http://www.clip.app"
  spec.license        = "Apache License, Version 2.0"

  spec.author         = {
    "Sean Rucker"     => "seanrucker@icloud.com",
    "Andrew Clunis"   => "andrew@orospakr.ca"
  }

  spec.platform       = :ios, "11.0"
  spec.source         = { :git => "https://github.com/Clip/clip-ios.git", :tag => "v#{spec.version}" }
  spec.source_files   = "Sources/**/*.swift"
  spec.swift_versions = ["5.0"]
end
