// Build up our path ready to request the notifications
NSString *path = [NSString stringWithFormat:@"applications/myGuardian/users/%@/searchNotifications", [[User loggedInUser] userID]];

// Currently we must POST instead of GET due to 
// a design fault in the hub. This will be fixed
// eventually
[[RKObjectManager sharedManager] postObject:nil
                                       path:path
                                 parameters:nil
                                    success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                        // This worked, so we retrieve the list of notifications
                                        // from the mapping result. This mapping is calculated
                                        // for us by RestKit, which automatically maps the JSON
                                        // response into an array of Notification objects. Very
                                        // clever!
                                        NSSet *allNotifications = mappingResult.set;

                                        // Join the notifications to our current user in our
                                        // data store
                                        User *user = [User loggedInUser];
                                        [allNotifications makeObjectsPerformSelector:@selector(setUser:) withObject:user];
                                        [user setNotifications:allNotifications];
                                        [[MGRestKitManager sharedInstance] saveChangesToStore];
                                        [SVProgressHUD dismiss];
                                        [refresh endRefreshing];
                                    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                        // There was an error, so display the error to the user
                                        [SVProgressHUD dismiss];
                                        [refresh endRefreshing];
                                        UIAlertView *errorView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                                            message:[MGFlexeyeConfig flexeyeErrorMessage:error]
                                                                                           delegate:nil
                                                                                  cancelButtonTitle:@"OK"
                                                                                  otherButtonTitles:nil, nil];
                                        [errorView show];
                                    }];

// Refresh the table view so that the notifications
// can be seen
[_notificationsTableView reloadData];