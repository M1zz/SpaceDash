//
//  HomeViewController.swift
//  SpaceX
//
//  Created by Pushpinder Pal Singh on 24/06/20.
//  Copyright © 2020 Pushpinder Pal Singh. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {
    
    @IBOutlet weak var upcomingView: UpcomingView!
    @IBOutlet weak var upcomingPanel: NSLayoutConstraint!
    @IBOutlet var panelConstraints: [NSLayoutConstraint]!
    @IBOutlet weak var launchDate: UILabel!
    @IBOutlet weak var launchSite: UILabel!
    @IBOutlet weak var missions: UILabel!
    @IBOutlet weak var watchNowButton: WatchNowButton!
    @IBOutlet weak var isTentative: UILabel!
    @IBOutlet weak var rocketImage: RocketImageView!
    @IBOutlet var launchProviderLogo: UIImageView!
    
    let networkObject = NetworkManager(Constants.NetworkManager.rocketLaunchLiveAPI)
    let cache = NSCache<NSString, DetailsViewModel>()
    
    var watchURL : URL? = nil
    
    let smallDeviceHeight: CGFloat = 896
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        networkObject.performRequest(key: Constants.HomeView.nextLaunch) { [weak self] (result: Result<NextLaunchData,Error>) in
            guard let self = self else { return }
            
            switch result {
            
            case .success(let nextLaunch):
                self.updateUI(nextLaunch)
                print(nextLaunch)
                break
                
            case .failure(let error):
                print(error)
            }
        }
        
        adjustUpcomingSize()
        
        //tap gesture for tentative label
        self.isTentative.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tentativeClicked(_:))))
        self.isTentative.isUserInteractionEnabled = true
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    @IBAction func buttonPressed(_ sender: UIButton) {
        performSegue(withIdentifier: Constants.SegueManager.detailViewSegue, sender: sender.titleLabel?.text)
    }
    
    @IBAction func watchNowButton(_ sender: UIButton) {
        UIApplication.shared.open(watchURL!)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let target = segue.destination as? DetailsViewController {
            let key = sender as! String
            print("Sender: \(key)")
            
            switch key {
            case Constants.SegueManager.SenderValues.rocket:
                target.callAPI(withEndpoint: key, decode: [RocketData](), cachedData: cache)
                break
            case Constants.SegueManager.SenderValues.launches:
                target.callAPI(withEndpoint: key, decode: [LaunchesData](), cachedData: cache)
                break
            case Constants.SegueManager.SenderValues.launchSite:
                target.callAPI(withEndpoint: key, decode: [LaunchPadData](), cachedData: cache)
                break
            case Constants.SegueManager.SenderValues.ships:
                target.callAPI(withEndpoint: key, decode: [ShipsData](), cachedData: cache)
                break
            case Constants.SegueManager.SenderValues.capsules:
                target.callAPI(withEndpoint: key, decode: [CapsulesData](), cachedData: cache)
                break
            case Constants.SegueManager.SenderValues.landpads:
                target.callAPI(withEndpoint: key, decode: [LandpadsData](), cachedData: cache)
                break
            default:
                print("error")
            }
        }
    }
    
}

//MARK: - UI

extension HomeViewController: UIPopoverPresentationControllerDelegate {
    
    /// Making the Height of Upcoming Panel and View Dynamic
    func adjustUpcomingSize() {
        if UIScreen.main.bounds.height<smallDeviceHeight || !watchNowButton.isHidden {
            upcomingPanel.constant = UIScreen.main.bounds.height*0.04
            
            for panels in panelConstraints{
                panels.constant = UIScreen.main.bounds.height*0.025
            }
        }
        
        if UIScreen.main.bounds.height<smallDeviceHeight && !watchNowButton.isHidden {
            upcomingView.setupSmallHeight()
        }
    }
    
    /// This function will update the UI once updateFromAPI updates the data for HomeViewController
    func updateUI(_ upcomingLaunch : NextLaunchData){
        DispatchQueue.main.async {
            self.launchSite.text = upcomingLaunch.launchSite
            self.missions.text = upcomingLaunch.missions
            self.launchDate.text =  upcomingLaunch.date
            self.launchProviderLogo.image = UIImage(named: upcomingLaunch.providerSlug)
//            self.isTentative.isHidden = !(upcomingLaunch.isTentative!)
//            self.rocketImage.image = UIImage(named: upcomingLaunch.rocket!)
//            self.checkWatchButton()
            self.adjustUpcomingSize()
        }
    }
    
    /// This function will assign the video URL of the upcoming launch and display the "Watch Now" button if the URL available
//    func checkWatchButton() {
//        guard let safeWatchURL = upcomingLaunch.watchNow, UIApplication.shared.canOpenURL(safeWatchURL) else { return }
//        self.watchURL = safeWatchURL
//        watchNowButton.isHidden = false
//    }
    
    
    @objc func tentativeClicked(_ sender: UITapGestureRecognizer){
        // we dont want to fill the popover to full width of the screen
        let standardWidth = self.view.frame.width - 60
        
        //to dynamically resize the popover, we premature-ly calculate the height of the label using the text content
        let estimatedHeight = Constants.HomeView.tentativeDetail.height(ConstrainedWidth: standardWidth - 24)
        
        let tentativeDetailsVC = TentativeDetailsViewController()
        tentativeDetailsVC.lblTentativeDetail.text = Constants.HomeView.tentativeDetail
        tentativeDetailsVC.modalPresentationStyle = .popover //this tells that the presenting viewcontroller is an popover style
        tentativeDetailsVC.preferredContentSize = CGSize.init(width: standardWidth, height: estimatedHeight + 40) //40 is vertical padding
        tentativeDetailsVC.overrideUserInterfaceStyle = .light //disabling dark mode
        
        if let popoverPresentationController = tentativeDetailsVC.popoverPresentationController {
            //this option makes popover to preview below the "T" sign
            popoverPresentationController.permittedArrowDirections = .up
            //source view and source rect is used by popover controller to determine where the triangle should be placed and present the popover relative to the source view
            popoverPresentationController.sourceView = self.isTentative
            popoverPresentationController.sourceRect = self.isTentative.bounds
            popoverPresentationController.delegate = self
        }
        self.present(tentativeDetailsVC, animated: true, completion: nil)
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        // .none makes the viewcontroller to be present as popover always, no matter what trait changes
        return .none
    }
    
}
