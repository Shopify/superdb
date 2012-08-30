//
//  SuperNetworkMessageTypes.h
//  SuperDBCore
//
//  Created by Jason Brennan on 12-08-28.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#ifndef SuperDBCore_SuperNetworkMessageTypes_h
#define SuperDBCore_SuperNetworkMessageTypes_h

typedef enum {
	SuperNetworkMessageTypeHandshake,
	SuperNetworkMessageTypeRequestResponse
} SuperNetworkMessageType;

@class SuperNetworkMessage;
typedef SuperNetworkMessage *(^SuperInterpreterServiceRequestHandler)(SuperNetworkMessage *request);

#pragma mark - Message keys

extern NSString *kSuperNetworkMessageBodyStatusKey;
extern NSString *kSuperNetworkMessageBodyStatusOK;
extern NSString *kSuperNetworkMessageBodyStatusError;
extern NSString *kSuperNetworkMessageBodyErrorMessageKey;
extern NSString *kSuperNetworkMessageBodyErrorRange;
extern NSString *kSuperNetworkMessageBodyInputKey;
extern NSString *kSuperNetworkMessageBodyOutputKey;


#pragma mark - Resource paths

extern NSString *kSuperNetworkMessageResourceInterpreter;
extern NSString *kSuperNetworkMessageResourceSymbolTable;
extern NSString *kSuperNetworkMessageResourceClassList;


#endif
