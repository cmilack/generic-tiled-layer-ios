//
//  EDNLODLimitedTiledMapServiceLayer.m
//
//  Created by Nicholas Furness on 3/14/12.
//  Copyright (c) 2012 ESRI. All rights reserved.
//

#import "AGSLODLimitedTiledLayer.h"
#import "AGSGenericTileOperation.h"

@interface AGSLODLimitedTiledLayer () <AGSGenericTileOperationDelegate, AGSLayerDelegate>
@property (nonatomic, retain) AGSTileInfo *myTileInfo;
@end

@implementation AGSLODLimitedTiledLayer
@synthesize minLODLevel = _minLODLevel;
@synthesize maxLODLevel = _maxLODLevel;
@synthesize wrappedTiledLayer = _wrappedTiledLayer;

const NSUInteger appleMinLODLevel = 3;
const NSUInteger appleMaxLODLevel = 14;

#pragma -mark Initialization
-(id)initWithBaseTiledMapServiceLayer:(AGSTiledServiceLayer *)baseLayer fromLODLevel:(NSInteger)min toLODLevel:(NSInteger)max
{
    self = [super init];
	if (self)
	{
		_wrappedTiledLayer = baseLayer;
        _wrappedTiledLayer.delegate = self;
		_minLODLevel = min;
		_maxLODLevel = max;
        _myTileInfo = nil;
	}
	
    return self;
}

- (void)dealloc
{
    _myTileInfo = nil;
	_wrappedTiledLayer = nil;
}

#pragma -mark Overrides
-(AGSTileInfo *)tileInfo
{
    if (self.myTileInfo == nil &&
		_wrappedTiledLayer != nil && 
		_wrappedTiledLayer.loaded)
    {
        AGSTileInfo *originalTileInfo = _wrappedTiledLayer.tileInfo;
        
		if (originalTileInfo != nil)
		{
			NSUInteger minLOD = self.minLODLevel;
			NSUInteger maxLOD = self.maxLODLevel;
			
			NSMutableArray *newLODs = [NSMutableArray array];

			// Remove the LODs that we're not interested in.
            for (AGSLOD *sourceLOD in originalTileInfo.lods) {
                if (sourceLOD.level >= minLOD &&
                    sourceLOD.level <= maxLOD) {
                    NSLog(@"Adding %d", sourceLOD.level);
                    [newLODs addObject:[[AGSLOD alloc] initWithLevel:sourceLOD.level
                                                          resolution:sourceLOD.resolution
                                                               scale:sourceLOD.scale]];
                }
            }
			
			// We're just duplicating everything here...
			self.myTileInfo = [[AGSTileInfo alloc] initWithDpi:originalTileInfo.dpi
                                                        format:originalTileInfo.format
                                                          lods:[NSArray arrayWithArray:newLODs] // ...except the LODs
                                                        origin:originalTileInfo.origin
                                              spatialReference:originalTileInfo.spatialReference
                                                      tileSize:CGSizeMake(originalTileInfo.tileSize.width, originalTileInfo.tileSize.height)];
            
            [self.myTileInfo computeTileBounds:self.fullEnvelope];
		}
    }
    
    return self.myTileInfo;
}


-(void)layerDidLoad:(AGSLayer *)layer
{
    if (layer == _wrappedTiledLayer)
    {
        [self layerDidLoad];
    }
}

-(AGSEnvelope *)fullEnvelope
{
    return _wrappedTiledLayer.fullEnvelope;
}

-(AGSEnvelope *)initialEnvelope
{
    return _wrappedTiledLayer.initialEnvelope;
}

-(AGSSpatialReference *)spatialReference
{
    return _wrappedTiledLayer.spatialReference;
}

-(void)requestTileForKey:(AGSTileKey *)key
{
    NSLog(@"RequestTileForKey: %@", key);
    AGSGenericTileOperation *op =
    [[AGSGenericTileOperation alloc] initWithTileKey:key
                                       forTiledLayer:_wrappedTiledLayer
                                         forDelegate:self];
    
    [[AGSRequestOperation sharedOperationQueue] addOperation:op];
}

