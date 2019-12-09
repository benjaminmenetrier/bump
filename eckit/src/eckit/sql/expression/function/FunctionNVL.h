/*
 * (C) Copyright 1996-2012 ECMWF.
 * 
 * This software is licensed under the terms of the Apache Licence Version 2.0
 * which can be obtained at http://www.apache.org/licenses/LICENSE-2.0. 
 * In applying this licence, ECMWF does not waive the privileges and immunities 
 * granted to it by virtue of its status as an intergovernmental organisation nor
 * does it submit to any jurisdiction.
 */

// File FunctionNVL.h
// Baudouin Raoult - ECMWF Dec 03

#ifndef FunctionNVL_H
#define FunctionNVL_H

#include "eckit/sql/expression/function/FunctionExpression.h"

namespace eckit {
namespace sql {
namespace expression {
namespace function {

class FunctionNVL : public FunctionExpression {
public:
	FunctionNVL(const std::string&,const expression::Expressions&);
	FunctionNVL(const FunctionNVL&);
	~FunctionNVL(); 

	std::shared_ptr<SQLExpression> clone() const;

    static int arity() { return 2; }

private:
// No copy allowed
	FunctionNVL& operator=(const FunctionNVL&);

// -- Overridden methods
	virtual const eckit::sql::type::SQLType* type() const;
	virtual double eval(bool& missing) const;

// -- Friends
	//friend std::ostream& operator<<(std::ostream& s,const FunctionNVL& p)
	//	{ p.print(s); return s; }
};

} // namespace function
} // namespace expression 
} // namespace sql
} // namespace eckit

#endif
