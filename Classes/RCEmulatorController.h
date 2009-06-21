//
//  RCEmulatorController.h
//  dreaMote
//
//  Created by Moritz Venn on 23.07.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 @brief Basic Emulated Remote Control.
 */
@interface RCEmulatorController : UIViewController <UIScrollViewDelegate>
{
@private
	BOOL _shouldVibrate; /*!< @brief Vibrate as response to successfully sent RC code? */

	UIView *screenView; /*!< @brief Screenshot View. */
	UIScrollView *scrollView; /*!< @brief Container of Screenshot View. */
	UIImageView *imageView; /*!< @brief Actual Screenshot UI Item. */
	UIToolbar *toolbar; /*!< @brief Toolbar. */
	UIBarButtonItem *screenshotButton; /*!< @brief Button to quickly change to Screenshot View. */

	NSInteger _screenshotType; /*!< @brief Selected Screenshot type. */
@protected
	UIView *rcView; /*!< @brief Remote Controller view. */
}

/*!
 @brief Create custom Button.
 
 @param frame Button Frame.
 @param imagePath Path to Button Image.
 @param keyCode RC Code.
 @return UIButton instance.
 */
- (UIButton*)customButton:(CGRect)frame withImage:(NSString*)imagePath andKeyCode:(int)keyCode;

/*!
 @brief Load Image.
 
 @param dummy Unused parameter required by Buttons.
 */
- (void)loadImage:(id)dummy;

/*!
 @brief Flip Views.
 
 @param sender Unused parameter required by Buttons.
 */
- (void)flipView:(id)sender;

@end
