//
//  JBTextEditorProcessor.h
//  TextEditing
//
//  Created by Jason Brennan on 12-06-04.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^JBTextEditorProcessorCompletionHandler)(NSString *processedText, NSRange newSelectedRange);

@interface JBTextEditorProcessor : NSObject

- (void)processString:(NSString *)originalString changedSelectionRange:(NSRange)selectionRange deletedString:(NSString *)deletedString insertedString:(NSString *)insertedString completionHandler:(JBTextEditorProcessorCompletionHandler)completionHandler; // completionHandler is executed on the main queue.
@end
