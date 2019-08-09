//
//  Client.h
//  PJSIPCarthage
//
//  Created by Devansh Vyas on 09/08/19.
//  Copyright © 2019 Devansh Vyas. All rights reserved.
//

#include <stdio.h>
#import <AudioToolbox/AudioToolbox.h>
#import <Foundation/Foundation.h>
#import "pjsua_app_common.h"
#import "pjsua_internal.h"

int registerSipUser(NSString* sipUser, NSString* sipDomain, NSString* scheme, NSString* realm, NSString* username, int passwordType, NSString* passwd, NSString* proxy, int port);
void addSIPUserForCustomerSupport(char *sipUser, char* sipDomain, char* scheme, char* realm, char* username, int passwordType, char* passwd, char* proxy, int port);
void unregisterAccount(void);
void unregisterSupportAccount(int acc_id);
int sendCommand(char* to, char* command);
int isRegisteredUser(void);
int sendMessage(char* to, char* message, int account_id);
void makeCall(NSString* destUri, int acc_identity);
void endCall(void);
void answerCall(int acc_identity);
void muteCall(BOOL status);
void onSpeaker(BOOL status);
int sendDTMS(NSString* digits);


