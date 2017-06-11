//
//  ViewController.swift
//  myRecords
//
//  Created by Luis Tejada on 8/6/17.
//  Copyright © 2017 Luis Tejada. All rights reserved.
//

import UIKit
import AVFoundation

import MobileCoreServices
import CoreSpotlight

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AVAudioRecorderDelegate, AVAudioPlayerDelegate, UISearchBarDelegate {
    
    @IBOutlet weak var durationLabel: UILabel!
    
    private var records = Array<URL>()
    
    private var filteredRecords = Array<URL>()
    
    @IBOutlet weak var playerView: UIView!
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
    
    private var searchQuery : CSSearchQuery?
    private var playerUp = true
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        loadRecords()
        
        sesion = AVAudioSession.sharedInstance()
        
        recordButton.layer.cornerRadius = 24.0
        playButton.layer.cornerRadius = 18.0
        nextButton.layer.cornerRadius = 18.0
        previousButton.layer.cornerRadius = 18.0
        
        
        self.recordsTableView.estimatedRowHeight = 44.0
        self.recordsTableView.rowHeight = UITableViewAutomaticDimension
        self.recordsTableView.tableFooterView = UIView(frame: CGRect.zero)
        
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
        
        let swipeUpPlayer = UISwipeGestureRecognizer(target: self, action: #selector(self.swipePlayer(_:)))
        swipeUpPlayer.direction = UISwipeGestureRecognizerDirection.up
        playerView.addGestureRecognizer(swipeUpPlayer)
        
        let swipeDownPlayer = UISwipeGestureRecognizer(target: self, action: #selector(self.swipePlayer(_:)))
        swipeDownPlayer.direction = UISwipeGestureRecognizerDirection.down
        playerView.addGestureRecognizer(swipeDownPlayer)
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        playerView.layer.cornerRadius = 10.0
        
        if filteredRecords.count > 0 {
            
            let indexPath = IndexPath(row: 0, section: 0)
            recordsTableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableViewScrollPosition.top)
        }
    }
    func swipePlayer(_ sender: UISwipeGestureRecognizer) {
        
        let direction = sender.direction
        switch direction {
            
        case UISwipeGestureRecognizerDirection.down:
            
            if playerUp {
                UIView.animate(withDuration: 0.3, animations: {
                    
                    self.playerView.center.y += self.playerView.bounds.midY
                    self.playerUp = false
                    print("swipe")
                })
            }
            break;
            
        case UISwipeGestureRecognizerDirection.up:
            
            if !playerUp {
                UIView.animate(withDuration: 0.3, animations: {
                    
                    self.playerView.center.y -= self.playerView.bounds.midY
                    self.playerUp = true
                    print("swipe")
                })
            }
            break;
            
        default: break;
            
        }
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
            
            if filteredRecords.count > 0 {
                
                playButton.setImage(#imageLiteral(resourceName: "ic_pause"), for: .normal)
                playRecord(url: records[row])
            }
            
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
        
        if reproductor != nil {
            
            reproductor.currentTime = TimeInterval(sender.value)
            reproductor.play()
        }
    }
    
    @IBAction func previousRecord(_ sender: UIButton) {
        
        if recordsTableView.indexPathForSelectedRow!.row != 0 {
            
            let indexPath = IndexPath(row: recordsTableView.indexPathForSelectedRow!.row - 1, section: 0)
            recordsTableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableViewScrollPosition.middle)
            
        }
        if reproductor == nil {
            
            playRecord(url: records[recordsTableView.indexPathForSelectedRow!.row])
            playButton.setImage(#imageLiteral(resourceName: "ic_pause"), for: .normal)
        }else {
            if reproductor.isPlaying {
                
                reproductor.stop()
                playRecord(url: records[recordsTableView.indexPathForSelectedRow!.row])
                playButton.setImage(#imageLiteral(resourceName: "ic_pause"), for: .normal)
            }
        }
    }
    @IBAction func nextRecord(_ sender: UIButton) {
        
        if recordsTableView.indexPathForSelectedRow!.row == records.count-1 {
            
            let indexPath = IndexPath(row: 0, section: 0)
            recordsTableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableViewScrollPosition.top)
            
        } else {
            
            let indexPath = IndexPath(row: recordsTableView.indexPathForSelectedRow!.row + 1, section: 0)
            recordsTableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableViewScrollPosition.middle)
        }
        if reproductor == nil {
            
            playRecord(url: records[recordsTableView.indexPathForSelectedRow!.row])
            playButton.setImage(#imageLiteral(resourceName: "ic_pause"), for: .normal)
        } else {
            
            if reproductor.isPlaying {
                
                reproductor.stop()
                playRecord(url: records[recordsTableView.indexPathForSelectedRow!.row])
                playButton.setImage(#imageLiteral(resourceName: "ic_pause"), for: .normal)
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return filteredRecords.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = recordsTableView.dequeueReusableCell(withIdentifier: "recordCell", for: indexPath)
        
        cell.textLabel?.text = Utils.getFileName(url: filteredRecords[indexPath.row])
        
        return cell;
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if reproductor != nil {
            
            reproductor.stop()
        }
        playRecord(url: filteredRecords[indexPath.row])
        self.durationLabel.text = Utils.stringFromTimeInterval(interval: reproductor.duration)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        return true
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            let fileManager = FileManager.default
            
            do {
                
                let index = records.index { (item) -> Bool in
                    
                    item.lastPathComponent == filteredRecords[indexPath.row].lastPathComponent
                }
                if let index = index {
                    
                    try fileManager.removeItem(at: filteredRecords[indexPath.row])
                    deIndexRecord(record: filteredRecords[indexPath.row])
                    records.remove(at: index)
                    filteredRecords.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .automatic)
                    recordsTableView.reloadData()
                }
                
            } catch {
                
                print("No se pudo eliminar el archivo")
            }
        }
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
            indexRecord(record: recorder.url, text: Utils.getFileName(url: recorder.url))
            
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
            self.durationLabel.text = Utils.stringFromTimeInterval(interval: self.reproductor.duration)
            reproductor.play()
            
            
        } catch {
            
            print("No se pudo reproducir el audio! \(error.localizedDescription)")
        }
        print(reproductor.url!.absoluteString)
    }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        
        if flag {
            
            playButton.setImage(#imageLiteral(resourceName: "ic_play"), for: .normal)
            timerSlider.setValue(0, animated: false)
            stopTimerPlayer()
            
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
    
    func filterRecords(text: String){
        
        guard text.characters.count > 0 else {
            self.filteredRecords = self.records
            
            UIView.performWithoutAnimation {
                
                recordsTableView.reloadData()
            }
            
            return
        }
        
        
        
        
        var allTheItems : [CSSearchableItem] = []
        
        self.searchQuery?.cancel()
        
        let queryString = "contentDescription == \"*\(text)*\"c"
        self.searchQuery = CSSearchQuery(queryString: queryString, attributes: nil)
        
        self.searchQuery?.foundItemsHandler = { items in
            allTheItems.append(contentsOf: items)
        }
        
        self.searchQuery?.completionHandler = { error in
            DispatchQueue.main.async { [unowned self] in
                self.activateFilter(matches: allTheItems)
            }
        }
        
        self.searchQuery?.start()
        
    }
    
    func activateFilter(matches: [CSSearchableItem]){
        
        self.filteredRecords = matches.map { item in
            let uniqueID = item.uniqueIdentifier
            let url = URL(fileURLWithPath: uniqueID)
            return url
        }
        
        UIView.performWithoutAnimation {
            recordsTableView.reloadData()
        }
        
        
    }
    
    func indexRecord(record: URL, text: String){
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
        attributeSet.title = "Grabacion de myRecords"
        attributeSet.contentDescription = text
        attributeSet.thumbnailData = UIImagePNGRepresentation(#imageLiteral(resourceName: "ic_mic"))
  
        
        let item = CSSearchableItem(uniqueIdentifier: record.path, domainIdentifier: "me.luistejada", attributeSet: attributeSet)
        item.expirationDate = Date.distantFuture
        
        
        CSSearchableIndex.default().indexSearchableItems([item]) { (error) in
            if let error = error {
                print("Ha habido un problema al indexar \(error)")
            } else {
                print("Hemos podido indexar correctamente el texto : \(text)")
            }
        }
        
    }
    
    func deIndexRecord(record: URL) {
        
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [record.path]) { (error) in
            
            if error != nil {
                
                print("Se elimino correctamente!")
            }
        }
    }


    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        filterRecords(text: searchText)
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
    override func restoreUserActivityState(_ activity: NSUserActivity) {
        
        
        let path = activity.userInfo?[CSSearchableItemActivityIdentifier] as! String
        let urlPath = URL(string: path)
        let url = Utils.getDocumentsDirectory().appendingPathComponent((urlPath!.lastPathComponent))
        
        let index = filteredRecords.index { (item) -> Bool in
            
            item.lastPathComponent == url.lastPathComponent
            
        }
        
        if let index = index {
            
            recordsTableView.selectRow(at: IndexPath(row: index, section: 0), animated: true, scrollPosition: .middle)
        }
    }
}

