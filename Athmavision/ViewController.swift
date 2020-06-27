//
//  ViewController.swift
//  Athmavision
//
//  Created by IRPL on 12/05/20.
//  Copyright © 2020 IRPL. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

class ViewController: UIViewController, TaskListener {

    @IBOutlet weak var btnPlayPause: UIView!
    @IBOutlet weak var playPauseImage: UIImageView!
    @IBOutlet weak var uiviewVolumeController: UIView!
    @IBOutlet weak var imgVolumeDown: UIImageView!
    @IBOutlet weak var imgVolumeUp: UIImageView!
    @IBOutlet weak var imgMute: UIImageView!
    @IBOutlet weak var volumeSlider: UISlider!
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var labelArtist: UILabel!
    @IBOutlet weak var openURL: UILabel!
    
    var isPlaying: Bool!
    var isMuted: Bool!
    var URL: String!
    var listSongs = Array<StreamAPIData>()
    var volume: Float!
    var updateUI = false
    
    
    var player: AVPlayer?
    var outputVolumeObserve: NSKeyValueObservation?
    let audioSession = AVAudioSession.sharedInstance()
    let audioEngine = AVAudioEngine.init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        overrideUserInterfaceStyle = .light
        initAudio()
        
       let gradientLayer = CAGradientLayer()
        let endColor = UIColor(red: 0/255, green: 74/255, blue: 126/255, alpha: 1.0)
        let startColor = UIColor(red: 24/255, green: 105/255, blue: 94/255, alpha: 1.0)
        
//        gradientLayer.locations = [0.1, 1.0]
        gradientLayer.startPoint = CGPoint(x: 1.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.0, y: 1.0)
        gradientLayer.frame = self.btnPlayPause.bounds
        gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
        self.btnPlayPause.layer.insertSublayer(gradientLayer, at: 0)
        
        makeRoundedLayout(view: self.btnPlayPause)
        
