// Get the old, new, and confirmation passwords
NSString *oldPassword = _oldPassword.text;
NSString *newPassword = _updatedPassword.text;
NSString *confirmPassword = _confirmPassword.text;

// Make sure that all 3 passwords have
// been entered
if (oldPassword.length == 0 || newPassword.length == 0 || confirmPassword.length == 0) {
    UIAlertView *error = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:@"You must enter all fields"
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil, nil];
    [error show];

// If they have, make sure the new password
// and the new password confirmation match
} else if (![newPassword isEqualToString:confirmPassword]) {
    UIAlertView *error = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:@"Your new password does not match the confirmation"
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil, nil];
    [error show];
} else {
    // Passwords match, so show a loading overlay and
    // prepare the path that we will request
    [SVProgressHUD showWithStatus:@"Updating Password..." maskType:SVProgressHUDMaskTypeGradient];
    NSString *userID = [[User loggedInUser] userID];
    NSString *path = [NSString stringWithFormat:@"applications/myGuardian/users/%@/changePassword?oldPassword=%@&newPassword=%@&repeatNewPassword=%@", userID, oldPassword, newPassword, confirmPassword];

    // Once again we must supply the parameters as
    // URL parameters before POSTing.
    [[[RKObjectManager sharedManager] HTTPClient] postPath:path
                                                parameters:nil
                                                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                       // Make sure our 200 response isn't actually an 
                                                       // error
                                                       NSDictionary *result = (NSDictionary *)responseObject;
                                                       if ([[result objectForKey:@"results"] rangeOfString:@"successfully"].location == NSNotFound) {
                                                           // This was actually a failure, so display an
                                                           // error to the user
                                                           UIAlertView *error = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                                                           message:[result objectForKey:@"results"]
                                                                                                          delegate:nil
                                                                                                 cancelButtonTitle:@"OK"
                                                                                                 otherButtonTitles:nil, nil];
                                                           [error show];
                                                       } else {
                                                           // No error, so we'll update the authentication header
                                                           // and go back to the previous view
                                                           [[MGRestKitManager sharedInstance] updateAuthenticationHeaderWithUsername:userID password:newPassword];
                                                           [self.navigationController popViewControllerAnimated:YES];
                                                       }
                                                       [SVProgressHUD dismiss];
                                                   } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                       // Tgere was an error, so display an alert
                                                       // to the user
                                                       [SVProgressHUD dismiss];
                                                       UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                                                       message:[MGFlexeyeConfig flexeyeErrorMessage:error]
                                                                                                      delegate:nil
                                                                                             cancelButtonTitle:@"OK"
                                                                                             otherButtonTitles:nil, nil];
                                                       [alert show];
                                                   }];
}