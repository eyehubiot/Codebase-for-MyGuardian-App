// Present a loading overlay
[SVProgressHUD showWithStatus:@"Inviting Trustee" maskType:SVProgressHUDMaskTypeGradient];

// Prepare our path for the request. Once again,
// the hub is ignoring RESTful design, and forcing
// me to provide the personId as a URL parameter
// rather than a JSON payload.
NSString *path = [NSString stringWithFormat:@"applications/myGuardian/users/%@/addTrustee?personId=%@", [[User loggedInUser] userID], [user userID]];

// Unfortunately, because of the hub being awkward, we
// can't let Restkit do its magic so must manually call
// the underlying HTTP client.
AFHTTPClient *client = [[RKObjectManager sharedManager] HTTPClient];
client.parameterEncoding = AFJSONParameterEncoding;
[client postPath:path
      parameters:nil
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             // Once again, the server might have returned an error
             // with a 200 response so we check this
             [SVProgressHUD dismiss];
             NSDictionary *response = (NSDictionary *)responseObject;

             if ([[[response objectForKey:@"results"] lowercaseString] hasPrefix:@"false"]) {
                 // This actually failed so we display an error message
                 // to the user.
                 NSString *message = [[response objectForKey:@"results"] stringByReplacingOccurrencesOfString:@"False: " withString:@""];
                 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                 message:message
                                                                delegate:nil
                                                       cancelButtonTitle:@"Done"
                                                       otherButtonTitles:nil, nil];
                 [alert show];
             } else {
                 // The invitation was successful, so we show
                 // an alert informing the user of this.
                 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success"
                                                                 message:@"The trustee has been invited. They will appear in this list if they accept your invitation"
                                                                delegate:nil
                                                       cancelButtonTitle:@"Done"
                                                       otherButtonTitles:nil, nil];
                 [alert show];
             }
             
             [self dismissViewControllerAnimated:YES completion:nil];
         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             // Something actually went wrong here,
             // so we'll display an error
             [SVProgressHUD dismiss];
             UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                             message:[MGErrorHandler generateErrorMessageFromError:error]
                                                            delegate:nil
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil, nil];
             [alert show];
         }];