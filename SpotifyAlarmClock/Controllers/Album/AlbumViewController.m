//
//  AlbumViewController.m
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 10-10-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import "AlbumViewController.h"
#import "CocoaLibSpotify.h"
#import "MBProgressHud.h"
#import "UIImage+ImageEffects.h"
#import "UIScrollView+APParallaxHeader.h"
#import "BlurredHeaderView.h"
#import "TrackCell.h"
#import "AlbumCell.h"
#import "SpotifyPlayer.h"
#import "CellConstructHelper.h"

@interface AlbumViewController ()

@property (nonatomic, strong) SPAlbumBrowse *albumBrowse;
@property (nonatomic, assign) bool headerRendered;
@property (nonatomic, strong) BlurredHeaderView *blurredHeaderView;

- (void)loadAlbumBrowse;
- (void)renderAlbumHeader:(UIImage *)cover;

@end

@implementation AlbumViewController
@synthesize album;
@synthesize albumBrowse;
@synthesize blurredHeaderView;
@synthesize headerRendered;


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Register cells
    [self.tableView registerNib:[UINib nibWithNibName:@"TrackCell" bundle:nil] forCellReuseIdentifier:@"trackCell"];
        
    //Load header view from nib
    NSArray* nibViews = [[NSBundle mainBundle] loadNibNamed:@"BlurredHeader" owner:self options:nil];
    blurredHeaderView = [nibViews firstObject];
    
    //Set header to max width
    CGRect frame = blurredHeaderView.frame;
    frame.size.width = self.view.bounds.size.width;
    blurredHeaderView.frame = frame;
    
    //Set default album image
    [blurredHeaderView.image setImage:[UIImage imageNamed:@"Album"]];
    
    //Add parallax header
    [self.tableView addParallaxWithView:blurredHeaderView andHeight:150];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //Set Spotify Player delegate
    [[SpotifyPlayer sharedSpotifyPlayer] setDelegate:self];
    
    //Set artist name
    [self.navigationItem setTitle:[album name]];
    
    //Load and render cover
    [album.cover startLoading];
    [SPAsyncLoading waitUntilLoaded:album.cover timeout:10.0 then:^(NSArray *loadedItems, NSArray *notLoadedItems)
     {
         if(loadedItems == nil || [loadedItems count] != 1 || ![[loadedItems firstObject] isKindOfClass:[SPImage class]])
             return;
         
         SPImage *cover = (SPImage*)[loadedItems firstObject];
         
         [self renderAlbumHeader:[cover image]];
     }];
    
    //Load artist information
    [self loadAlbumBrowse];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[SpotifyPlayer sharedSpotifyPlayer] stopTrack];
}

- (void)loadAlbumBrowse
{
    //Show loading HUD
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.tableView animated:YES];
    hud.labelText = @"Loading";
    
    //Async loading
    albumBrowse = [[SPAlbumBrowse alloc] initWithAlbum:album inSession:[SPSession sharedSession]];
    [SPAsyncLoading waitUntilLoaded:albumBrowse timeout:10.0 then:^(NSArray *loadedItems, NSArray *notLoadedItems)
     {
         //Check if databrowse could be loaded
         if(loadedItems == nil || [loadedItems count] != 1 || ![[loadedItems firstObject] isKindOfClass:[SPAlbumBrowse class]])
         {
             [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Spotify Alarm Clock wasn't able to load the album. Is your internet connection still active?" delegate:nil cancelButtonTitle:@"Oke!" otherButtonTitles:nil] show];
             NSLog(@"Album load time out");
             
             return;
         }
         
         //Disable loading HUD
         [MBProgressHUD hideAllHUDsForView:self.tableView animated:YES];
         
         //Reload table because artist browse was successful
         [self.tableView reloadData];
     }];
}

- (void)renderAlbumHeader:(UIImage*)cover
{
    //Only render header once
    if(headerRendered)
        return;
    
    //Background portrait
    UIImage *blurredImage = [cover applyBlurWithRadius:30 tintColor:[UIColor colorWithWhite:0.25 alpha:0.2] saturationDeltaFactor:1.5 maskImage:nil];
    [UIView transitionWithView:self.blurredHeaderView.backgroundImage
                      duration:0.5f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        [self.blurredHeaderView.backgroundImage setImage:blurredImage];
                    } completion:NULL];
    
    //Portrait
    [UIView transitionWithView:self.blurredHeaderView.image
                      duration:0.5f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        [self.blurredHeaderView.image setImage:cover];
                    } completion:NULL];
    
    headerRendered = true;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    //Hide results as long as no album browse loaded;
    if(albumBrowse == nil || ![albumBrowse isLoaded])
        return 0;
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return[self.albumBrowse.tracks count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [CellConstructHelper tableView:tableView cellForTrack:[self.albumBrowse.tracks objectAtIndex:[indexPath row]] atIndexPath:indexPath];
}

#pragma mark - UITableView delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 55;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

    SPTrack *track = [self.albumBrowse.tracks objectAtIndex:[indexPath row]];
    if([[SpotifyPlayer sharedSpotifyPlayer] currentTrack] == track)
        [[SpotifyPlayer sharedSpotifyPlayer] stopTrack];
    else
        [[SpotifyPlayer sharedSpotifyPlayer] playTrack:track];
}

#pragma mark - Spotify Player delegate

- (void)track:(SPTrack *)track progess:(double) progress
{
    TrackCell *cell = (TrackCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.albumBrowse.tracks indexOfObject:track] inSection:0]];
    [cell setProgress:progress];
}

- (void)trackStartedPlaying:(SPTrack *)track
{
    TrackCell *cell = (TrackCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.albumBrowse.tracks indexOfObject:track] inSection:0]];
    [cell showPlayProgress:YES animated:YES];
}

- (void)trackStoppedPlaying:(SPTrack *)track
{
    TrackCell *cell = (TrackCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.albumBrowse.tracks indexOfObject:track] inSection:0]];
    [cell showPlayProgress:NO animated:YES];
}

@end
