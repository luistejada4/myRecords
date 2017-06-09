//
//  ViewController.swift
//  myRecords
//
//  Created by Luis Tejada on 8/6/17.
//  Copyright © 2017 Luis Tejada. All rights reserved.
//

import UIKit
import AVFoundation

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    private var someObservationContext: String = "something"
    
    private var records = Array<URL>()
    
    private var filteredRecords = Array<URL>()
    
    @IBOutlet weak var timerSlider: UISlider!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var recordsTableView: UITableView!
    
    private var reproductor : AVAudioPlayer!
    private var grabador: AVAudioRecorder!
    private var sesion: AVAudioSession!
    private var timerPlayer: Timer!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadRecords()
        
        sesion = AVAudioSession.sharedInstance()
        
        recordButton.layer.cornerRadius = 24.0
        playButton.layer.cornerRadius = 18.0
        nextButton.layer.cornerRadius = 18.0
        previousButton.layer.cornerRadius = 18.0
        
        recordsTableView.estimatedRowHeight = 44.0
        recordsTableView.rowHeight = UITableViewAutomaticDimension
        recordsTableView.tableFooterView = UIView(frame: CGRect.zero)
        
        if sesion.recordPermission() == .undetermined {
            
            do {
                
                try sesion.setCategory(AVAudioSessionCategoryRecord)
                try sesion.setActive(true)
                
                sesion.requestRecordPermission({ (bool) in
                    
                    if !bool {
                        
                        self.recordButton.isEnabled = false
                    }
                })
                
            } catch {
                
                
            }
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    @IBAction func recordButton(_ sender: UIButton) {
        
        if(sender.imageView?.image == #imageLiteral(resourceName: "ic_mic"))
        {
            sender.setImage(#imageLiteral(resourceName: "ic_stop"), for: .normal)
            comenzarGrabacion()
        } else {
            
            sender.setImage(#imageLiteral(resourceName: "ic_mic"), for: .normal)
            grabador.stop()
        }
    }
    
    @IBAction func playButton(_ sender: UIButton) {
        
        var row = 0
        if let indexPath = recordsTableView.indexPathForSelectedRow {
            
            row = indexPath.row
        }
        
        if reproductor == nil {
            
            playButton.setImage(#imageLiteral(resourceName: "ic_pause"), for: .normal)
            playRecord(url: records[row])
            
        } else {
            
            if reproductor.currentTime == 0.0 {
                
                playButton.setImage(#imageLiteral(resourceName: "ic_pause"), for: .normal)
                playRecord(url: records[row])
            }
            else if reproductor.isPlaying {
                
                reproductor.pause()
                stopTimerPlayer()
                playButton.setImage(#imageLiteral(resourceName: "ic_play"), for: .normal)
            } else {
                
                reproductor.play()
                starTimerPlayer()
                playButton.setImage(#imageLiteral(resourceName: "ic_pause"), for: .normal)
            }
        }
    }
    
    @IBAction func setPlayerTimer(_ sender: UISlider) {
        
        reproductor.currentTime = TimeInterval(sender.value)
        reproductor.play()
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return records.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = recordsTableView.dequeueReusableCell(withIdentifier: "recordCell", for: indexPath)
        
        cell.textLabel?.text = Utils.getFileName(url: records[indexPath.row])
        
        return cell;
    }
    func comenzarGrabacion() {
        
        let fileName = Utils.getDocumentsDirectory().appendingPathComponent("audio-\(Date().timeIntervalSince1970).m4a")
        
        let config = [
            
            AVFormatIDKey : Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey : 12000,
            AVNumberOfChannelsKey : 1,
            AVEncoderAudioQualityKey : AVAudioQuality.high.rawValue]
        
        do {
            
            try grabador = AVAudioRecorder(url: fileName, settings: config)
            try sesion.setCategory(AVAudioSessionCategoryRecord)
            try sesion.setActive(true)
            grabador.delegate = self
            grabador.record()
            
        } catch {
            
            
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        
        if flag {
            
            print("Grabacion extiosa!")
            records.append(recorder.url)
            filteredRecords = records
            recordsTableView.beginUpdates()
            recordsTableView.insertRows(at: [IndexPath(row: filteredRecords.count-1, section: 0)], with: .automatic)
            recordsTableView.endUpdates()
        }
    }
    
    func playRecord(url: URL) {
        
        do {
            
            try reproductor = AVAudioPlayer(contentsOf: url)
            try sesion.setCategory(AVAudioSessionCategoryPlayback)
            try sesion.setActive(true)
            reproductor.delegate = self
            reproductor.prepareToPlay()
            
            timerSlider.maximumValue = Float(reproductor.duration)
            
            starTimerPlayer();
            
            reproductor.play()
            
            
        } catch {
            
            print("No se pudo reproducir el audio! \(error.localizedDescription)")
        }
        print(reproductor.url!.absoluteString)
    }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        
        if flag {
            
            playButton.setImage(#imageLiteral(resourceName: "ic_play"), for: .normal)
            timerPlayer.invalidate()
            timerSlider.setValue(0, animated: false)
            
        }
    }
    func starTimerPlayer() {
        
        timerPlayer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { (time) in
            
            print("\(Float(self.reproductor.currentTime)) : \(Float(self.reproductor.duration))")
            self.timerSlider.setValue(Float(self.reproductor.currentTime), animated: true)
            
        })
    }
    func stopTimerPlayer() {
        
        if timerPlayer != nil {
            timerPlayer.invalidate()
            timerPlayer = nil
        }
    }
    func loadRecords() {
        
        guard let files = try? FileManager.default.contentsOfDirectory(at: Utils.getDocumentsDirectory(), includingPropertiesForKeys: nil, options: []) else {
            return
        }
        
        for file in files {
            
            if file.lastPathComponent.hasSuffix(".m4a") {
                
                records.append(file)
            }
        }
        filteredRecords = records
    }
}

