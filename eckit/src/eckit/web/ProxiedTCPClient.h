/*
 * (C) Copyright 1996- ECMWF.
 *
 * This software is licensed under the terms of the Apache Licence Version 2.0
 * which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
 * In applying this licence, ECMWF does not waive the privileges and immunities
 * granted to it by virtue of its status as an intergovernmental organisation nor
 * does it submit to any jurisdiction.
 */

// File ProxiedTCPClient.h
// Baudouin Raoult - ECMWF Aug 2017

#ifndef eckit_ProxiedTCPClient_h
#define eckit_ProxiedTCPClient_h

#include "eckit/net/NetAddress.h"
#include "eckit/net/TCPClient.h"

//-----------------------------------------------------------------------------

namespace eckit {

//-----------------------------------------------------------------------------

class ProxiedTCPClient : public TCPClient {
public:

// -- Contructors

	ProxiedTCPClient(const std::string& proxyHost, int proxyPort, int port = 0);

// -- Destructor

	~ProxiedTCPClient();

// -- Methods

	virtual TCPSocket& connect(const std::string& host, int port, int retries = 5, int timeout = 0);

private:

// No copy allowed

	ProxiedTCPClient(const ProxiedTCPClient&);
	ProxiedTCPClient& operator=(const ProxiedTCPClient&);

// -- Members

	std::string proxyHost_;
	int proxyPort_;

// -- Overridden methods

    virtual void print(std::ostream& s) const;

};


//-----------------------------------------------------------------------------

} // namespace eckit

#endif // ProxiedTCPClient_H
