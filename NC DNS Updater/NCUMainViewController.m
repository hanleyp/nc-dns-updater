//
//  NCUMainViewController.m
//  NC DNS Updater
//
//  Created by Spencer Müller Diniz on 7/23/14.
//  Copyright (c) 2014 SPENCER. All rights reserved.
//

#import "NCUMainViewController.h"
#import "NCUMainTableCellView.h"
#import "NCUAppDelegate.h"

@interface NCUMainViewController ()
@end

@implementation NCUMainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.masterSwitchState = [[NSUserDefaults standardUserDefaults] boolForKey:@"MASTER_SWITCH"];
        [self loadDomains];
    }
    return self;
}

- (void)loadView {
    [super loadView];
    
    [self.formView setHidden:YES];
    
    [self updateMasterSwitchPosition];
    NCUAppDelegate *appDelegate = (NCUAppDelegate *)[NSApplication sharedApplication].delegate;
    [appDelegate.window makeFirstResponder:self.domainsTableView];
    
    if ([self.namecheapDomains count] && !self.selectedNamecheapDomain) {
        [self.domainsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    }
}

- (void)loadDomains {
    self.namecheapDomains = [NSMutableArray array];
    NCUAppDelegate *appDelegate = (NCUAppDelegate *)[NSApplication sharedApplication].delegate;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"NCUNamecheapDomain"];
    NSError *error;

    [self.namecheapDomains addObjectsFromArray:[appDelegate.managedObjectContext executeFetchRequest:fetchRequest error:&error]];
    
    if (error) {
        NSLog(@"ERROR FETCHING DATA: %@", [error localizedDescription]);
    }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.namecheapDomains count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NCUMainTableCellView *cell = [tableView makeViewWithIdentifier:@"MainTableCellView" owner:self];
    NCUNamecheapDomain *namecheapDomain = [self.namecheapDomains objectAtIndex:row];
    cell.textField.stringValue = namecheapDomain.name;
    
    return cell;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSTableView *tableView = (NSTableView *)notification.object;
    [self saveChanges];

    if (self.selectedNamecheapDomain) {
        [self.domainsTableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:[self.namecheapDomains indexOfObject:self.selectedNamecheapDomain]] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
    }
    
    self.selectedNamecheapDomain = [self.namecheapDomains objectAtIndex:tableView.selectedRow];
    [self loadForm];
}

- (IBAction)addDomain_Clicked:(id)sender {
    NCUAppDelegate *appDelegate = (NCUAppDelegate *)[NSApplication sharedApplication].delegate;
    NSManagedObjectContext *context = appDelegate.managedObjectContext;
    NCUNamecheapDomain *namecheapDomain = [NSEntityDescription insertNewObjectForEntityForName:@"NCUNamecheapDomain" inManagedObjectContext:context];
    
    namecheapDomain.name = @"new domain";
    namecheapDomain.host = @"";
    namecheapDomain.domain = @"";
    namecheapDomain.password = @"";
    namecheapDomain.interval = @5;
    namecheapDomain.enabled = NO;
    
    [self.namecheapDomains addObject:namecheapDomain];
    [self.domainsTableView reloadData];
    [self.domainsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[self.namecheapDomains indexOfObject:namecheapDomain]] byExtendingSelection:NO];
    [self loadForm];
}

- (void)loadForm {
    if (self.selectedNamecheapDomain) {
        [self.formView setHidden:NO];
        [self.domainNameTextField setStringValue:self.selectedNamecheapDomain.name];
        [self.domainHostTextField setStringValue:self.selectedNamecheapDomain.host];
        [self.domainDomainTextField setStringValue:self.selectedNamecheapDomain.domain];
        [self.domainPasswordTextField setStringValue:self.selectedNamecheapDomain.password];
        [self.domainIntervalTextField setStringValue:[NSString stringWithFormat:@"%@", self.selectedNamecheapDomain.interval]];
        [self.domainEnabledButton setState:[self.selectedNamecheapDomain.enabled integerValue]];
    }
    else {
        [self.formView setHidden:YES];
    }
}

- (IBAction)masterSwitch_Clicked:(id)sender {
    NSLog(@"MASTER SWITCH CLICKED");
    
    self.masterSwitchState = !self.masterSwitchState;
    [[NSUserDefaults standardUserDefaults] setBool:self.masterSwitchState forKey:@"MASTER_SWITCH"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [NSAnimationContext beginGrouping];
    [self updateMasterSwitchPosition];
    [NSAnimationContext endGrouping];
}

- (void)updateMasterSwitchPosition {
    if (self.masterSwitchState) {
        NSRect newFrame = self.masterSwitchButtonImageView.frame;
        newFrame.origin.x = CGRectGetMaxX(self.masterSwitchBackgroundButton.frame) - self.masterSwitchButtonImageView.frame.size.width;
        self.masterSwitchButtonImageView.animator.frame = newFrame;
    }
    else {
        NSRect newFrame = self.masterSwitchButtonImageView.frame;
        newFrame.origin = self.masterSwitchBackgroundButton.frame.origin;
        self.masterSwitchButtonImageView.animator.frame = newFrame;
    }
}

- (void)saveChanges {
    if (self.selectedNamecheapDomain) {
        NCUAppDelegate *appDelegate = (NCUAppDelegate *)[NSApplication sharedApplication].delegate;
        NSManagedObjectContext *context = appDelegate.managedObjectContext;
        
        self.selectedNamecheapDomain.name = self.domainNameTextField.stringValue;
        self.selectedNamecheapDomain.host = self.domainHostTextField.stringValue;
        self.selectedNamecheapDomain.domain = self.domainDomainTextField.stringValue;
        self.selectedNamecheapDomain.password = self.domainPasswordTextField.stringValue;
        self.selectedNamecheapDomain.interval = [NSNumber numberWithLong:self.domainIntervalTextField.integerValue];
        self.selectedNamecheapDomain.enabled = [NSNumber numberWithInteger:self.domainEnabledButton.state];
        
        NSError *error;
        if (![context save:&error]) {
            NSLog(@"ERROR SAVING IN DATABASE: %@", [error localizedDescription]);
        }
        
        [self.domainsTableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:[self.namecheapDomains indexOfObject:self.selectedNamecheapDomain]] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
    }
}

@end
