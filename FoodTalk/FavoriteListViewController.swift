//
//  FavoriteListViewController.swift
//  FoodTalk
//
//  Created by Eric Hong on 4/19/16.
//  Copyright © 2016 EricDHong. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData

func calculateDistanceBetweenTwoLocations(source:CLLocation, destination:CLLocation) -> Double {
    let distanceMeters = source.distanceFromLocation(destination)
    let distanceKM = distanceMeters / 1000.0
    return distanceKM
}

extension Restaurant {
    func distance(from: CLLocation)->Double {
        return calculateDistanceBetweenTwoLocations(from, destination: CLLocation(latitude: Double(latitude!), longitude: Double(longitude!)))
    }
    
    func rating()->Int {
        let numVisits = (visits?.count)!
        if(numVisits == 0) {
            return 0
        }
        var Rating = 0.0
        for i in 0...numVisits-1 {
            Rating += Double((visits?.allObjects[i] as! Visit).rating!)
        }
        Rating = round(2 * Rating/Double(numVisits))
        return Int(Rating)
    }
}

class FavoriteListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate,CLLocationManagerDelegate {
    
   
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var sortingSegmentedControl: UISegmentedControl!
    
    let locationManager = CLLocationManager()
    var location = CLLocation()
    var restaurants = [Restaurant]()
    var r : Restaurant!
    let predicate = NSPredicate()
    let resDemo1 = restaurantDescriptor()
    let resDemo2 = restaurantDescriptor()
    
    let resDemo3 = restaurantDescriptor()
    let visit1 = visitDescriptor()
    let visit2 = visitDescriptor()
    let visit3 = visitDescriptor()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        let dateFormatter = NSDateFormatter()
        
        dateFormatter.dateFormat = "yyyy-MM-dd" //  "yyyy-MM-dd HH:mm:ss ZZZ"
        
        resDemo1.name =      "Farmhouse Kitchen"
        resDemo1.address =   "710 Florida St"
        resDemo1.city =      "San Francisco"
        resDemo1.state =     "CA"
        resDemo1.country =   "United States"
        resDemo1.type =      "Thai"
        resDemo1.latitude =   37.7602175
        resDemo1.longitude = -122.4112856
        resDemo1.date = dateFormatter.dateFromString("2016-01-14")!
        
        resDemo2.name =      "Chez Panisse"
        resDemo2.address =   "1517 Shattuck Ave"
        resDemo2.city =      "Berkeley"
        resDemo2.state =     "CA"
        resDemo2.country =   "United States"
        resDemo2.type =      "Californian"
        resDemo1.latitude =   37.8795896
        resDemo1.longitude = -122.2711532
        resDemo2.date = dateFormatter.dateFromString("2015-01-20")!
        
        resDemo3.name =      "Flour + Water"
        resDemo3.address =   "2401 Harrison St"
        resDemo3.city =      "San Francisco"
        resDemo3.state =     "CA"
        resDemo3.country =   "United States"
        resDemo3.type =      "Italian"
        resDemo1.latitude =   37.7589424
        resDemo1.longitude = -122.414457
        resDemo3.date = dateFormatter.dateFromString("2016-05-02")!
        
        
        visit1.date = dateFormatter.dateFromString("2016-01-14")
        visit1.favoriteDishes = ""
        visit1.notes = "It is always fun to be here and watch Lætitia drinking coco water."
        visit1.rating = 4.5
        
        visit2.date = dateFormatter.dateFromString("2016-02-05")
        visit2.favoriteDishes = ""
        visit2.notes = "We wanted to show my mom Lætitia's favorite restaurant, she usually eats very well here."
        visit2.rating = 4.5
        
        visit3.date = dateFormatter.dateFromString("2016-04-13")
        visit3.favoriteDishes = ""
        visit3.rating = 4
        visit3.notes = "I loved the vibe of the restaurant with Thai new year decorations. All the dishes looked fantastic!  We had great fun..."

