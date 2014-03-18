// Display a loading overlay
[SVProgressHUD showWithStatus:@"Loading Locations" maskType:SVProgressHUDMaskTypeGradient];
// Again this is a POST request due to the design
// fault in the hub, and will be rectified later
[[RKObjectManager sharedManager] postObject:nil
                                       path:@"searchLocationsNotNull"
                                 parameters:nil
                                    success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                        // The locations have been downloaded. Now we
                                        // hide the loading overlay and hide the `pull
                                        // to refresh` spinner
                                        [SVProgressHUD dismiss];
                                        [_refreshControl endRefreshing];
                                    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                        // The request failed, so we just display a
                                        // message to the use
                                        [SVProgressHUD dismiss];
                                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                                        message:[MGErrorHandler generateErrorMessageFromError:error]
                                                                                       delegate:nil
                                                                              cancelButtonTitle:@"OK"
                                                                              otherButtonTitles:nil, nil];
                                        [alert show];
                                        [_refreshControl endRefreshing];
                                        [SVProgressHUD dismiss];
                                    }];