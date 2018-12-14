//
//  ScrollableBottomSheetViewController.swift
//  BottomSheet
//
//  Created by Ahmed Elassuty on 10/15/16.
//  Copyright © 2016 Ahmed Elassuty. All rights reserved.
//

import UIKit

class ScrollableBottomSheetViewController: UIViewController {
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    let fullView: CGFloat = 100
    
    var arrNearBy = [[String:Any]]()
    
    var latLongArray = [[String: Any]]()
    var partialView: CGFloat {
        return UIScreen.main.bounds.height - 150
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "DefaultTableViewCell", bundle: nil), forCellReuseIdentifier: "default")
        
        searchBar.isUserInteractionEnabled = true
        searchBar.showsCancelButton = true
        
        let gesture = UIPanGestureRecognizer.init(target: self, action: #selector(ScrollableBottomSheetViewController.panGesture))
        gesture.delegate = self
        view.addGestureRecognizer(gesture)
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prepareBackgroundView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animate(withDuration: 0.6, animations: { [weak self] in
            let frame = self?.view.frame
            let yComponent = self?.partialView
            self?.view.frame = CGRect(x: 0, y: yComponent!, width: frame!.width, height: frame!.height - 100)
        })
    }
    
    @objc func panGesture(_ recognizer: UIPanGestureRecognizer) {
        
        let translation = recognizer.translation(in: self.view)
        let velocity = recognizer.velocity(in: self.view)
        
        let y = self.view.frame.minY
        if (y + translation.y >= fullView) && (y + translation.y <= partialView) {
            self.view.frame = CGRect(x: 0, y: y + translation.y, width: view.frame.width, height: view.frame.height)
            recognizer.setTranslation(CGPoint.zero, in: self.view)
        }
        
        if recognizer.state == .ended {
            var duration =  velocity.y < 0 ? Double((y - fullView) / -velocity.y) : Double((partialView - y) / velocity.y )
            
            duration = duration > 1.3 ? 1 : duration
            
            UIView.animate(withDuration: duration, delay: 0.0, options: [.allowUserInteraction], animations: {
                if  velocity.y >= 0 {
                    self.view.frame = CGRect(x: 0, y: self.partialView, width: self.view.frame.width, height: self.view.frame.height)
                } else {
                    self.view.frame = CGRect(x: 0, y: self.fullView, width: self.view.frame.width, height: self.view.frame.height)
                }
                
            }, completion: { [weak self] _ in
                if ( velocity.y < 0 ) {
                    self?.tableView.isScrollEnabled = true
                }
            })
        }
    }
    
    func prepareBackgroundView(){
        let blurEffect = UIBlurEffect.init(style: .dark)
        let visualEffect = UIVisualEffectView.init(effect: blurEffect)
        let bluredView = UIVisualEffectView.init(effect: blurEffect)
        bluredView.contentView.addSubview(visualEffect)
        visualEffect.frame = UIScreen.main.bounds
        bluredView.frame = UIScreen.main.bounds
        view.insertSubview(bluredView, at: 0)
    }
    
}

extension ScrollableBottomSheetViewController {
    
    func getWaypoints(searchString: String) {
        
        var req = "\(Constant.SEARCHAPI)input=\(searchString)&type=&key=\(Constant.GOOGLEAPIKEY)"
        req = req.addingPercentEncoding( withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
        print(req)
        
        var request = URLRequest(url: URL(string: req)!)
        request.httpMethod = "GET"
        let session = URLSession.shared
        
        session.dataTask(with: request) {data, response, error in
            
            guard let data = data, error == nil else {
                print(error!)
                return
            }
            
            do {
                let resultJsons = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:Any]
                print("======Result =====",resultJsons!)
                if (String((resultJsons!["status"] as! String)) == "OK") {
                    self.arrNearBy = resultJsons!["predictions"] as! [[String : Any]]
                    print(self.arrNearBy)
                    OperationQueue.main.addOperation {
                        self.tableView.reloadData()
                    }
                } else if (String((resultJsons!["status"] as! String)) == "ZERO_RESULTS") {
                    
                }
                
            } catch {
                print("Error ---------> \(error)")
            }
            }.resume()
    }
    
