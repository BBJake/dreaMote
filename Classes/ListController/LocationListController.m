//
//  LocationListController.m
//  dreaMote
//
//  Created by Moritz Venn on 01.01.11.
//  Copyright 2011-2012 Moritz Venn. All rights reserved.
//

#import "LocationListController.h"

#import "Constants.h"
#import "RemoteConnectorObject.h"
#import "UITableViewCell+EasyInit.h"

#import "UIPromptView.h"

#import <TableViewCell/BaseTableViewCell.h>

#import <Objects/LocationProtocol.h>
#import <Objects/Generic/Location.h>
#import <Objects/Generic/Result.h>

#import "MBProgressHUD.h"

@interface LocationListController()
/*!
 @brief done editing
 */
- (void)doneAction:(id)sender;
@end

@implementation LocationListController

@synthesize isSplit, showDefault, callback;
@synthesize movieListController = _movieListController;

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Locations", @"Title of LocationListController");
		_locations = [NSMutableArray array];
		_refreshLocations = YES;

		self.contentSizeForViewInPopover = CGSizeMake(370.0f, 450.0f);
		self.modalPresentationStyle = UIModalPresentationFormSheet;
		self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	}
	return self;
}

/* memory warning */
- (void)didReceiveMemoryWarning
{
	if(!IS_IPAD())
	{
		_movieListController = nil;
	}
	
	[super didReceiveMemoryWarning];
}

/* getter of willReapper */
- (BOOL)willReappear
{
	return !_refreshLocations;
}

/* setter of willReapper */
- (void)setWillReappear:(BOOL)new
{
	if([_locations count]) _refreshLocations = !new;
}

/* layout */
- (void)loadView
{
	[super loadView];
	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.rowHeight = 38;
	_tableView.sectionHeaderHeight = 0;
	if(self.editing)
		[_tableView setEditing:YES animated:NO];
	[self theme];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	const BOOL wasEditing = self.editing;
	[super setEditing:editing animated:animated];
	[_tableView setEditing:editing animated:animated];

	if(wasEditing != editing)
	{
		if(animated)
		{
			NSInteger row = _locations.count;
			if(showDefault)
				++row;
			if(editing)
				[_tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:row inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
			else
				[_tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:row inSection:0]] withRowAnimation:UITableViewRowAnimationRight];
		}
		else
			[_tableView reloadData];
	}
}

/* cancel in delegate mode */
- (void)doneAction:(id)sender
{
	locationCallback_t call = callback;
	callback = nil;
	if(call)
		call(nil, YES);
}

/* about to display */
- (void)viewWillAppear:(BOOL)animated
{
	_tableView.allowsSelection = YES;

	if(callback)
	{
		UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																				target:self action:@selector(doneAction:)];
		self.navigationItem.leftBarButtonItem = button;
	}
	else
		self.navigationItem.leftBarButtonItem = nil;
	self.navigationItem.rightBarButtonItem = self.editButtonItem;

	// Refresh cache if we have a cleared one
	if(_refreshLocations && !_reloading)
	{
		_reloading = YES;
		[self emptyData];
		[_refreshHeaderView setTableLoadingWithinScrollView:_tableView];

		// Run this in our "temporary" queue
		[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(fetchData)];
	}
	else
	{
		// this UIViewController is about to re-appear, make sure we remove the current selection in our table view
		NSIndexPath *tableSelection = [_tableView indexPathForSelectedRow];
		[_tableView deselectRowAtIndexPath:tableSelection animated:YES];
	}

	_refreshLocations = YES;

	[super viewWillAppear: animated];
}

/* did hide */
- (void)viewDidDisappear:(BOOL)animated
{
	// Clean caches if supposed to
	if(_refreshLocations)
	{
		[_locations removeAllObjects];

		if(!IS_IPAD())
		{
			_movieListController = nil;
		}
		_xmlReader = nil;
	}
}

/* fetch contents */
- (void)fetchData
{
	_reloading = YES;
	_xmlReader = [[RemoteConnectorObject sharedRemoteConnector] fetchLocationlist:self];
}

