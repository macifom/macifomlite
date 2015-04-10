//
//  NESROMListController.m
//  macifomlite
//
//  Created by Auston Stewart on 4/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NESROMListController.h"
#import "macifomliteAppDelegate.h"

@implementation NESROMListController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [_roms release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    NSArray *romURLs;
    NSURL *documentsURL;
    id resourceValue;
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    NSArray* possibleURLs = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    if (possibleURLs > 0) {
        
        documentsURL = (NSURL *)[possibleURLs objectAtIndex:0];
        romURLs = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:documentsURL includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLNameKey,NSURLIsRegularFileKey,NSURLIsReadableKey,nil] options:NSDirectoryEnumerationSkipsHiddenFiles error:NULL];
    }
    else romURLs = [NSArray array];
    
    [_roms release];
    _roms = [[NSMutableArray alloc] initWithCapacity:100];
    
    for (NSURL *romURL in romURLs) {
        
        // Filter out non-regular files
        if (![romURL getResourceValue:&resourceValue forKey:NSURLIsRegularFileKey error:NULL] || ![(NSNumber *)resourceValue boolValue]) continue;
        
        // Filter out unreadable files
        if (![romURL getResourceValue:&resourceValue forKey:NSURLIsReadableKey error:NULL] || ![(NSNumber *)resourceValue boolValue]) continue;
        
        if ([[romURL pathExtension] isEqualToString:@"nes"]) {
            
            if ([romURL getResourceValue:&resourceValue forKey:NSURLNameKey error:NULL]) 
                [_roms addObject:[NSDictionary dictionaryWithObjectsAndKeys:[romURL path],@"path",[resourceValue copy],@"title",nil]];
        }
    }
    
    // _roms = [[[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Configuration" ofType:@"plist"]] objectForKey:@"roms"] retain];
    
    [self.tableView reloadData];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_roms) return [_roms count];
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"RomCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
    cell.textLabel.text = [[_roms objectAtIndex:indexPath.row] objectForKey:@"title"];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    [(macifomliteAppDelegate *)[[UIApplication sharedApplication] delegate] loadROM:[[_roms objectAtIndex:indexPath.row] objectForKey:@"path"]];
}

@end
