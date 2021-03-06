//
//  NSObject+RACDeallocating.m
//  ReactiveCocoa
//
//  Created by Kazuo Koga on 2013/03/15.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "RACTestObject.h"

#import "NSObject+RACDeallocating.h"
#import "RACCompoundDisposable.h"
#import "RACDisposable.h"
#import "RACSignal+Operations.h"

SpecBegin(NSObjectRACDeallocatingSpec)

describe(@"-rac_deallocDisposable", ^{
	it(@"should dispose of the disposable when it is dealloc'd", ^{
		__block BOOL wasDisposed = NO;
		@autoreleasepool {
			NSObject *object __attribute__((objc_precise_lifetime)) = [[NSObject alloc] init];
			[object.rac_deallocDisposable addDisposable:[RACDisposable disposableWithBlock:^{
				wasDisposed = YES;
			}]];

			expect(wasDisposed).to.beFalsy();
		}

		expect(wasDisposed).to.beTruthy();
	});

	it(@"should be able to use the object during disposal", ^{
		@autoreleasepool {
			RACTestObject *object __attribute__((objc_precise_lifetime)) = [[RACTestObject alloc] init];

			@autoreleasepool {
				object.objectValue = [@"foo" mutableCopy];
			}

			__unsafe_unretained RACTestObject *weakObject = object;

			[object.rac_deallocDisposable addDisposable:[RACDisposable disposableWithBlock:^{
				expect(weakObject.objectValue).to.equal(@"foo");
			}]];
		}
	});
});

describe(@"-rac_willDeallocSignal", ^{
	it(@"should complete on dealloc", ^{
		__block BOOL completed = NO;
		@autoreleasepool {
			[[[[RACTestObject alloc] init] rac_willDeallocSignal] subscribeCompleted:^{
				completed = YES;
			}];
		}

		expect(completed).to.beTruthy();
	});

	it(@"should not send anything", ^{
		__block BOOL valueReceived = NO;
		__block BOOL completed = NO;
		@autoreleasepool {
			[[[[RACTestObject alloc] init] rac_willDeallocSignal] subscribeNext:^(id x) {
				valueReceived = YES;
			} completed:^{
				completed = YES;
			}];
		}

		expect(valueReceived).to.beFalsy();
		expect(completed).to.beTruthy();
	});

	it(@"should complete before the object is invalid", ^{
		__block NSString *objectValue;

		@autoreleasepool {
			RACTestObject *object __attribute__((objc_precise_lifetime)) = [[RACTestObject alloc] init];

			@autoreleasepool {
				object.objectValue = [@"foo" mutableCopy];
			}

			__unsafe_unretained RACTestObject *weakObject = object;

			[[object rac_willDeallocSignal] subscribeCompleted:^{
				objectValue = [weakObject.objectValue copy];
			}];
		}

		expect(objectValue).to.equal(@"foo");
	});
});

SpecEnd