        title = "Favorites"
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestLocation()
        }
        
        self.restaurants = sortedVisitedRestaurants()
        self.tableView.reloadData()
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        let alert = UIAlertController(title: "Alert", message: "You must enable location services to get search results", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "ok", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last!
        locationManager.stopUpdatingLocation()
    }
    
    func closeEnough(candidate: Restaurant) -> Bool {
        let dest =  CLLocation(latitude: Double(candidate.latitude!),longitude: Double(candidate.longitude!))

        let distance = calculateDistanceBetweenTwoLocations(self.location, destination: dest)
        
        return distance <= 0.2
    }
    
    
    @IBAction func indexChanged(sender: UISegmentedControl){
        
        switch  sender.selectedSegmentIndex {
        case 0:
            self.restaurants = sortedVisitedRestaurants()
        case 1:
            self.restaurants = sortedRatedRestaurant()
        case 2:
            self.restaurants = sortedDistanceRestaurants(location)
        default:
            self.restaurants = sortedVisitedRestaurants()
            break
            
        }
        self.tableView.reloadData()
    }
    
   func sortedVisitedRestaurants()->[Restaurant] {
        let request = CDM.makeRequest("Restaurant")
        let sort = NSSortDescriptor(key:"date", ascending: false)
        request.sortDescriptors = [sort]

        do {
            let results = try moc.executeFetchRequest(request)
            self.restaurants = results  as! [Restaurant]
        } catch {
            let fetchError = error as NSError
            print(fetchError)
        }
    
        return self.restaurants
    }
    
    
    func sortedRatedRestaurant()->[Restaurant]{
        let request = CDM.makeRequest("Restaurant")
        
        do {
            let results = try moc.executeFetchRequest(request)
            self.restaurants = (results as! [Restaurant]).sort({ r1, r2 in r1.rating() > r2.rating() })
        } catch {
            let fetchError = error as NSError
            print(fetchError)
        }
        
        return self.restaurants
    }

    
    func sortedDistanceRestaurants(location:CLLocation)-> [Restaurant] {
       let request = CDM.makeRequest("Restaurant")

        do {
            let results = try moc.executeFetchRequest(request)
            self.restaurants = (results as! [Restaurant]).sort({ r1, r2 in r1.distance(self.location) < r2.distance(self.location) })
        } catch {
            let fetchError = error as NSError
            print(fetchError)
        }

        return self.restaurants
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.restaurants.count == 0  {
             CDM.addRestaurant(resDemo1, presentViewController: self)
             CDM.addRestaurant(resDemo2, presentViewController: self)
             CDM.addRestaurant(resDemo3, presentViewController: self)
             let r = CDM.findRestaurant(resDemo1)! as Restaurant
             CDM.addVisit(r, descr: visit1)
             CDM.addVisit(r, descr: visit2)
             CDM.addVisit(r, descr: visit3)
             self.restaurants = sortedVisitedRestaurants()
        }
        
        return self.restaurants.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("favoriteCell", forIndexPath: indexPath) as! FavoriteListCell
        let restaurant = self.restaurants[indexPath.row]
        self.r = restaurant
        cell.restaurant = restaurant
        cell.nameOfRestaurant.text = r.name
        cell.typeLabel.text = r.type
        cell.addressTextView.text = r.address! + "\n" + r.city! + ", " + r.state! + "\n" + String(format: "%.2f", r.distance(self.location)) + " km"

        let stars = ["0 Stars", "1 Star", "2 Stars", "3 Stars", "4 Stars", "5 Stars", "6 Stars", "7 Stars", "8 Stars", "9 Stars", "10 Stars"]
        cell.myRatingImage.image = UIImage(named: stars[restaurant.rating()])
        cell.numRatings.text = "(\(restaurant.visits!.count))"
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let restaurant = self.restaurants[indexPath.row]

        // TODO: These heights shouldn't be hardcoded
        if (restaurant.visits?.count == 0) {
            return 60
        }
        return 200
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let indexPath = tableView.indexPathForCell(sender as! UITableViewCell)
        r = self.restaurants[indexPath!.row]
        
        let enumerator = self.r.visits?.objectEnumerator()
               while let myVisit = enumerator!.nextObject() as! Visit? {
                    print(myVisit.notes)
        }
        
        let vc = segue.destinationViewController as! FavoriteListDetails
        vc.r = r
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