/* remove content data */
- (void)emptyData
{
	// Clean location list
	[_locations removeAllObjects];
#if INCLUDE_FEATURE(Extra_Animation)
	NSIndexSet *idxSet = [NSIndexSet indexSetWithIndex: 0];
	[_tableView reloadSections:idxSet withRowAnimation:UITableViewRowAnimationRight];
#else
	[_tableView reloadData];
#endif
	_xmlReader = nil;
}

/* force a refresh */
- (void)forceRefresh
{
	[_locations removeAllObjects];
	[_tableView reloadData];
	[_refreshHeaderView setTableLoadingWithinScrollView:_tableView];
	// Run this in our "temporary" queue
	[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(fetchData)];
	_refreshLocations = NO;
}

#pragma mark -
#pragma mark UIAlertViewDelegate
#pragma mark -

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
#define promptView (UIPromptView *)alertView
	if(buttonIndex == alertView.cancelButtonIndex)
	{
		// do nothing
	}
	else
	{
		NSString *bookmark = [promptView promptFieldAtIndex:0].text;
		Result *result = [[RemoteConnectorObject sharedRemoteConnector] addLocation:bookmark createFolder:YES];
		if(result.result)
		{
			GenericLocation *location = [[GenericLocation alloc] init];
			location.fullpath = bookmark;
			location.valid = YES;
			[self addLocation:location];
		}
		else
		{
			const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"")
																  message:[NSString stringWithFormat:NSLocalizedString(@"Unable to add bookmark: %@",@"Creating a bookmark has failed"), result.resulttext]
																 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
		}
	}
}

#pragma mark -
#pragma mark DataSourceDelegate
#pragma mark -

- (void)dataSourceDelegate:(SaxXmlReader *)dataSource errorParsingDocument:(NSError *)error
{
	if([error domain] == NSURLErrorDomain)
	{
		if([error code] == 404)
		{
			// received 404, assume very old enigma2 without location support: insert default location (if not showing anyway)
			if(!showDefault)
			{
				GenericLocation *location = [[GenericLocation alloc] init];
				location.fullpath = @"/hdd/movie/";
				location.valid = YES;
				[self addLocation:location];
			}
			error = nil;
		}
	}

	// assume details will fail too if in split
	if(isSplit)
	{
		[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:_tableView];
		[_tableView reloadData];
		_reloading = NO;
	}
	else
	{
		[super dataSourceDelegate:dataSource errorParsingDocument:error];
	}
}

#pragma mark -
#pragma mark LocationSourceDelegate
#pragma mark -

/* add location to list */
- (void)addLocation: (NSObject<LocationProtocol> *)location
{
	[_locations addObject: location];
#if INCLUDE_FEATURE(Extra_Animation)
	[_tableView insertRowsAtIndexPaths: [NSArray arrayWithObject: [NSIndexPath indexPathForRow:[_locations count]-1 inSection:0]]
					  withRowAnimation: UITableViewRowAnimationTop];
#endif
}

- (void)addLocations:(NSArray *)items
{
#if INCLUDE_FEATURE(Extra_Animation)
	NSUInteger count = _locations.count;
	NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:items.count];
#endif
	[_locations addObjectsFromArray:items];
#if INCLUDE_FEATURE(Extra_Animation)
	for(NSObject<LocationProtocol> *location in items)
	{
		[indexPaths addObject:[NSIndexPath indexPathForRow:count inSection:0]];
		++count;
	}
	if(indexPaths)
		[_tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationLeft];
#endif
}

#pragma mark	-
#pragma mark		Table View
#pragma mark	-

/* create cell for given row */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [BaseTableViewCell reusableTableViewCellInView:tableView withIdentifier:kBaseCell_ID];
	NSInteger row = indexPath.row;

	cell.textLabel.font = [UIFont boldSystemFontOfSize:kTextViewFontSize-1];
	if(showDefault && row-- == 0)
	{
		cell.textLabel.text = NSLocalizedString(@"Default Location", @"");;
	}
	else if(row == (NSInteger)_locations.count)
	{
		cell.textLabel.text = NSLocalizedString(@"New Bookmark", @"Title of cell to add a new bookmark");
	}
	else
		cell.textLabel.text = ((NSObject<LocationProtocol> *)[_locations objectAtIndex:row]).fullpath;

	[[DreamoteConfiguration singleton] styleTableViewCell:cell inTableView:tableView];
	return cell;
}

