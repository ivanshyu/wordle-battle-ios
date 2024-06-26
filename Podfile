platform :ios, '13.0'
use_modular_headers!

use_frameworks!

target 'alphacarbon-wordle' do
    pod 'Socket.IO-Client-Swift', '~> 16.0.1'
    pod 'SwiftyJSON', '~> 4.0'
    pod 'Alamofire'
    # Add the Firebase pod for Google Analytics
    pod 'FirebaseAnalytics'
    pod 'FirebaseAuth'
    pod 'FirebaseMessaging'

end

post_install do |installer|
  xcode_base_version = `xcodebuild -version | grep 'Xcode' | awk '{print $2}' | cut -d . -f 1`

  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings["IPHONEOS_DEPLOYMENT_TARGET"] = "13.0"

      # For xcode 15+ only
      if config.base_configuration_reference && Integer(xcode_base_version) >= 15
        xcconfig_path = config.base_configuration_reference.real_path
        xcconfig = File.read(xcconfig_path)
        xcconfig_mod = xcconfig.gsub(/DT_TOOLCHAIN_DIR/, "TOOLCHAIN_DIR")
        File.open(xcconfig_path, "w") { |file| file << xcconfig_mod }
      end
    end
  end
end
