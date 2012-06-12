//
//  SanoSubstanceViewController.m
//  Sano
//
//  Created by Raj Gokal on 1/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SanoSubstanceViewController.h"
#import <Parse/Parse.h>

static NSString *const MAIN_PLOT      = @"Scatter Plot";
static NSString *const SELECTION_PLOT = @"Selection Plot";

@interface SanoSubstanceViewController()

-(void) addDataPoint;
-(void) setupGraph;
-(void) setupAxes;
-(void) setupScatterPlots;
-(void) fetchSubstanceSequence;
-(double) extrema:(NSString *)extrema ForAxis:(NSString *)axis;
-(double) minXValue;
-(double) minYValue;
-(double) maxXValue;
-(double) maxYValue;
-(double) midXValue;
-(double) midYValue;

@property (nonatomic, readwrite) NSUInteger selectedIndex;
@property (nonatomic, strong) CPTXYGraph *graph;
@property (nonatomic, strong) NSMutableArray *dataForPlot;
@property (nonatomic, strong) CPTPlotSpaceAnnotation *symbolTextAnnotation;
@property (atomic, strong) NSMutableArray *substanceSequence;
@property (nonatomic, strong) NSTimer *timer;

@end

@implementation SanoSubstanceViewController

@synthesize dataForPlot = _dataForPlot;
@synthesize symbolTextAnnotation = _symbolTextAnnotation;
@synthesize currentSubstance = _currentSubstance;
@synthesize selectedIndex = _selectedIndex;
@synthesize graph = _graph;
@synthesize substanceSequence = _substanceSequence;
@synthesize timer = _timer;

-(void)generateSubstanceSequence {
    
    double start = (double)(int)[[NSDate date] timeIntervalSince1970];
    double yValue = (self.currentSubstance.max - self.currentSubstance.min)/2.0;
    NSMutableArray *localSequence = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < 3600; i++) {
        NSDate *xDate = [NSDate dateWithTimeIntervalSince1970:start + i];
        
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:xDate, @"x", [NSNumber numberWithDouble:yValue], @"y", nil];
        
        [localSequence addObject:dict];
        
        yValue = yValue + (double)rand()/(double)RAND_MAX - 0.5;
    }
    
    self.substanceSequence = [localSequence copy];
}

-(void)fetchSubstanceSequence {

    PFUser *currentUser = [PFUser currentUser];
    NSString *substanceSequenceKey = [self.currentSubstance.name stringByAppendingString:@"_sequence"];
    
    // A substance sequence is an NSArray of 
    // NSDictionaries - each NSDictionary with two keys,
    // "x" and "y" with objects that are a NSDate and a NSNumber

    // PFUsers have an object for each substance sequence
    // called [name]_sequence. 
    
    NSArray *fetchedSubstanceSequence = [currentUser objectForKey: substanceSequenceKey];
    
    if (fetchedSubstanceSequence) {
        NSDate *lastDate = [fetchedSubstanceSequence.lastObject objectForKey:@"x"];
        
        if (lastDate < [NSDate date]) {
            // if last timestamp is less than five minutes from now, generate a new sequence and post
            
        }
        else {
            
        }
        
    }
    else {
        [self generateSubstanceSequence];
        [currentUser setObject:self.substanceSequence forKey:substanceSequenceKey];
        [currentUser saveInBackground];
    }
}

