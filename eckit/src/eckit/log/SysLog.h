/*
 * (C) Copyright 1996- ECMWF.
 *
 * This software is licensed under the terms of the Apache Licence Version 2.0
 * which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
 * In applying this licence, ECMWF does not waive the privileges and immunities
 * granted to it by virtue of its status as an intergovernmental organisation nor
 * does it submit to any jurisdiction.
 */

/// @author Tiago Quintino
/// @date   Feb 2018

#ifndef eckit_log_SysLog_h
#define eckit_log_SysLog_h

#include <string>
#include <iosfwd>


namespace eckit {

/// SysLog implements the RFC 5424 format for logging

class SysLog {


public:
    enum Facility
    {
        Kernel = 0,
        User,
        Mail,
        SystemDaemon,
        Security,
        SysLogD,
        LinePrinter,
        NetworkNews,
        UUCP,
        Clock,
        Security2,
        FTP,
        NTP,
        LogAudit,
        LogAlert,
        Clock2,
        Local0,
        Local1,
        Local2,
        Local3,
        Local4,
        Local5,
        Local6,
        Local7, //< we use this for MARS
    };

    enum Severity {
        Emergency = 0,
        Alert,
        Critical,
        Error,
        Warning,
        Notice,
        Info,
        Debug
    };

public:  // methods

    static char nilvalue() { return '-'; }


    SysLog(const std::string& msg, int msgid = 0, Facility f = SysLog::User, Severity s = SysLog::Info);

    unsigned priotity() const { return facility_*8 + severity_; }

    unsigned version() const { return 1; }

    std::string timestamp() const { return timestamp_; }

    std::string fqdn() const;

    std::string appName() const;
    void appName(const std::string&);

    /// Not necessarily a pid, but for now we settled with that
    /// Semantics is application dependent
    int procid() const;

    /// Follows some application classification therefore semantics is application dependent
    int msgid() const { return msgid_; }

    std::string structuredData() const;

    operator std::string() const;

    friend std::ostream& operator<<(std::ostream& s, const SysLog& o) {
        o.print(s);
        return s;
    }

private: // methods

    void print(std::ostream& out) const;

private: // members

    Facility facility_;
    Severity severity_;

    std::string timestamp_;
    std::string appName_;

    int msgid_;

    std::string msg_;
};

} // namespace eckit

#endif
