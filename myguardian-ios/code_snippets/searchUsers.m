// POST request to get a list of users. Again this should
// be a GET request and will be fixed at a later point
[[RKObjectManager sharedManager] postObject:nil
                                       path:@"applications/myGuardian/searchUsers"
                                 parameters:nil
                                    success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                        // The users were successfully retrieved.
                                        // Now dismiss the overlay
                                        [SVProgressHUD dismiss];
                                        [refresh endRefreshing];
                                    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                        // The request failed, so hide the overlay
                                        // and display an error to the user
                                        [SVProgressHUD dismiss];
                                        [refresh endRefreshing];
                                        UIAlertView *errorView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                                            message:[MGFlexeyeConfig flexeyeErrorMessage:error]
                                                                                           delegate:nil
                                                                                  cancelButtonTitle:@"OK"
                                                                                  otherButtonTitles:nil, nil];
                                        [errorView show];
                                    }];