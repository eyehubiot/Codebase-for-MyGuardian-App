// Inform the user that we're registering
// This displays a simple ovelay with a loading
// spinner with a message.
[SVProgressHUD showWithStatus:@"Registering" maskType:SVProgressHUDMaskTypeGradient];

// Creates a new user object locally, which will
// also be inserted into the core data store, but
// not persisted
User *newUser = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:[[RKManagedObjectStore defaultStore] mainQueueManagedObjectContext]];

// Assigns all the properties to the user
// ready for posting to the server
newUser.forename = forename;
newUser.surname = surname;
newUser.email = email;
newUser.phone = phone;
newUser.username = login;
newUser.password = password;
newUser.userID = login;


// Performs a POST request to the server with
// the newly created user object. We don't supply
// any parameters here, as RestKit will automatically
// map the keys and values in the user object
// into a JSON payload
[[RKObjectManager sharedManager] postObject:newUser
	                                   path:nil
	                             parameters:nil
	                                success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
	                                	// This block is called when the request succeeds.
	                                	// This dismisses the loading overlay created previously,
	                                	// and then marks the users as logged in. The users
	                                	// username and password is then set as the HTTP basic
	                                	// auth header for future requests, and a notification
	                                	// is broadcast across the app that the user has
	                                	// now logged in. (that causes the registration screen
	                                	// to be dismissed)
	                                    [SVProgressHUD dismiss];
	                                    newUser.loggedIn = @YES;
	                                    [[MGRestKitManager sharedInstance] updateAuthenticationHeaderWithUsername:newUser.username password:newUser.password];
	                                    [[MGRestKitManager sharedInstance] saveChangesToStore];
	                                    [MGNotifications userLoggedIn];
	                                } failure:^(RKObjectRequestOperation *operation, NSError *error) {
	                                	// This block is called when the request fails. Again, 
	                                	// the loading overlay is dismissed, and then an error
	                                	// message alert is displayed. 
	                                    [SVProgressHUD dismiss];
	                                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
	                                                                                    message:[MGFlexeyeConfig flexeyeErrorMessage:error]
	                                                                                   delegate:nil
	                                                                          cancelButtonTitle:@"OK"
	                                                                          otherButtonTitles:nil, nil];
	                                    [alert show];

	                                    // After showing the error, we remove the new user
	                                    // object is removed from the Core Data store and then
	                                    // the core data store is saved.
	                                    [[[RKManagedObjectStore defaultStore] mainQueueManagedObjectContext] deleteObject:newUser];
	                                    [[MGRestKitManager sharedInstance] saveChangesToStore];
	                                }];