/* select row */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// do nothing if reloading
	if(_reloading)
	{
#if IS_DEBUG()
		NSLog(@"willSelectRowAtIndexPath was triggered for indexPath (section %d, row %d) while reloading", indexPath.section, indexPath.row);
#endif
		return [tableView deselectRowAtIndexPath:indexPath animated:YES];
	}

	NSInteger row = indexPath.row;
	NSObject<LocationProtocol> *location = nil;
	if(showDefault) --row;
	if(row > -1)
	{
		if(row >= (NSInteger)_locations.count)
		{
#if IS_DEBUG()
			NSLog(@"Selection (%d) outside of bounds (%d) in LocationListController. This does not have to be bad!", indexPath.row, _locations.count);
#endif
			return [tableView deselectRowAtIndexPath:indexPath animated:YES];
		}
		location = [_locations objectAtIndex:row];
		if(!location.valid)
			return [tableView deselectRowAtIndexPath:indexPath animated:YES];
	}

	// Callback mode
	if(callback)
	{
		locationCallback_t call = callback;
		callback = nil;
		tableView.allowsSelection = NO;
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
		call(location, NO);
	}
	// Open movie list
	else if(!_movieListController.reloading)
	{
		// Check for cached MovieListController instance
		if(_movieListController == nil)
			_movieListController = [[MovieListController alloc] init];
		_movieListController.currentLocation = location.fullpath;

		// We do not want to refresh bouquet list when we return
		_refreshLocations = NO;

		// when in split view go back to movie list, else push it on the stack
		if(!isSplit)
		{
			// XXX: wtf?
			if([self.navigationController.viewControllers containsObject:_movieListController])
			{
#if IS_DEBUG()
				NSMutableString* result = [[NSMutableString alloc] init];
				for(NSObject* obj in self.navigationController.viewControllers)
					[result appendString:[obj description]];
				[NSException raise:@"MovieListTwiceInNavigationStack" format:@"_movieListController was twice in navigation stack: %@", result];
#endif
				[self.navigationController popToViewController:self animated:NO]; // return to us, so we can push the service list without any problems
			}
			[self.navigationController pushViewController: _movieListController animated:YES];
		}
		else
			[_movieListController.navigationController popToRootViewControllerAnimated: YES];
	}
	else
		return [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

/* number of sections */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	return 1;
}

/* number of rows */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	NSUInteger count = _locations.count;
	if(showDefault)
		++count;
	if(self.editing)
		++count;
	return count;
}

/* editing style */
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(self.editing)
	{
		NSInteger row = indexPath.row;
		if(showDefault && row-- == 0)
			return UITableViewCellEditingStyleNone;
		if(row == (NSInteger)_locations.count)
			return UITableViewCellEditingStyleInsert;
		return UITableViewCellEditingStyleDelete;
	}
	return UITableViewCellEditingStyleNone;
}

/* commit editing style */
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(editingStyle == UITableViewCellEditingStyleInsert)
	{
		UIPromptView *alertView = [[UIPromptView alloc] initWithTitle:NSLocalizedString(@"Enter path of bookmark", @"Title of prompt requesting name for new bookmark")
															  message:nil
															 delegate:self
													cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
														okButtonTitle:@"OK"
								   ];
		alertView.promptViewStyle = UIPromptViewStylePlainTextInput;
		[alertView show];
	}
	else
	{
		NSInteger row = indexPath.row;
		if(showDefault) --row;
		NSObject<LocationProtocol> *location = [_locations objectAtIndex:row];
		Result *result = [[RemoteConnectorObject sharedRemoteConnector] delLocation:location.fullpath];
		if(result.result)
		{
			showCompletedHudWithText(NSLocalizedString(@"Bookmark deleted", @"Text of HUD when a bookmark was removed successfully"));
			[_locations removeObjectAtIndex:row];
			[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationRight];
		}
		else
		{
			[tableView reloadData];
		}
	}
}

#pragma mark -

/* support rotation */
- (BOOL)shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end
