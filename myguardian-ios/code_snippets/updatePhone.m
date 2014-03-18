// Get the values of the new phone number and
// the confirmation of the number
NSString *newPhone = _updatedPhone.text;
NSString *confirmPhone = _confirmPhone.text;

// Make sure that both fields have been given
// a value. We don't need to test if they're
// numbers, as the fields are configured to
// show a keyboard that only has numbers.
if (newPhone.length == 0 || confirmPhone.length == 0) {
    UIAlertView *error = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:@"You must enter all fields"
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil, nil];
    [error show];

// The fields were both populated, so make
// sure that the confirmation matches the
// number
} else if (![newPhone isEqualToString:confirmPhone]) {
    // It doesn't, so inform the user of this problem
    UIAlertView *error = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:@"Your new password does not match the confirmation"
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil, nil];
    [error show];
} else {
    // Everything is ready, so we display the udpating
    // overlay, retrieve the currently logged in user
    // object, and change the phone number property.
    [SVProgressHUD showWithStatus:@"Updating Phone..." maskType:SVProgressHUDMaskTypeGradient];
    User *user = [User loggedInUser];
    user.phone = newPhone;
    
    // Now we make a simple PUT request to updated the
    // user. RestKit will automatically map the properties
    // for the request.
    [[RKObjectManager sharedManager] putObject:user
                                          path:nil
                                    parameters:nil
                                       success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                           // The user has now been udpated, so we hide
                                           // the loading overlay, save the changes to
                                           // our local data store, and go back to the 
                                           // previous view
                                           [SVProgressHUD dismiss];
                                           [[MGRestKitManager sharedInstance] saveChangesToStore];
                                           [self.navigationController popViewControllerAnimated:YES];
                                       } failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                           // The udpate failed, so display an error 
                                           // message describing the situation.
                                           UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                                           message:[MGFlexeyeConfig flexeyeErrorMessage:error]
                                                                                          delegate:nil
                                                                                 cancelButtonTitle:@"OK"
                                                                                 otherButtonTitles:nil, nil];
                                           [alert show];
                                           [SVProgressHUD dismiss];
                                       }];
