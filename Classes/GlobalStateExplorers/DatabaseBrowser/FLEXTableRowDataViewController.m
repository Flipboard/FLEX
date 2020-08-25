//
//  FLEXTableRowDataViewController.m
//  FLEX
//
//  Created by Chaoshuai Lu on 7/8/20.
//

#import "FLEXTableRowDataViewController.h"

#import <Foundation/Foundation.h>

#import "FLEXAlert.h"
#import "FLEXMutableListSection.h"

@implementation FLEXTableRowDataViewController
{
    FLEXMutableListSection<NSString *> *_section;
    NSDictionary<NSString *, NSString *> *_valuesByColumn;
}

#pragma mark - Initializer

- (instancetype)initWithTitle:(NSString *)title
                      rowData:(NSDictionary<NSString *, NSString *> *)rowData
{
    if (self = [super init]) {
        self.title = title;
        _valuesByColumn = [rowData copy];
    }
    return self;
}

#pragma mark - Overrides

- (NSArray<FLEXTableViewSection *> *)makeSections {
    NSArray<NSString *> *columns = _valuesByColumn.allKeys;
    __weak __typeof(self) weakSelf = self;
    _section = [FLEXMutableListSection list:columns
        cellConfiguration:^(UITableViewCell *cell, NSString *column, NSInteger row) {
            __strong __typeof(self) strongSelf = weakSelf;
            if (strongSelf) {
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.textLabel.text = column;
                cell.detailTextLabel.text = [strongSelf->_valuesByColumn[column] description];
            }
        } filterMatcher:^BOOL(NSString *filterText, NSString *column) {
            __strong __typeof(self) strongSelf = weakSelf;
            if (strongSelf) {
                return [column localizedCaseInsensitiveContainsString:filterText] ||
                    [strongSelf->_valuesByColumn[column] localizedCaseInsensitiveContainsString:filterText];
            } else {
                return NO;
            }
        }
    ];

    _section.selectionHandler = ^(UIViewController *host, NSString *column) {
        __strong __typeof(self) strongSelf = weakSelf;
        if (strongSelf) {
            NSString *string = [strongSelf->_valuesByColumn[column] description];
            UIPasteboard.generalPasteboard.string = string;
            [FLEXAlert makeAlert:^(FLEXAlert *make) {
                make.title(@"Copied");
                make.message(string);
                make.button(@"OK");
            } showFrom:host];
        }
    };

    return @[_section];
}

@end
