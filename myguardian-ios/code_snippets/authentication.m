// Simply get the text content from the login fields
NSString *login = _loginField.text;
NSString *password = _passwordField.text;

// Create a POST request to the authentication URL
// This is actually quite pointless as the hub
// authenticates each and every request via basic
// auth but still. This SHOULD also be a POST
// request with a JSON payload, NOT URL params but
// there you go
[[[RKObjectManager sharedManager] HTTPClient] postPath:[NSString stringWithFormat:@"applications/myGuardian/authenticateUser?username=%@&password=%@", login, password]
                                            parameters:nil
                                               success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                   // This is the success block, however the hub is quite
                                                   // strange, and even if the server sends a 200 response,
                                                   // the JSON body may actually describe an error, so we
                                                   // need to test this. The hub SHOULD be returning all
                                                   // errors with a 4xx status, NOT a 2xx!
                                                   NSDictionary *response = (NSDictionary *)responseObject;
                                                   NSString *result = [[response objectForKey:@"results"] lowercaseString];
                                                   
                                                   if ([result isEqualToString:@"authentication successful"]) {
                                                       // This actually was a successful authentication
                                                       // so we'll set the authentication header to the
                                                       // username and password
                                                       NSString *header = [[MGRestKitManager sharedInstance] updateAuthenticationHeaderWithUsername:login
                                                                                                                                           password:password];

                                                       // Now, because the authentication request is half
                                                       // pointless, it also doesn't return any information
                                                       // SOOO we need to make a second request to fetch
                                                       // the current users details.
                                                       [[RKObjectManager sharedManager] getObject:nil
                                                                                             path:[NSString stringWithFormat:@"applications/myGuardian/users/%@", login]
                                                                                       parameters:nil
                                                                                          success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                                                                              // Once that has succeeded, we'll save the user and
                                                                                              // mark them as logged in. We'll also keep track of
                                                                                              // the auth header, as we need it later. Unfortunately,
                                                                                              // this is quite a horrible security risk, as we are
                                                                                              // just storing the username and password in base64
                                                                                              // encoding, but we have to do this in order to auth
                                                                                              // with the hub.
                                                                                              User *loggedIn = mappingResult.firstObject;
                                                                                              loggedIn.loggedIn = @YES;
                                                                                              loggedIn.authHeader = header;
                                                                                              // Save this user to the data store
                                                                                              [[MGRestKitManager sharedInstance] saveChangesToStore];
                                                                                              
                                                                                              // Find out if we've got a device token waiting to 
                                                                                              // be registered. If there is, then we'll register
                                                                                              // it, however we won't wait to see if it fails as
                                                                                              // it's not important enough to cancel the login.
                                                                                              NSString *currentDeviceToken = [[MGSettings sharedSettings] currentDeviceToken];
                                                                                              if (currentDeviceToken && currentDeviceToken.length > 0) {
                                                                                                  [loggedIn registerNewDeviceWithToken:currentDeviceToken];
                                                                                              }
                                                                                             
                                                                                              // Notify listeners that a user has logged in
                                                                                              [MGNotifications userLoggedIn];
                                                                                          } failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                                                                              // Fetching the users details failed, so present an error
                                                                                              [self showLoginError:[MGFlexeyeConfig flexeyeErrorMessage:error]];
                                                                                          }];
                                                   } else {
                                                       // Nope, something failed, so display an error
                                                       [self showLoginError:@"Invalid username or password. Please try again"];
                                                   }
                                                   [SVProgressHUD dismiss];
                                               } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                   // The authentication request failed, so we simply
                                                   // display an error with a message explaining this
                                                   [self showLoginError:[MGFlexeyeConfig flexeyeErrorMessage:error]];
                                                   [SVProgressHUD dismiss];
                                               }];
