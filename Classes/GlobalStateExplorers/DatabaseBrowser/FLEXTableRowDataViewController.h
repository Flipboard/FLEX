//
//  FLEXTableRowDataViewController.h
//  FLEX
//
//  Created by Chaoshuai Lu on 7/8/20.
//

#import "FLEXFilteringTableViewController.h"

@interface FLEXTableRowDataViewController : FLEXFilteringTableViewController

- (instancetype)initWithTitle:(NSString *)title
                      rowData:(NSDictionary<NSString *, NSString *> *)rowData;

@end
