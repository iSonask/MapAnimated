import UIKit
import MapKit


class AppleMapController: UIViewController,MKMapViewDelegate,MKLocalSearchCompleterDelegate {
    
    var mapView: MKMapView?
    var camera = MKMapCamera()
    
    lazy var searchCompleter: MKLocalSearchCompleter = {
        let sC = MKLocalSearchCompleter()
        sC.delegate = self
        return sC
    }()
    
    var searchSource: [String]?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView = MKMapView(frame: view.bounds)
        view.addSubview(mapView!)
        camera = MKMapCamera(lookingAtCenter: Global.shared.locations, fromEyeCoordinate: Global.shared.locations, eyeAltitude: 400.0)
        mapView?.camera = camera
        mapView?.delegate = self
        mapView?.showsUserLocation = true
        NotificationCenter.default.addObserver(self, selector: #selector(changeLocation), name: NSNotification.Name(rawValue: "handleNewNotification"), object: nil)
        searchCompleter.queryFragment = "garden"
    }
    
    let destination = CLLocationCoordinate2D(latitude: 18.5204, longitude: 73.8567)

    @objc func changeLocation()  {
        camera = MKMapCamera(lookingAtCenter: Global.shared.locations, fromEyeCoordinate: Global.shared.locations, eyeAltitude: 400.0)
        showRouteOnMap(pickupCoordinate: Global.shared.locations, destinationCoordinate: destination)

        mapView?.setCamera(camera, animated: true)
    }
    func showRouteOnMap(pickupCoordinate: CLLocationCoordinate2D, destinationCoordinate: CLLocationCoordinate2D) {
        
        let sourcePlacemark = MKPlacemark(coordinate: pickupCoordinate, addressDictionary: nil)
        let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate, addressDictionary: nil)
        
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
        
        let sourceAnnotation = MKPointAnnotation()
        
        if let location = sourcePlacemark.location {
            sourceAnnotation.coordinate = location.coordinate
        }
        
        let destinationAnnotation = MKPointAnnotation()
        
        if let location = destinationPlacemark.location {
            destinationAnnotation.coordinate = location.coordinate
        }
        
        self.mapView!.showAnnotations([destinationAnnotation], animated: true )
        
        let directionRequest = MKDirections.Request()
        directionRequest.source = sourceMapItem
        directionRequest.destination = destinationMapItem
        directionRequest.transportType = .automobile
        
        // Calculate the direction
        let directions = MKDirections(request: directionRequest)
        
        directions.calculate {
            (response, error) -> Void in
            
            guard let response = response else {
                if let error = error {
                    print("Error: \(error)")
                }
                
                return
            }
            
            let route = response.routes[0]
            
            self.mapView!.addOverlay((route.polyline), level: MKOverlayLevel.aboveLabels)
            
            let rect = route.polyline.boundingMapRect
            self.mapView!.setRegion(MKCoordinateRegion(rect), animated: true)
        }
    }
    //https://github.com/gm6379/MapKitAutocomplete
    //https://stackoverflow.com/questions/33380711/how-to-implement-auto-complete-for-address-using-apple-map-kit
    //https://stackoverflow.com/questions/29319643/how-to-draw-a-route-between-two-locations-using-mapkit-in-swift
    //https://stackoverflow.com/questions/27558912/draw-polyline-using-swift
    // MARK: - MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        let renderer = MKPolylineRenderer(overlay: overlay)
        
        renderer.strokeColor = UIColor(red: 17.0/255.0, green: 147.0/255.0, blue: 255.0/255.0, alpha: 1)
        
        renderer.lineWidth = 5.0
        
        return renderer
    }

    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        //get result, transform it to our needs and fill our dataSource
//        let subtitle = completer.results.map { $0.subtitle}
//        let value = completer.results.map { $0.titleHighlightRanges}
//        print(completer.results)
//        print(subtitle,value)
        self.searchSource = completer.results.map { $0.title }
        print(searchSource!)
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        //handle the error
        print(error.localizedDescription)
    }
    

}
