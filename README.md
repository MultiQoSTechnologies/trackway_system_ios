# TrackWay System 
 

![screenshot](https://firebasestorage.googleapis.com/v0/b/deliveryapp-62ea4.appspot.com/o/ss1.png?alt=media&token=a47a46d1-5758-4bd6-9c31-a61ae87afb2c)

![screenshot](https://firebasestorage.googleapis.com/v0/b/deliveryapp-62ea4.appspot.com/o/ss2.png?alt=media&token=9022c52a-a1db-4e2b-8b71-bc83a0accf18)


[Watch Video](https://firebasestorage.googleapis.com/v0/b/deliveryapp-62ea4.appspot.com/o/TrackWay%20System.mp4?alt=media&token=aba722a3-3ab7-4b50-b755-3cf263026bd9)

## About
TrackWay is the ultimate solution for precise driver and user location tracking.  

Seamlessly connecting drivers and users, the system streamlines transportation experiences with advanced tracking.  
 
Whether you are a driver optimizing your  routes or a user impatiently  waiting for your journey, TrackWay guarantees effortless and enhanced safety. 

With real-time updates and intuitive features, TrackWay redefines transportation convenience and reliability.  
 

## Key Features

* **Login:**
  - Users have the option to log in either as a driver or as a customer.

* **Request Ride:**
  - Customer can place a request for a new ride.
  - Nearby drivers will receive the request.

* **Driver Actions:**
  - Drivers can choose to accept or reject a ride.
  - If one driver rejects the request, it will be forwarded to the next driver.
  - If no driver accepts the ride, it will be canceled.

* **Ride Completion:**
  - Once a ride is accepted, the driver can move to the customer and reach the destination.
  - The driver can then complete the ride.

## Technology Used

* Swift
* UIKit
* Google Maps
* FirebaseFirestore
* FirebaseRemoteConfig

## How To Use

To clone and run this application, you'll need [Git](https://git-scm.com) and the latest [XCode](https://developer.apple.com/xcode/) installed on your computer, as well as a [Firebase](https://firebase.google.com/) account.

* Clone the project and navigate to the project directory in the terminal.
* Install the pods.
* Create a project in the Firebase console and obtain a Google-info.plist file, then place it in the project.
* Enable Email/Password login in Firebase authentication.
* In Firebase Remote Config, add the following configurations:
  - `NEARBY_DRIVER_SEARCH_RADIUS`: 10000 (In meters) - This tells to find a driver within this radius only.
  - `REQUEST_INTERVAL_FOR_DRIVER`: 20 (In seconds) - This specifies how long one request stays with one driver.
* In the Google Cloud Console from Firebase, obtain the map key and replace it in the AppDelegate as shown below:

![screenshot](https://firebasestorage.googleapis.com/v0/b/deliveryapp-62ea4.appspot.com/o/Screenshot%202024-02-21%20at%2012.43.54%E2%80%AFPM.png?alt=media&token=77148c1e-a5b1-4c21-b7f5-a0f5e0834bf8)

* Voila! You are good to run this project.