-(void)cancelRequestForKey:(AGSTileKey *)key
{
    NSLog(@"Cancel request for key: %@", key);
    for (id op in [AGSRequestOperation sharedOperationQueue].operations)
    {
        if ([op isKindOfClass:[AGSGenericTileOperation class]])
        {
            if ([((AGSGenericTileOperation *)op).tileKey isEqualToTileKey:key])
            {
                NSLog(@"Found operation. Cancelling…");
                [((AGSGenericTileOperation *)op) cancel];
                return;
            }
        }
    }
    [_wrappedTiledLayer cancelRequestForKey:key];
}

-(void)genericTileOperation:(AGSGenericTileOperation *)operation
             loadedTileData:(NSData *)tileData
                 forTileKey:(AGSTileKey *)tileKey
{
    if (!operation.isCancelled)
    {
        [self setTileData:tileData forKey:tileKey];
    }
}

//#pragma mark - Generic Passthrough
//// Step 1: We have to pretend to be whatever AGSTiledLayer we contain. Neat!
//-(BOOL)isKindOfClass:(Class)aClass
//{
//	// Why not just inherit from AGSTiledLayer? Well, then the call to inherited methods go 
//	// direct to the super instance rather than through the dynamic "forwardInvocation" 
//	// framework (see below).
//	if (_wrappedTiledLayer != nil && [_wrappedTiledLayer isKindOfClass:aClass])
//	{
////		NSLog(@"I (%@) am a kind of %@", [self class], aClass);
//		return YES;
//	}
//	else 
//	{
//		return [super isKindOfClass:aClass];
//	}
//}
//
//// Step 2: We now have to return a valid method signature for objects we pretend to be.
//-(NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
//{
////	NSLog(@"Method signature for selector: %@", NSStringFromSelector(aSelector));
//	if (_wrappedTiledLayer != nil && [_wrappedTiledLayer respondsToSelector:aSelector])
//	{
//		return [_wrappedTiledLayer methodSignatureForSelector:aSelector];
//	}
//	else
//	{
//		return [super methodSignatureForSelector:aSelector];
//	}
//}
//
//// Step 3: Since we provided a method signature, we need to handle the invocation.
//-(void)forwardInvocation:(NSInvocation *)anInvocation
//{
//	if (_wrappedTiledLayer != nil && [_wrappedTiledLayer respondsToSelector:[anInvocation selector]])
//	{
//		// Our wrapped AGSTiledLayer subclass handles this particular message, so let's do it.
////		NSLog(@"Forwarding invocation: %@", NSStringFromSelector([anInvocation selector]));
//		[anInvocation invokeWithTarget:_wrappedTiledLayer];
//	}
//	else 
//	{
//		// Well, really, we should never get here, but we'll be nice just in case.
//		[super forwardInvocation:anInvocation];
//	}
//}

#pragma -mark Static members
// Convenience methods for getting LOD Limited layers.
+(AGSLODLimitedTiledLayer *)lodLimitedTiledMapServiceLayer:(AGSTiledServiceLayer *)baseLayer fromLODLevel:(NSInteger)min toLODLevel:(NSInteger)max
{
	return [[AGSLODLimitedTiledLayer alloc] initWithBaseTiledMapServiceLayer:baseLayer 
																fromLODLevel:min 
																  toLODLevel:max];
}

+(AGSLODLimitedTiledLayer *)lodLimitedTiledMapServiceLayerMatchingAppleLODs:(AGSTiledServiceLayer *)baseLayer
{
	return [AGSLODLimitedTiledLayer lodLimitedTiledMapServiceLayer:baseLayer 
													  fromLODLevel:appleMinLODLevel 
														toLODLevel:appleMaxLODLevel];
}

+(AGSLODLimitedTiledLayer *)openStreetMapLayerFromLODLevel:(NSInteger)min toLODLevel:(NSInteger)max
{
    return [AGSLODLimitedTiledLayer lodLimitedTiledMapServiceLayer:[AGSOpenStreetMapLayer openStreetMapLayer] 
													  fromLODLevel:min
														toLODLevel:max];
}

+(AGSLODLimitedTiledLayer *)openStreetMapLayerMatchingAppleOSMLODS
{
    return [AGSLODLimitedTiledLayer openStreetMapLayerFromLODLevel:appleMinLODLevel 
														toLODLevel:appleMaxLODLevel];
}
@end
