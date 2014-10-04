//
//  AllAlbumsViewController.m
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 04-10-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import "AllAlbumsViewController.h"
#import "CocoaLibSpotify.h"
#import "MBProgressHud.h"
#import "LoadMoreCell.h"
#import "AlbumCell.h"

@interface AllAlbumsViewController ()

@property (nonatomic, strong) SPSearch *searchResult;

- (void)loadMoreAlbums;
- (AlbumCell *)cellForAlbumAtIndexPath:(NSIndexPath *)indexPath;

@end

@implementation AllAlbumsViewController
@synthesize searchText;

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
        
    //Empty remaining search results
    self.searchResult = nil;
    [self.tableView reloadData];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.tableView animated:YES];
    hud.labelText = @"Loading";
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    SPSearch *search = [[SPSearch alloc] initWithSearchQuery:[self searchText] pageSize:30 inSession:[SPSession sharedSession] type:SP_SEARCH_STANDARD];
    [SPAsyncLoading waitUntilLoaded:search timeout:10.0 then:^(NSArray *loadedItems, NSArray *notLoadedItems)
     {
         //Disable loading HUD
         [MBProgressHUD hideAllHUDsForView:self.tableView animated:YES];
         
         //Check if search wasn't timed out
         if(loadedItems == nil || [loadedItems count] != 1 || ![[loadedItems firstObject] isKindOfClass:[SPSearch class]])
         {
             [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Spotify Alarm Clock wasn't able to perform the search. Is your internet connection still active?" delegate:nil cancelButtonTitle:@"Oke!" otherButtonTitles:nil] show];
             NSLog(@"Search request timedout");
             
             return;
         }
         
         //Set search result and reload table
         self.searchResult = (SPSearch*)[loadedItems firstObject];
         [self.tableView reloadData];
     }];
}

- (void)loadMoreAlbums
{
    //Only load more tracks when searchresult is loaded
    if(self.searchResult == nil || ![self.searchResult isLoaded] || [self.searchResult hasExhaustedAlbumResults])
        return;
    
    [self.searchResult addAlbumPage];
    [SPAsyncLoading waitUntilLoaded:self.searchResult timeout:10.0 then:^(NSArray *loadedItems, NSArray *notLoadedItems)
     {
         if(loadedItems != nil && [loadedItems count] == 1 && [[loadedItems firstObject] isKindOfClass:[SPSearch class]])
             [self.tableView reloadData];
     }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(self.searchResult != nil && [self.searchResult isLoaded])
    {
        if([self.searchResult hasExhaustedAlbumResults])
            return [self.searchResult.albums count];
        else
            return [self.searchResult.albums count] + 1;
    }
    else
        return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //Load more cells
    if([self.searchResult.albums count] - 20 < [indexPath row])
        [self loadMoreAlbums];
    
    //More cells loading
    if([self.searchResult.albums count] == [indexPath row])
    {
        LoadMoreCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"loadingMoreAlbums" forIndexPath:indexPath];
        [cell.spinner startAnimating];
        
        return cell;
    }
    else //Show track
        return [self cellForAlbumAtIndexPath:indexPath];
}

- (AlbumCell *)cellForAlbumAtIndexPath:(NSIndexPath *)indexPath
{
    SPAlbum *album = [self.searchResult.albums objectAtIndex:[indexPath row]];
    
    AlbumCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"albumCell" forIndexPath:indexPath];
    [cell.lbArtist setText:[album.artist name]];
    [cell.lbAlbum setText:[album name]];
    
    if([album.cover isLoaded])
        [cell.albumImage setImage:[album.cover image]];
    else
    {
        [cell.albumImage setImage:[UIImage imageNamed:@"Album"]];
        
        [album.cover startLoading];
        [SPAsyncLoading waitUntilLoaded:album.cover timeout:10.0 then:^(NSArray *loadedItems, NSArray *notLoadedItems)
         {
             if(loadedItems == nil || [loadedItems count] != 1 || ![[loadedItems firstObject] isKindOfClass:[SPImage class]])
                 return;
             
             SPImage *cover = (SPImage*)[loadedItems firstObject];
             
             [cell.albumImage setImage:[cover image]];
         }];
        
    }
    
    [cell.albumImage sizeToFit];
    
    return cell;
}

#pragma mark - UITableView delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([self.searchResult.albums count] == [indexPath row])
        return 40;
    else
        return 75;
}

@end