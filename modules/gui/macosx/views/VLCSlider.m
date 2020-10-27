/*****************************************************************************
 * VLCSlider.m
 *****************************************************************************
 * Copyright (C) 2017 VLC authors and VideoLAN
 *
 * Authors: Marvin Scholz <epirat07 at gmail dot com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/

#import "VLCSlider.h"

#import "main/VLCMain.h"
#import "playlist/VLCPlaylistController.h"
#import "playlist/VLCPlayerController.h"

#import "extensions/NSView+VLCAdditions.h"
#import "views/VLCSliderCell.h"

@implementation VLCSlider

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];

    if (self) {
        NSAssert([self.cell isKindOfClass:[VLCSliderCell class]],
                 @"VLCSlider cell is not VLCSliderCell");
        _isScrollable = YES;
        if (@available(macOS 10.14, *)) {
            [self viewDidChangeEffectiveAppearance];
        } else {
            [self setSliderStyleLight];
        }

        /// gvlc
        // Setup a tracking area when the view is added to the window.
        NSTrackingArea* trackingArea = [
            [NSTrackingArea alloc] initWithRect: 
                [self bounds] 
                options: (
                    NSTrackingMouseEnteredAndExited 
                    | NSTrackingMouseMoved 
                    | NSTrackingActiveInKeyWindow
                    | NSTrackingInVisibleRect
                ) 
                owner:self 
                userInfo:nil
        ];
        [self addTrackingArea:trackingArea];           
    }
    return self;
}

- (void) mouseDown:(NSEvent*)theEvent {
	NSLog(@"\n --- aaa: mouseDown");

    NSPoint event_location = theEvent.locationInWindow;
    NSPoint local_point = [self convertPoint:event_location fromView:nil];
    int mouseAt = (int)local_point.x;
    int width = (int)NSWidth(self.bounds);

   // ---    
    VLCPlayerController * pc = 
        [[[VLCMain sharedInstance] playlistController] playerController];
    vlc_tick_t durSeconds = [pc durationOfCurrentMediaItem]/1000000;
    vlc_tick_t secToShow = (mouseAt * durSeconds)/width + 1;
    [pc setTimeFast: 1000000*secToShow];
}

- (void) mouseMoved:(NSEvent*)theEvent {
	NSLog(@"\n --- aaa: mouseMoved");

    NSPoint event_location = theEvent.locationInWindow;
    NSPoint local_point = [self convertPoint:event_location fromView:nil];
    int mouseAt = (int)local_point.x;
    int width = (int)NSWidth(self.bounds);
    VLCPlayerController * pc = 
        [[[VLCMain sharedInstance] playlistController] playerController];
    NSString * name = [pc nameOfCurrentMediaItem];
    int durSeconds = [pc durationOfCurrentMediaItem]/1000000;
    int secToShow = (mouseAt * durSeconds)/width + 1;
    NSString * sec = [NSString stringWithFormat:@"%d", secToShow];
    NSString * path = @"/Users/gsimsek/Downloads/.";
    // e.g. /opt/.video-name.mp4/1.jpg
    NSString * thumbFile = 
        [NSString stringWithFormat:@"%@%@%@%@%@", path, name, @"/", sec, @".jpg"];

    NSLog(@"--- aaa: mouseAt: %d", mouseAt);
    NSLog(@"--- aaa: width: %d", width);
    NSLog(@"--- aaa: name: %@", name);    
    NSLog(@"--- aaa: total dur: %d secs", durSeconds);
    NSLog(@"--- aaa: thumbFile: %@", thumbFile);
    NSLog(@"--- mw: %@", [[NSApplication sharedApplication] mainWindow]);

    NSImage * img = [[NSImage alloc]initWithContentsOfFile:thumbFile];
    if(img == nil) { NSLog(@" --- aaa: img is nil"); }
    // NSLog(@" --- aaa: size: %f x %f", img.size.width, img.size.height);
    // NSMakeRect: x, y, w, h
    NSRect frame = NSMakeRect(400, 400, 240, (240/img.size.width)*img.size.height);
    NSWindow* window  = [[NSWindow alloc] initWithContentRect:frame
                                          styleMask:NSBorderlessWindowMask
                                          backing:NSBackingStoreBuffered
                                          defer:NO];
    [[window contentView] setWantsLayer:YES];
    [[window contentView] layer].contents = img;
    [window makeKeyAndOrderFront: NSApp];

    // --- 

}

- (void) mouseEntered:(NSEvent*)theEvent {
	// NSLog(@"\n --- aaa: mouse entered");
}

+ (Class)cellClass
{
    return [VLCSliderCell class];
}

- (void)scrollWheel:(NSEvent *)event
{
    if (!_isScrollable)
        return [super scrollWheel:event];
    double increment;
    CGFloat deltaY = [event scrollingDeltaY];
    double range = [self maxValue] - [self minValue];

    // Scroll less for high precision, else it's too fast
    if (event.hasPreciseScrollingDeltas) {
        increment = (range * 0.002) * deltaY;
    } else {
        if (deltaY == 0.0)
            return;
        increment = (range * 0.01 * deltaY);
    }

    // If scrolling is inversed, increment in other direction
    if (!event.isDirectionInvertedFromDevice)
        increment = -increment;

    [self setDoubleValue:self.doubleValue - increment];
    [self sendAction:self.action to:self.target];
}

// Workaround for 10.7
// http://stackoverflow.com/questions/3985816/custom-nsslidercell
- (void)setNeedsDisplayInRect:(NSRect)invalidRect {
    [super setNeedsDisplayInRect:[self bounds]];
}

- (BOOL)getIndefinite
{
    return [(VLCSliderCell*)[self cell] indefinite];
}

- (void)setIndefinite:(BOOL)indefinite
{
    [(VLCSliderCell*)[self cell] setIndefinite:indefinite];
}

- (BOOL)getKnobHidden
{
    return [(VLCSliderCell*)[self cell] isKnobHidden];
}

- (void)setKnobHidden:(BOOL)isKnobHidden
{
    [(VLCSliderCell*)[self cell] setKnobHidden:isKnobHidden];
}

- (BOOL)isFlipped
{
    return NO;
}

- (void)setSliderStyleLight
{
    [(VLCSliderCell*)[self cell] setSliderStyleLight];
}

- (void)setSliderStyleDark
{
    [(VLCSliderCell*)[self cell] setSliderStyleDark];
}

- (void)viewDidChangeEffectiveAppearance
{
    if (self.shouldShowDarkAppearance) {
        [self setSliderStyleDark];
    } else {
        [self setSliderStyleLight];
    }
}

@end