-(void)setSelectedIndex:(NSUInteger)newIndex
{
    if ( self.selectedIndex != newIndex ) {
        self.selectedIndex = newIndex;
        [[self.graph plotWithIdentifier:SELECTION_PLOT] reloadData];
    }
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

-(double)xAxisOffset {
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;    
    return plotSpace.yRange.lengthDouble * 0.10;
}

-(void)scatterPlot:(CPTScatterPlot *)plot plotSymbolWasSelectedAtRecordIndex:(NSUInteger)index
{
    if ( self.symbolTextAnnotation ) {
        [self.graph.plotAreaFrame.plotArea removeAnnotation:self.symbolTextAnnotation];
        self.symbolTextAnnotation = nil;
    }
    
    // Setup a style for the annotation
    CPTMutableTextStyle *hitAnnotationTextStyle = [CPTMutableTextStyle textStyle];
    hitAnnotationTextStyle.color    = [CPTColor darkGrayColor];
    hitAnnotationTextStyle.fontSize = 16.0f;
    hitAnnotationTextStyle.fontName = @"Helvetica-Bold";
    
    // Determine point of symbol in plot coordinates
    NSNumber *x          = [[self.dataForPlot objectAtIndex:index] valueForKey:@"x"];
    NSNumber *y          = [[self.dataForPlot objectAtIndex:index] valueForKey:@"y"];
    NSArray *anchorPoint = [NSArray arrayWithObjects:x, y, nil];
    
    // Add annotation
    // First make a string for the y value
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setMaximumFractionDigits:2];
    NSString *yString = [formatter stringFromNumber:y];
    
    // Now add the annotation to the plot area
    CPTTextLayer *textLayer = [[CPTTextLayer alloc] initWithText:yString style:hitAnnotationTextStyle];
    self.symbolTextAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:self.graph.defaultPlotSpace anchorPlotPoint:anchorPoint];
    self.symbolTextAnnotation.contentLayer = textLayer;
    self.symbolTextAnnotation.displacement = CGPointMake(0.0f, 20.0f);
    [self.graph.plotAreaFrame.plotArea addAnnotation:self.symbolTextAnnotation];

}

-(BOOL)plotSpace:(CPTPlotSpace *)space shouldHandlePointingDeviceDownEvent:(id)event atPoint:(CGPoint)point
{
    if ( self.symbolTextAnnotation ) {
        [self.graph.plotAreaFrame.plotArea removeAnnotation:self.symbolTextAnnotation];
        self.symbolTextAnnotation = nil;
    }
    return YES;
}

-(CGPoint)plotSpace:(CPTPlotSpace *)space willDisplaceBy:(CGPoint)displacement
{
    return CGPointMake(displacement.x, 0);
}

-(CPTPlotRange *)plotSpace:(CPTPlotSpace *)space willChangePlotRangeTo:(CPTPlotRange *)newRange forCoordinate:(CPTCoordinate)coordinate
{
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
    
    if (coordinate == CPTCoordinateX) {
        axisSet.yAxis.orthogonalCoordinateDecimal = newRange.location;
    }
    else {
        CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;        
        newRange = [CPTPlotRange plotRangeWithLocation:(plotSpace.yRange.location) length:(plotSpace.yRange.length)];
    }
    return newRange;
}

-(double) extrema:(NSString *)extrema ForAxis:(NSString *)axis {
    NSArray *copy = [self.dataForPlot copy];

    NSArray *sortedCopy = [copy sortedArrayUsingComparator:^(id a, id b){
        id first = [a objectForKey:axis];
        id second = [b objectForKey:axis];
        return [first compare:second];
    }];
    if (extrema == @"max") {
        return [[sortedCopy.lastObject objectForKey:axis] doubleValue];
    }
    else {
        return [[[sortedCopy objectAtIndex:0] objectForKey:axis] doubleValue];
    }
}

-(double) minXValue {
    return [self extrema:@"min" ForAxis:@"x"];
}

-(double) minYValue {
    return [self extrema:@"min" ForAxis:@"y"];
}

-(double) maxXValue {
    return [self extrema:@"max" ForAxis:@"x"];
}

-(double) maxYValue {
    return [self extrema:@"max" ForAxis:@"y"];
}

-(double) midYValue {
    return ([self maxYValue] - [self minYValue])/2;
}

-(double) midXValue {
    return ([self maxXValue] - [self minXValue])/2;
}

