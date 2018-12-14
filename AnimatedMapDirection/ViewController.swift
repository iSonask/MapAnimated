//
//  ViewController.swift
//  AnimatedMapDirection
//
//  Created by SHANI SHAH on 06/12/18.
//  Copyright © 2018 SHANI SHAH. All rights reserved.
// https://stackoverflow.com/questions/42620510/how-to-get-animated-polyline-route-in-gmsmapview-so-that-it-move-along-with-map
// https://stackoverflow.com/questions/40650366/move-the-annotation-on-map-like-uber-ios-application

import UIKit
import GoogleMaps

let kMapStyle = "[" +
    "  {" +
    "    \"featureType\": \"poi.business\"," +
    "    \"elementType\": \"all\"," +
    "    \"stylers\": [" +
    "      {" +
    "        \"visibility\": \"off\"" +
    "      }" +
    "    ]" +
    "  }," +
    "  {" +
    "    \"featureType\": \"transit\"," +
    "    \"elementType\": \"labels.icon\"," +
    "    \"stylers\": [" +
    "      {" +
    "        \"visibility\": \"off\"" +
    "      }" +
    "    ]" +
    "  }" +
"]"


class ViewController: UIViewController {

    @IBOutlet weak var myMapView: GMSMapView!
    
    var camera = GMSCameraPosition()
    var latitude = String()
    var longitude = String()
    var stepsArray = [[String: Any]]()
    var polyline: GMSPolyline!
    let marker = GMSMarker()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("locations = \(Global.shared.locations.latitude) \(Global.shared.locations.longitude)")
        camera = GMSCameraPosition.camera(withTarget: Global.shared.locations, zoom: 2.0)

        myMapView.animate(to: camera)
        myMapView.isMyLocationEnabled = true
        myMapView.settings.myLocationButton = false
        myMapView.isTrafficEnabled = true
        
        do {
            // Set the map style by passing a valid JSON string.
            let styleURL = Bundle.main.url(forResource: "DayStyle", withExtension: "json")
            myMapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL!)
        } catch {
            NSLog("One or more of the map styles failed to load. \(error)")
        }

        
        NotificationCenter.default.addObserver(self, selector: #selector(changeLocation), name: NSNotification.Name(rawValue: "handleNewNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(addMarker(_:)), name: NSNotification.Name(rawValue: "addNewMarkerOnMap"), object: nil)

        addBottomSheetView()
    }
    
    @objc func changeLocation()  {
        camera = GMSCameraPosition.camera(withTarget: Global.shared.locations, zoom: 15.0)
        
        myMapView.animate(to: camera)
    }
    
    @objc func addMarker(_ notification: Notification) {
        print(notification.userInfo!)
        guard let data = notification.userInfo as? [String: String] else { return }
//        print(data["latitude"])
        latitude = data["latitude"]!
        longitude = data["longitude"]!
        OperationQueue.main.addOperation {
            
        
            
            self.marker.isDraggable = true
            self.marker.position = CLLocationCoordinate2D(latitude: Double(data["latitude"]!)!, longitude: Double(data["longitude"]!)!)
            self.marker.title = data["name"]
            self.marker.snippet = data["detailName"]
            self.marker.map = self.myMapView
            self.myMapView.delegate = self
            let location = CLLocationCoordinate2D(latitude: Double(data["latitude"]!)!, longitude: Double(data["longitude"]!)!)
            self.camera = GMSCameraPosition.camera(withTarget: location, zoom: 15.0)
            
            self.myMapView.animate(to: self.camera)
            
            self.getRoutes(waypoints: data["waypoints"]!)
        }
        
    }
    
    func getRoutes(waypoints: String)  {
        
        var req = "http://maps.googleapis.com/maps/api/directions/json?origin=\(Global.shared.locations.latitude),\(Global.shared.locations.longitude)&waypoints=\(Global.shared.locations.latitude),\(Global.shared.locations.longitude)&destination=\(self.latitude),\(self.longitude)&sensor=false&mode=driving"

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
                if let resultJsons = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:Any] {
                    print("======Result =====",resultJsons)
                    
                    
                    if let routes = resultJsons["routes"] as? [[String : AnyObject]] {
                        if routes.count > 0 {
                            
                            if let legs = routes.first!["legs"] as? [[String : AnyObject]] {
                                let fullPath : GMSMutablePath = GMSMutablePath()
                                
                                for leg in legs {
                                    if let steps = leg["steps"] as? [[String : AnyObject]] {
                                        for step in steps {
                                            self.stepsArray.append(step)
                                            if let polyline = step["polyline"] as? [String : AnyObject] {
                                                if let points = polyline["points"] as? String {
                                                    
                                                    fullPath.appendPath(path: GMSMutablePath(fromEncodedPath: points))
                                                    
                                                    //   let path = GMSPath.init(fromEncodedPath: points!)
                                                }
                                            }
                                        }
                                    }
                                }
                                print(self.stepsArray)
                                
                                //DispatchQueue.main.async {
                                OperationQueue.main.addOperation {
                                    
                                    self.showPath(path: fullPath)
                                }
                            }
                        }
                    }
                }
                
            } catch {
                print("Error ---------> \(error)")
                
            }
            
            }.resume()
    }

    func showPath(path :GMSMutablePath){
        print(path)
        polyline = GMSPolyline(path: path)
        polyline.strokeWidth = 4.0
        polyline.strokeColor = UIColor.black
        polyline.map = myMapView
    }
    
    @IBAction func showHideNightVision(_ sender: UISwitch) {
        if sender.isOn{
            do {
                // Set the map style by passing a valid JSON string.
                let styleURL = Bundle.main.url(forResource: "NightStyle", withExtension: "json")
                myMapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL!)
            } catch {
                NSLog("One or more of the map styles failed to load. \(error)")
            }
        } else {
            do {
                // Set the map style by passing a valid JSON string.
                let styleURL = Bundle.main.url(forResource: "DayStyle", withExtension: "json")
                myMapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL!)
            } catch {
                NSLog("One or more of the map styles failed to load. \(error)")
            }
        }
    }
    
    
    func addBottomSheetView(scrollable: Bool? = true) {
        let bottomSheetVC = ScrollableBottomSheetViewController()
        
        self.addChild(bottomSheetVC)
        self.view.addSubview(bottomSheetVC.view)
        bottomSheetVC.didMove(toParent: self)
        
        let height = view.frame.height
        let width  = view.frame.width
        bottomSheetVC.view.frame = CGRect(x: 0, y: self.view.frame.maxY, width: width, height: height)
    }
    

}

