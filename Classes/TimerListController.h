//
//  TimerListController.h
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Objects/TimerProtocol.h"

// Forward Declarations...
@class CXMLDocument;
@class FuzzyDateFormatter;
@class TimerViewController;

/*!
 @brief Timer List.
 */
@interface TimerListController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
@private
	NSMutableArray *_timers; /*!< @brief Timer List. */
	NSInteger dist[kTimerStateMax]; /*!< @brief Offset of State in Timer List. */
	FuzzyDateFormatter *dateFormatter; /*!< @brief Date Formatter. */
	TimerViewController *timerViewController; /*!< @brief Cached Timer Detail View. */
	BOOL _willReappear; /*!< @brief Used to guard free of ressources on close if we are opening a subview. */

	CXMLDocument *timerXMLDoc; /*!< @brief Current Timer XML Document. */
}

/*!
 @brief Timer List.
 */
@property (nonatomic, retain) NSMutableArray *timers;

/*!
 @brief Date Formatter.
 */
@property (nonatomic, retain) FuzzyDateFormatter *dateFormatter;

@end