-(void) setupGraph {
    self.graph = [[CPTXYGraph alloc] initWithFrame:CGRectZero];
    CPTTheme *theme = [CPTTheme themeNamed:kCPTPlainWhiteTheme];
    [self.graph applyTheme:theme];
    CPTGraphHostingView *hostingView = (CPTGraphHostingView *)self.view;
    hostingView.collapsesLayers = NO; // Setting to YES reduces GPU memory usage, but can slow drawing/scrolling
    hostingView.hostedGraph     = self.graph;
    
    self.graph.paddingLeft   = 0.0;
    self.graph.paddingTop    = 0.0;
    self.graph.paddingRight  = 0.0;
    self.graph.paddingBottom = 0.0;
    
    double yLength = [self maxYValue] - [self minYValue];
    
    // Setup plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
    
    plotSpace.allowsUserInteraction = YES;
    plotSpace.xRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt([[NSDate date] timeIntervalSince1970]) length:CPTDecimalFromFloat((float) 100 + 2)];
    plotSpace.yRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat((float) [self minYValue] - 0.5) length:CPTDecimalFromFloat((float) yLength + 1)];
//    plotSpace.globalXRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(0) length:CPTDecimalFromInt(100)];
    plotSpace.delegate = self;    
}

-(void)setupAxes {
    NSDate *refDate = [NSDate dateWithTimeIntervalSince1970:0];
    
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;    
    
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
    CPTXYAxis *x          = axisSet.xAxis;
    
    x.orthogonalCoordinateDecimal = CPTDecimalFromDouble(plotSpace.yRange.locationDouble + [self xAxisOffset]);

    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];

//    dateFormatter.dateStyle = kCFDateFormatterShortStyle;
//    dateFormatter.timeStyle = kCFDateFormatterShortStyle;
    dateFormatter.dateFormat = @"H:mm:ss";
    CPTTimeFormatter *timeFormatter = [[CPTTimeFormatter alloc] initWithDateFormatter:dateFormatter];
    timeFormatter.referenceDate = refDate;

    x.labelFormatter = timeFormatter;
    
    x.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
    x.minorTicksPerInterval       = 2;
    x.preferredNumberOfMajorTicks = 6;
    
    CPTXYAxis *y = axisSet.yAxis;
    y.orthogonalCoordinateDecimal = CPTDecimalFromDouble([[NSDate date] timeIntervalSince1970]);
    y.labelOffset                 = -35;
    y.delegate             = self;
    y.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
    y.preferredNumberOfMajorTicks = 4;
    y.minorTicksPerInterval       = 5;
    
    // Create the acceptable threshold guide
    CPTFill *fill = [CPTFill fillWithColor:[CPTColor grayColor]];
    CPTPlotRange *fillRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble([self midYValue] - 0.2) length:CPTDecimalFromDouble([self midYValue] + 0.2)];
    
    [y addBackgroundLimitBand:[CPTLimitBand limitBandWithRange:fillRange fill:fill]];    
}

-(void)setupScatterPlots {
    CPTScatterPlot *dataSourceLinePlot  = [[CPTScatterPlot alloc] init];
    
    dataSourceLinePlot.identifier = MAIN_PLOT;
    
    CPTMutableLineStyle *lineStyle = [CPTMutableLineStyle lineStyle];
    lineStyle.miterLimit        = 1.0f;
    lineStyle.lineWidth         = 3.0f;
    lineStyle.lineColor         = [CPTColor blueColor];
    dataSourceLinePlot.dataLineStyle = lineStyle;
    
    dataSourceLinePlot.dataSource    = self;
    dataSourceLinePlot.interpolation = CPTScatterPlotInterpolationCurved;
    dataSourceLinePlot.delegate = self;
    dataSourceLinePlot.plotSymbolMarginForHitDetection = 7.0;
    
    [self.graph addPlot:dataSourceLinePlot];

    // Add plot symbols
    CPTMutableLineStyle *symbolLineStyle = [CPTMutableLineStyle lineStyle];
    symbolLineStyle.lineColor = [CPTColor blackColor];
    CPTPlotSymbol *plotSymbol = [CPTPlotSymbol ellipsePlotSymbol];
    plotSymbol.fill          = [CPTFill fillWithColor:[CPTColor blueColor]];
    plotSymbol.lineStyle     = symbolLineStyle;
    plotSymbol.size          = CGSizeMake(1.0, 1.0);
    dataSourceLinePlot.plotSymbol = plotSymbol;

}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    // right now these are dependent on each other and should 
    // be called in this order:
    self.dataForPlot = nil;

    if (!self.substanceSequence) {
        [self generateSubstanceSequence];
    }

    [self addDataPoint];
    [self setupGraph];
    [self setupAxes];
    [self setupScatterPlots];
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(addDataPoint) userInfo:nil repeats:YES];
}