extension ViewController: GMSMapViewDelegate{
    
    /* handles Info Window tap */
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        print("didTapInfoWindowOf")
    }
    
    /* handles Info Window long press */
    func mapView(_ mapView: GMSMapView, didLongPressInfoWindowOf marker: GMSMarker) {
        print("didLongPressInfoWindowOf")
    }
    
    /* set a custom Info Window */
    func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView? {
        let view = UIView(frame: CGRect.init(x: 0, y: 0, width: 200, height: 70))
        view.backgroundColor = UIColor.white
        view.layer.cornerRadius = 6
        
        let lbl1 = UILabel(frame: CGRect.init(x: 8, y: 8, width: view.frame.size.width - 16, height: 15))
        lbl1.text = "Hi there!"
        view.addSubview(lbl1)
        
        let lbl2 = UILabel(frame: CGRect.init(x: lbl1.frame.origin.x, y: lbl1.frame.origin.y + lbl1.frame.size.height + 3, width: view.frame.size.width - 16, height: 15))
        lbl2.text = "I am a custom info window."
        lbl2.font = UIFont.systemFont(ofSize: 14, weight: .light)
        view.addSubview(lbl2)
        
        return view
    }
}

extension GMSMutablePath {
    
    func appendPath(path : GMSPath?) {
        if let path = path {
            for i in 0..<path.count() {
                self.add(path.coordinate(at: i))
            }
        }
    }
}



/*
 OperationQueue.main.addOperation {
 
 // waypoints marker
 var bounds = GMSCoordinateBounds()
 bounds = bounds.includingCoordinate(self.currentLocationMarker.position)
 
 for dic in filteredArray {
 if let dicLocation = dic["geometry"] as? [String:Any] {
 if let data = dicLocation["location"] as? [String:Any] {
 
 let marker1 = GMSMarker()
 marker1.position = CLLocationCoordinate2D(latitude: data["lat"] as! Double, longitude: data["lng"] as! Double)
 marker1.title = dic["name"] as? String ?? ""
 marker1.snippet = dic["vicinity"] as? String ?? ""
 marker1.groundAnchor = CGPoint(x: 0.5, y: 0.5)
 marker1.map = self.mapView
 bounds = bounds.includingCoordinate(marker1.position)
 
 }
 }
 }
 
 
 let update = GMSCameraUpdate.fit(bounds, with: UIEdgeInsets(top: 80, left: 40, bottom: 270, right: 40))
 self.mapView.animate(with: update)
 }
 */
