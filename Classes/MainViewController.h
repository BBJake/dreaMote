//
//  MainViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 @brief Main View.
 */
@interface MainViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
	IBOutlet UITableView		*myTableView; /*!< @brief Table View. */
	NSMutableArray	*menuList; /*!< @brief Item List. */
@private
	UIViewController *configListController; /*!< @brief Cached Configuration List. */
	UIViewController *aboutViewController; /*!< @brief Cached Abour View. */
	NSDictionary *_bouquetDictionary; /*!< @brief Dictionary describing Bouquet List Item. */
	NSDictionary *_recordDictionary; /*!< @brief Dictionary describing Movie List Item. */
	NSDictionary *_serviceDictionary; /*!< @brief Dictionary describing Service List Item. */
	NSDictionary *_eventSearchDictionary; /*!< @brief Dictionary describing EPG Search Item. */
	NSDictionary *_signalDictionary; /*!< @brief Dictionary describing Signal Item. */
}

/*!
 @brief Table View.
 */
@property (nonatomic, retain) UITableView *myTableView;

@end