-(void)viewDidUnload {
    [self.timer invalidate];
}

#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    return [self.dataForPlot count];
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    NSNumber *num = nil;
    
    if ( [(NSString *)plot.identifier isEqualToString:MAIN_PLOT] ) {    
        NSString *key = (fieldEnum == CPTScatterPlotFieldX ? @"x" : @"y");
        num = [[self.dataForPlot objectAtIndex:index] valueForKey:key];
    }
    return num;
}

-(CPTLayer *)dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)index
{
    // use default label
    return nil;
}

-(void)addDataPoint {
    int unixTime = [[NSDate date] timeIntervalSince1970];
    
    NSNumber *nextY;

    for (id dict in self.substanceSequence) {
        if (unixTime == (int)[[dict objectForKey:@"x"] timeIntervalSince1970]) {
            nextY = [dict objectForKey:@"y"];
            break;
        }
    }
    
    NSNumber *nextX = [NSNumber numberWithInt:unixTime];
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:nextX, @"x", nextY, @"y", nil];
    
    NSMutableArray *localArray = [[NSMutableArray alloc] initWithArray:self.dataForPlot copyItems:YES];

    [localArray addObject:[dict copy]];
    self.dataForPlot = [[NSMutableArray alloc] initWithArray:localArray copyItems:YES];

    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;

    // adjust y axis if we go above max value
    if ([nextY doubleValue] > plotSpace.yRange.maxLimitDouble) {
        plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:plotSpace.yRange.minLimit length:CPTDecimalFromDouble([nextY doubleValue] - plotSpace.yRange.minLimitDouble + 1)];
        CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
        axisSet.xAxis.orthogonalCoordinateDecimal = CPTDecimalFromDouble(plotSpace.yRange.locationDouble + [self xAxisOffset]);
    }
    
    // adjust y axis if we go below the min value
    if ([nextY doubleValue] < plotSpace.yRange.minLimitDouble) {
        plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:(CPTDecimalFromDouble([nextY doubleValue] - 1)) length:CPTDecimalFromDouble(plotSpace.yRange.lengthDouble + 1)];
        CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
        axisSet.xAxis.orthogonalCoordinateDecimal = CPTDecimalFromDouble(plotSpace.yRange.locationDouble + [self xAxisOffset]);
    }
    
    // if we're not looking at historical data, bump the graph right.
    if ( [nextX doubleValue] < plotSpace.xRange.maxLimitDouble && [nextX doubleValue] + 1 > plotSpace.xRange.maxLimitDouble) {
        double newLocation = plotSpace.xRange.locationDouble + 1;
        double newLength = plotSpace.xRange.lengthDouble + 1;

        CPTPlotRange *newRange = [CPTPlotRange plotRangeWithLocation:(CPTDecimalFromDouble(newLocation)) length:(CPTDecimalFromDouble(newLength))];
        plotSpace.xRange = newRange;
        
        // move the y axis too 
        CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
        axisSet.yAxis.orthogonalCoordinateDecimal = newRange.location;
    }
    
    [self.graph reloadData];
}

@end
