- (void) startTripAt:(NSDate *)startTime withCompletion:(void (^)(Timer *timer, NSError *error))completion
{
    // Make sure that the trip is valid before continuing
    if ([self isTripValid]) {
        // Create a new timer object locally in preparation.
        // Then set the properties needed, inclusive of the
        // notifications that the hub should send automatically.
        RKManagedObjectStore *objectStore = [[RKObjectManager sharedManager] managedObjectStore];
        Timer *timer = [NSEntityDescription insertNewObjectForEntityForName:@"Timer" inManagedObjectContext:objectStore.mainQueueManagedObjectContext];
        timer.startTime = startTime;
        timer.userID = [[User loggedInUser] userID];
        timer.doPauseNotify = @YES;
        timer.doStartNotify = @YES;
        timer.doStopNotify = @YES;

        // If a default trustee has been set, then set this
        // on the timer object
        if (_defaultTrustee) {
            timer.defaultTrusteeID = _defaultTrustee.userID;
        }
        
        // If the timer planner (this class) has been 
        // configured to use the current location, then
        // we need to create a new location object on
        // the hub for us to use
        if (_useCurrentLocation) {
            // Create a new location locally ready to be saved
            // and assign a latitude and longitude. We'll mark
            // it as hidden just for our reference, this is not
            // submit
            Location *origin = [NSEntityDescription insertNewObjectForEntityForName:@"Location" inManagedObjectContext:[[RKManagedObjectStore defaultStore] mainQueueManagedObjectContext]];
            origin.lat = [NSNumber numberWithDouble:_currentLocation.latitude];
            origin.lon = [NSNumber numberWithDouble:_currentLocation.longitude];
            origin.hidden = @YES;

            // POST the new location to the server
            [[RKObjectManager sharedManager] postObject:origin
                                                   path:nil
                                             parameters:nil
                                                success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                                    // Now that it's been created, we need to save
                                                    // it. Once it's saved, we can create the timer
                                                    Location *startLocation = mappingResult.firstObject;
                                                    timer.startLocation = startLocation;
                                                    timer.startLocationID = startLocation.objID;
                                                    [self configureTimer:timer andStartWithCompletion:^(Timer *t, NSError *e) {
                                                        if (e) {
                                                            // The timer creation had an error, so 
                                                            // we need to remove the timer from our
                                                            // local store.
                                                            [[[RKManagedObjectStore defaultStore] mainQueueManagedObjectContext] deleteObject:timer];
                                                        }
                                                        
                                                        // Call the completion handler
                                                        completion(t, e);
                                                    }];
                                                } failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                                    // The creation completely failed, so we'll remove
                                                    // the origin location as we no longer need it, and
                                                    // we'll remove the timer objet
                                                    completion(nil, error);
                                                    [[[RKManagedObjectStore defaultStore] mainQueueManagedObjectContext] deleteObject:origin];
                                                    [[[RKManagedObjectStore defaultStore] mainQueueManagedObjectContext] deleteObject:timer];
                                                }];
        } else {
            // We're not using the current location, so
            // we'll set the start location to the one
            // provided, and then start the timer.
            timer.startLocation = _startLocation;
            timer.startLocationID = _startLocation.objID;
            [self configureTimer:timer andStartWithCompletion:completion];
        }
        
    }
}

- (void) configureTimer:(Timer *)timer andStartWithCompletion:(void (^)(Timer *, NSError *))completion
{
    // We'll mark the destination as a recent location
    // for our own use, and then send all properties
    // needed for our timer.
    _endLocation.recent = @YES;
    timer.endLocation = _endLocation;
    timer.endLocationID = _endLocation.objID;
    timer.duration = [NSNumber numberWithInteger:_durationTime + _extendTime];
    timer.state = @0;
    timer.batteryLevel = [NSNumber numberWithFloat:[MGUtils batteryLevel]];
    
    // POST the timer to the hub
    [[RKObjectManager sharedManager] postObject:timer
                                           path:nil
                                     parameters:nil
                                        success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                            // The timer was successfully created. 
                                            // Here, we join our timer and logged in user
                                            // together in our local core data store.
                                            User *user = [User loggedInUser];
                                            Timer *t = mappingResult.firstObject;
                                            
                                            [user addTimersObject:t];
                                            [t setUser:user];
                                            [[MGRestKitManager sharedInstance] saveChangesToStore];

                                            // Call our completion handler
                                            completion(mappingResult.firstObject, nil);
                                        } failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                            // There was a problem creating the timer, so
                                            // call the completion handler with the error.
                                            completion(nil, error);
                                        }];
}