//
//  ViewController.m
//  BemeStyleVideoRecorder
//
//  Created by Russell Stephens on 7/25/15.
//  Copyright (c) 2015 Russell Stephens. All rights reserved.
//
// Sources
// http://iosdevelopertips.com/device/using-the-proximity-sensor.html


#import "ViewController.h"
#import "LLSimpleCamera.h"
#import <MediaPlayer/MediaPlayer.h>
#import "VideoEntity.h"
#import "AppDelegate.h"

@interface ViewController ()

@property (strong, nonatomic) LLSimpleCamera *camera;
@property (strong, nonatomic) MPMoviePlayerController *moviplayer;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@end

@implementation ViewController
{
    AppDelegate *appDelegate;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    
    // Enabled monitoring of the sensor
    [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
    
    // Set up an observer for proximity changes
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sensorStateChange:)
                                                 name:@"UIDeviceProximityStateDidChangeNotification" object:nil];
    
    // create camera vc
    self.camera = [[LLSimpleCamera alloc] initWithQuality:AVCaptureSessionPresetHigh
                                                 position:CameraPositionBack
                                             videoEnabled:YES];
    
    // read: http://stackoverflow.com/questions/5427656/ios-uiimagepickercontroller-result-image-orientation-after-upload
    // you probably will want to set this to YES, if you are going view the image outside iOS.
    self.camera.fixOrientationAfterCapture = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // start the camera
    [self.camera start];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // stop the camera
    [self.camera stop];
}

#pragma mark - Trigger

- (void)sensorStateChange:(NSNotificationCenter *)notification
{
    if ([[UIDevice currentDevice] proximityState] == YES) {
         NSLog(@"Device is close to user.");
        [self startRecording];
    }
    
    else {
        NSLog(@"Device is ~not~ closer to user.");
        [self stopRecording];
    }
    
}

#pragma mark - Camera Start / Stop
- (void) stopRecording
{
    [self.camera stopRecording:^(LLSimpleCamera *camera, NSURL *outputFileUrl, NSError *error) {
        NSLog(@"Did finish Recording");
        NSLog(@"File Saved to %@", outputFileUrl);
//        VideoViewController *vc = [[VideoViewController alloc] initWithVideoUrl:outputFileUrl];
//        [self.navigationController pushViewController:vc animated:YES];
        [self createVideoEntityWithURL:outputFileUrl];
        
    }];
    
    
    
}

#pragma mark - Core Data

- (void) createVideoEntityWithURL:(NSURL *)url
{
    VideoEntity *videoEntity = [NSEntityDescription insertNewObjectForEntityForName:@"VideoEntity" inManagedObjectContext:appDelegate.managedObjectContext];
    //https://github.com/mattt/FormatterKit
    videoEntity.timestamp = [NSDateFormatter localizedStringFromDate:[NSDate date]
                                                                                  dateStyle:NSDateFormatterShortStyle
                                                                                  timeStyle:NSDateFormatterFullStyle];
    videoEntity.path = [url absoluteString];
    
    [appDelegate saveContext];
    _fetchedResultsController = nil;
    [_tableView reloadData];
}

#pragma mark - MPMoviePlayerController
-(void)doneButtonClick:(NSNotification*)aNotification{
    [_moviplayer stop];
    [_moviplayer.view setHidden:YES];
    [_moviplayer.view removeFromSuperview];
    _moviplayer=nil;
}

- (void) playVideoAtPath:(NSString *)path
{
    _moviplayer =[[MPMoviePlayerController alloc] initWithContentURL:[NSURL URLWithString:path]];
    [_moviplayer prepareToPlay];
    [_moviplayer.view setFrame: self.view.bounds];
    [self.view addSubview: _moviplayer.view];
    _moviplayer.fullscreen = YES;
    _moviplayer.shouldAutoplay = YES;
    _moviplayer.repeatMode = MPMovieRepeatModeNone;
    _moviplayer.movieSourceType = MPMovieSourceTypeFile;
    
    [_moviplayer play];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(doneButtonClick:)
                                                 name:MPMoviePlayerWillExitFullscreenNotification
                                               object:nil];
}
- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                   inDomains:NSUserDomainMask] lastObject];
}

- (NSString *)videoFileName
{
    return [NSString stringWithFormat:@"bemeStyleVideo%li",[[self fetchedResultsController].fetchedObjects count]];
}
- (void) startRecording
{
    NSURL *outputURL = [[[self applicationDocumentsDirectory]
                         URLByAppendingPathComponent:[self videoFileName]] URLByAppendingPathExtension:@"mov"];
    [self.camera startRecordingWithOutputUrl:outputURL];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table View Methods

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self fetchedResultsController].fetchedObjects count];
}

- (VideoEntity *)videoEntityAtIndexPath:(NSIndexPath *)indexPath
{
    return [[self fetchedResultsController].fetchedObjects objectAtIndex:indexPath.row];
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    
    VideoEntity *videoEntity = [self videoEntityAtIndexPath:indexPath];
    cell.textLabel.text = videoEntity.timestamp;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    VideoEntity *videoEntity = [self videoEntityAtIndexPath:indexPath];
    [self playVideoAtPath:videoEntity.path];
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        VideoEntity *videoEntity = [self videoEntityAtIndexPath:indexPath];
        [appDelegate.managedObjectContext deleteObject:videoEntity];
        _fetchedResultsController = nil;
        [_tableView reloadData];
    }
}
#pragma mark - Fetched Results Controller

-(NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"VideoEntity" inManagedObjectContext:[appDelegate managedObjectContext]];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObjects:sortDescriptor, nil];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:appDelegate.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    
//    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _fetchedResultsController;
    
}
@end