        isPlaying = true
        isMuted = false
        URL = "https://janus.cdnstream.com:2199/rpc/athmavis/streaminfo.get"
        volume = self.volumeSlider.value
        player?.volume = volume
        
        
//        self.playPauseImage.bringSubviewToFront(self.btnPlayPause)
        
        
        let play = UITapGestureRecognizer(target: self, action: #selector(self.playPause))
        self.btnPlayPause.addGestureRecognizer(play)
        
        let volumeUp = UITapGestureRecognizer(target: self, action: #selector(self.increaseVolume))
        self.imgVolumeUp.addGestureRecognizer(volumeUp)
        let volumeDown = UITapGestureRecognizer(target: self, action: #selector(self.decreaseVolume))
        self.imgVolumeDown.addGestureRecognizer(volumeDown)
        
        let mute = UITapGestureRecognizer(target: self, action: #selector(self.muteVolume))
        self.imgMute.addGestureRecognizer(mute)
        
        let gotoURL = UITapGestureRecognizer(target: self, action: #selector(self.gotoURL))
        self.openURL.addGestureRecognizer(gotoURL)
        
        let apiCall = WebService()
        apiCall.WebService(self.URL, delegate: self, tag: "API")
        
        Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(self.callApiBackground), userInfo: nil, repeats: true)
    }
    
    @IBAction func sliderValueChanged(_ sender: Any) {
        player?.volume = (sender as! UISlider).value
        self.volume = (sender as! UISlider).value
        
        //audioSession.setValue((sender as! UISlider).value, forKey: "outputVolume")
    }
    
    @objc func callApiBackground() {
        let apiCall = WebService()
        apiCall.WebService(self.URL, delegate: self, tag: "API")
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        player?.play()
        self.isPlaying = true
        self.playPauseImage.image = UIImage(systemName: "pause")
        listenVolumeButton()
        
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(AVAudioSession.Category.playback,
            mode: .default,
            policy: .default,
            options: [])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        }
        catch{
            print(error)
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
    }
    
    func makeRoundedLayout(view: UIView) {
        view.layer.cornerRadius = 25
        view.clipsToBounds = true
    }

    @objc func playPause(sender: UITapGestureRecognizer) {
        if (isPlaying) {
            self.playPauseImage.image = UIImage(systemName: "play")
            isPlaying = false
            player?.pause()
        }
        else {
            self.playPauseImage.image = UIImage(systemName: "pause")
            isPlaying = true
            player?.play()
        }
        
        self.playPauseImage.layoutIfNeeded()
        
    }
    
    @objc func increaseVolume(sender: UITapGestureRecognizer) {
        let currentVolume = self.volumeSlider.value
        if (currentVolume < self.volumeSlider.maximumValue) {
            self.volume = currentVolume + 0.1
            self.volumeSlider.setValue(currentVolume + 0.1, animated: true)
            self.player?.volume = volume
        }
    }
    
    @objc func decreaseVolume(sender: UITapGestureRecognizer) {
        let currentVolume = self.volumeSlider.value
        if (currentVolume > 0) {
            self.volume = currentVolume - 0.1
            self.volumeSlider.setValue(currentVolume - 0.1, animated: true)
            self.player?.volume = volume
        }
    }
    
    @objc func muteVolume(sender: UITapGestureRecognizer) {
        if (isMuted) {
            isMuted = false
            self.imgMute.image = UIImage(systemName: "speaker.2")
            self.player?.isMuted = false
        }
        else {
            isMuted = true
            self.imgMute.image = UIImage(systemName: "speaker.slash")
            self.player?.isMuted = true
        }
    }
    
    func initAudio() {
        let url = NSURL(string: "http://janus.cdnstream.com:5680//stream")
        let playerItem:AVPlayerItem = AVPlayerItem(url: url! as URL)
        player = AVPlayer(playerItem: playerItem)
        
        let playerLayer=AVPlayerLayer(player: player!)
               playerLayer.frame=CGRect(x:0, y:0, width:10, height:50)
               self.view.layer.addSublayer(playerLayer)

    }
    
    @objc func gotoURL(sender: UITapGestureRecognizer) {
        guard let url = NSURL(string: "http://www.athmavision.org/") else {
          return //be safe
        }

        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url as URL, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url as URL)
        }
    }

    func listenVolumeButton() {
        do {
            try audioSession.setActive(true)
        } catch {}

        outputVolumeObserve = audioSession.observe(\.outputVolume) { (audioSession, changes) in
            /// TODOs
        }
    }
    
    func playerDidFinishPlaying(note: NSNotification) {
        // Your code here
    }
    
    @objc func stopPlayer() {
        self.player?.pause()
        self.isPlaying = false
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if object is AVPlayer {
            switch player?.timeControlStatus {
            case .playing:
                break;
            default:
                break;
            }
        }
    }
    
    func setUpMediaPlayerNotificationView(title: String, name: String) {
        
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [unowned self] event in
            
            self.playPauseImage.image = UIImage(systemName: "pause")
                self.player?.play()
            self.isPlaying = true
                return .success
        }

        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { [unowned self] event in
            
            self.isPlaying = false
            self.playPauseImage.image = UIImage(systemName: "play")
                self.player?.pause()
                return .success
        }
        
        commandCenter.seekForwardCommand.addTarget { [unowned self] event in
            
            return .success
        }
        
        var nowPlayingInfo = [String : Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = name
        nowPlayingInfo[MPMediaItemPropertyArtist] = title

        if let image = UIImage(named: "logo") {
            nowPlayingInfo[MPMediaItemPropertyArtwork] =
                MPMediaItemArtwork(boundsSize: image.size) { size in
                    return image
            }
        }
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player!.currentTime().seconds
//        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = playerItem.asset.duration.seconds
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player?.rate

        // Set the metadata
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    func webResponse(_ result: NSDictionary, tag: String) {
        if let songsList = result["data"] as? [[String: Any]] {
            for songs in songsList {
                if let details: NSDictionary = (songs["track"] as? AnyObject as! NSDictionary) {
                    DispatchQueue.main.async {
                        self.labelTitle.text = (details["title"] as! String)
                        self.labelArtist.text = (details["artist"] as! String)
                        
                        if (!self.updateUI) {
                            self.setUpMediaPlayerNotificationView(title: details["title"] as! String, name: details["artist"] as! String)
                            self.updateUI = true
                        }
                        
                        
                    }
                }
            }
        }
    }
}
