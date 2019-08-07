/* $Id: pjsip.h 3553 2011-05-05 06:14:19Z nanang $ */
/* 
 * Copyright (C) 2008-2011 Teluu Inc. (http://www.teluu.com)
 * Copyright (C) 2003-2008 Benny Prijono <benny@prijono.org>
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
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA 
 */
#ifndef __PJSIPCarthage_H__
#define __PJSIPCarthage_H__

/* Base types. */
#include <PJSIPCarthage/pjsip/sip_types.h>
#include <PJSIPCarthage/pjsip/sip_errno.h>

/* Messaging and parsing. */
#include <PJSIPCarthage/pjsip/sip_uri.h>
#include <PJSIPCarthage/pjsip/sip_tel_uri.h>
#include <PJSIPCarthage/pjsip/sip_msg.h>
#include <PJSIPCarthage/pjsip/sip_multipart.h>
#include <PJSIPCarthage/pjsip/sip_parser.h>

/* Core */
#include <PJSIPCarthage/pjsip/sip_event.h>
#include <PJSIPCarthage/pjsip/sip_module.h>
#include <PJSIPCarthage/pjsip/sip_endpoint.h>
#include <PJSIPCarthage/pjsip/sip_util.h>

/* Transport layer */
#include <PJSIPCarthage/pjsip/sip_transport.h>
#include <PJSIPCarthage/pjsip/sip_transport_udp.h>
#include <PJSIPCarthage/pjsip/sip_transport_loop.h>
#include <PJSIPCarthage/pjsip/sip_transport_tcp.h>
#include <PJSIPCarthage/pjsip/sip_transport_tls.h>
#include <PJSIPCarthage/pjsip/sip_resolve.h>

/* Authentication. */
#include <PJSIPCarthage/pjsip/sip_auth.h>
#include <PJSIPCarthage/pjsip/sip_auth_aka.h>

/* Transaction layer. */
#include <PJSIPCarthage/pjsip/sip_transaction.h>

/* UA Layer. */
#include <PJSIPCarthage/pjsip/sip_ua_layer.h>
#include <PJSIPCarthage/pjsip/sip_dialog.h>


#endif	/* __PJSIPCarthage_H__ */