    func getLatitudeLongitude(placeId: String)  {
        
        var req = "\(Constant.GETLATLONGAPI)type=&placeid=\(placeId)&key=\(Constant.GOOGLEAPIKEY)"
        req = req.addingPercentEncoding( withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
        print(req)
        
        var request = URLRequest(url: URL(string: req)!)
        request.httpMethod = "GET"
        let session = URLSession.shared
        
        session.dataTask(with: request) {data, response, error in
            
            guard let data = data, error == nil else {
                print(error!)
                return
            }
            
            do {
                let resultJsons = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:Any]
                //                print("======Result =====",resultJsons!)   formatted_address
                if (String((resultJsons!["status"] as! String)) == "OK") {
                    print(resultJsons!["result"]!)
                    var latitude = ""
                    var longitude = ""
                    var name = ""
                    var detailDescription = ""
                    
                    if let result = resultJsons!["result"] as? [String: Any]{
                        name = result["name"] as! String
                        detailDescription = ""
                        if let geometry = result["geometry"] as? [String: Any]{
                            if let location = geometry["location"] as? [String: Any]{
                                print(location["lat"]!)
                                print(location["lng"]!)
                                latitude = "\(location["lat"]!)"
                                longitude = "\(location["lng"]!)"
                                OperationQueue.main.addOperation {
                                    self.searchBar.resignFirstResponder()
                                    self.view.frame = CGRect(x: 0, y: self.partialView, width: self.view.frame.width, height: self.view.frame.height)
                                }
                                
                                var wayPoints: String = ""
                                wayPoints = wayPoints.count == 0 ? "\(location["lat"] as! Double),\(location["lng"] as! Double)" : "\(wayPoints)|\(location["lat"] as! Double),\(location["lng"] as! Double)"

                                let data = ["name": name,"detailName": detailDescription,"latitude": latitude,"longitude":longitude,"waypoints":wayPoints]
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "addNewMarkerOnMap"), object: nil, userInfo: data)
                            }
                        }
                    }
                } else if (String((resultJsons!["status"] as! String)) == "ZERO_RESULTS") {
                    
                }
                
            } catch {
                print("Error ---------> \(error)")
            }
            }.resume()
        
    }
    
}

extension ScrollableBottomSheetViewController: UISearchBarDelegate{
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.view.frame = CGRect(x: 0, y: self.fullView, width: self.view.frame.width, height: self.view.frame.height)
    }
    
    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if searchBar.text!.isEmpty{
        } else {
            self.view.frame = CGRect(x: 0, y: self.fullView, width: self.view.frame.width, height: self.view.frame.height)
        }
        return true
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        self.view.frame = CGRect(x: 0, y: self.partialView, width: self.view.frame.width, height: self.view.frame.height)
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        getWaypoints(searchString: searchBar.text!)
    }
}

extension ScrollableBottomSheetViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrNearBy.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "default") as! DefaultTableViewCell
        let places = arrNearBy[indexPath.row]
        cell.nameLabel.text = places["description"] as? String
        
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let places = arrNearBy[indexPath.row]
        getLatitudeLongitude(placeId: places["place_id"] as! String )
    }
}

extension ScrollableBottomSheetViewController: UIGestureRecognizerDelegate {
    
    // Solution
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        let gesture = (gestureRecognizer as! UIPanGestureRecognizer)
        let direction = gesture.velocity(in: view).y
        
        let y = view.frame.minY
        if (y == fullView && tableView.contentOffset.y == 0 && direction > 0) || (y == partialView) {
            tableView.isScrollEnabled = false
        } else {
            tableView.isScrollEnabled = true
        }
        
        return false
    }
    
}
