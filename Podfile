platform :ios, '11.0'

target 'XGenOutputUsageDemo_iOS' do
     pod 'xgen', :path => 'xgen'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['ENABLE_BITCODE'] = 'NO'
        end
    end
end
