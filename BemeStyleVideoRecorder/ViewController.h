//
//  ViewController.h
//  BemeStyleVideoRecorder
//
//  Created by Russell Stephens on 7/25/15.
//  Copyright (c) 2015 Russell Stephens. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

