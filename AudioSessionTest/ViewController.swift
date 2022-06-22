//
//  ViewController.swift
//  AudioSessionTest
//
//  Created by ranbo on 2022/6/20.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    var player: AVPlayer?
    var playerItem: AVPlayerItem?
    @IBOutlet weak var playBt: UIButton!
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        NotificationCenter.default.addObserver(self, selector: #selector(interruptionHandle(_:)), name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(routeChangeHandle(_:)), name: AVAudioSession.routeChangeNotification, object: nil)
        initPlayer()
        testList()
        getCurAudioSessionConfig()
    }

    func initPlayer() {
        guard let path = Bundle.main.path(forResource: "test", ofType: "mp3") else { return }
        let url = URL.init(fileURLWithPath: path)
        playerItem = AVPlayerItem.init(url: url)
        player = AVPlayer.init(playerItem: playerItem)
    }
    
    @IBAction func playAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            player?.play()
        } else {
            player?.pause()
        }
    }
    
  
    func testList() {
        
        //1、测试系统默认是soloAmbient类别
//        getCurAudioSessionCategory()
        
        //2、ambient类别 受静音键影响，不支持后台播放 默认不支持混音 可以添加mixWithOthers选项  支持duckOthers
//        switchDiffCategory(.ambient)
//        switchDiffCategory(.ambient, [.mixWithOthers])
//        switchDiffCategory(.ambient, [.mixWithOthers,.duckOthers])
        
        //3、soloAmbient类别 受静音键影响，不支持后台播放 不支持混音 独奏类型  不可以添加mixWithOthers选项  不支持duckOthers
//        switchDiffCategory(.soloAmbient)
//        switchDiffCategory(.ambient, [.mixWithOthers])
        
        //4、playback类别 不受静音键影响，(支持后台播放 需info配置后台模式)，option 默认none  可以通过添加mixWithOthers支持混音  支持duckOthers
//        switchDiffCategory(.playback)
//        switchDiffCategory(.playback, [.mixWithOthers])
//        switchDiffCategory(.playback, [.mixWithOthers,.duckOthers])
//        switchDiffCategory(.playback, [.mixWithOthers,.duckOthers,.allowBluetooth])
        
        //5、record类别
//        switchDiffCategory(.record)
        
        //6、playAndRecord类别  播放的生、声音处于压低状态
        switchDiffCategory(.playAndRecord) //声音比较小
        switchDiffCategory(.playback, [.allowBluetooth])
        switchDiffCategory(.playback, [.allowBluetooth,.defaultToSpeaker])
        
        //7、multiRoute 多路输入输出
//        switchDiffCategory(.multiRoute)
    }
    
    func switchDiffCategory(_ category: AVAudioSession.Category,_ options: AVAudioSession.CategoryOptions? = nil) {
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            if let options = options {
                try audioSession.setCategory(category, options: options)
            } else {
                try audioSession.setActive(true)
            }
        } catch {
            print("faild")
        }
    }
    
    func getCurAudioSessionConfig() {
        
        print("current category--\(AVAudioSession.sharedInstance().category.rawValue)")
        let options = AVAudioSession.sharedInstance().categoryOptions
        if options == .duckOthers {
          print("options: duckOthers")

        } else if options == .mixWithOthers {
          print("options: mixWithOthers")

        } else if options == .defaultToSpeaker {
          print("options: defaultToSpeaker")

        } else if options == .allowBluetooth {
          print("options: allowBluetooth")

        } else if options == .interruptSpokenAudioAndMixWithOthers {
          print("options: interruptSpokenAudioAndMixWithOthers")

        } else if options == .allowBluetoothA2DP {
          //Bluetooth Advanced Audio Distribution Profile (A2DP) 蓝牙高级音频分发模式
          print("options: allowBluetoothA2DP")

        } else if options == .allowAirPlay {
          print("options: allowAirPlay")

        } else if #available(iOS 14.5, *), options == .overrideMutedMicrophoneInterruption {
            //覆盖静音的麦克风中断
            /*
             iPad Smart Folio （智能对开本 即磁吸开关保护套）
             当 iPad 的 Smart Folio 关闭时，系统会自动关闭 iPad 的内置麦克风，自动停止录音。
             这个安全功能是默认启动的，如果应用需要在关闭 Smart Folio 时仍继续录音，则需要使 AVAudioSession.CategoryOptions overrideMutedMicrophoneInterruption API 来选择继续录音
             */
            print("options: overrideMutedMicrophoneInterruption")
        } else {
            print("option: None")
        }
        print("mode = \(AVAudioSession.sharedInstance().mode.rawValue)")

    }
    
    func checkHeadphonesIn() {
        
        let  currentRoute = AVAudioSession.sharedInstance().currentRoute
        currentRoute.outputs.forEach { (item) in
            if item.portType == .headphones {
                print("headphones are plugged in")
            }
        }
    }
    
    @objc func interruptionHandle(_ note: NSNotification) {

       guard let value = note.userInfo?["AVAudioSessionInterruptionTypeKey"] else { return }
       if let typeValue = value as? Int {
         if typeValue == AVAudioSession.InterruptionType.began.rawValue {
             player?.pause()
             print("保存播放或录制状态，上下文，更新用户界面等")
         } else if typeValue == AVAudioSession.InterruptionType.ended.rawValue {
             do {
                 try AVAudioSession.sharedInstance().setActive(true)
             } catch {
                 print(error)
             }
             player?.play()
             print("恢复播放或录制状态,上下文，更新用户界面等")
         }
       }
    }
    
    @objc func routeChangeHandle(_ note: NSNotification) {
        guard let value = note.userInfo?["AVAudioSessionRouteChangeReasonKey"] else { return }
        guard let typeValue = value as? UInt else { return }
        switch typeValue {
        case AVAudioSession.RouteChangeReason.unknown.rawValue:
            print("未知原因")
        case AVAudioSession.RouteChangeReason.newDeviceAvailable.rawValue:
            print("有新设备可用") //例如，已插入耳机
        case AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue:
            print("老设备不可用") //例如，耳机已拔下。
        case AVAudioSession.RouteChangeReason.categoryChange.rawValue:
            print("类别发生改变") //例如，AVAudioSession.Category.playback 被改变为 AVAudioSession.Category.playAndRecord。
        case AVAudioSession.RouteChangeReason.override.rawValue:
            print("重置了输出设置")//例如，类别为AVAudioSession.Category.playAndRecord和输出已从默认的接收器更改为扬声器。
        case AVAudioSession.RouteChangeReason.wakeFromSleep.rawValue:
            print("设备从睡眠中醒来")
        case AVAudioSession.RouteChangeReason.noSuitableRouteForCategory.rawValue:
            print("当前Category没有可用的设备") //（例如，类别为 AVAudioSession.Category.record，但没有可用的输入设备）
        case AVAudioSession.RouteChangeReason.routeConfigurationChange.rawValue:
            print("Rotue的配置发送变化") //例如，端口的选定数据源已更改
        default:
            break
        }
    }
    
    func requestRecordPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] (granted) in
            DispatchQueue.main.async {
                if granted == false {
                    let alertController = UIAlertController(title: "请在设备的'设置->隐私->麦克风'中打开本应用的访问权限",
                                                            message: nil,
                                                            preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
                    let okAction = UIAlertAction(title: "设置", style: .default, handler: { (action) in
                        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                        if UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    })
                    alertController.addAction(cancelAction)
                    alertController.addAction(okAction)
                    self?.present(alertController, animated: true, completion: nil)
                } else {
                    //已授权操作
                }
            }
        }
    }
    
    
}



