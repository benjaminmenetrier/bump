/*
 * (C) Copyright 1996-2012 ECMWF.
 * 
 * This software is licensed under the terms of the Apache Licence Version 2.0
 * which can be obtained at http://www.apache.org/licenses/LICENSE-2.0. 
 * In applying this licence, ECMWF does not waive the privileges and immunities 
 * granted to it by virtue of its status as an intergovernmental organisation nor
 * does it submit to any jurisdiction.
 */

// File FunctionEQ.h
// Baudouin Raoult - ECMWF Dec 03

#ifndef FunctionEQ_H
#define FunctionEQ_H

#include "eckit/sql/expression/function/FunctionExpression.h"

namespace eckit {
namespace sql {
namespace expression {
namespace function {

class FunctionEQ : public FunctionExpression {
public:
	FunctionEQ(const std::string&,const expression::Expressions&);
	FunctionEQ(const FunctionEQ&);
	~FunctionEQ(); 

	static bool equal(const SQLExpression& l, const SQLExpression& r, bool& missing);
	static void trimStringInDouble(char* &p, size_t& len);

	std::shared_ptr<SQLExpression> clone() const;

    static int arity() { return 2; }

private:
// No copy allowed
	FunctionEQ& operator=(const FunctionEQ&);

	double tmp_;

// -- Overridden methods
	virtual const eckit::sql::type::SQLType* type() const;
	virtual double eval(bool& missing) const;
    virtual std::shared_ptr<SQLExpression> simplify(bool&);

// -- Friends
	//friend std::ostream& operator<<(std::ostream& s,const FunctionEQ& p)
	//	{ p.print(s); return s; }
};

} // namespace function
} // namespace expression 
} // namespace sql
} // namespace eckit

#endif
